------------------------------------------------------------------------------------------------
-- Entity Name 	:	SPI Slave
-- File Name	:	spi_slave.vhd
-- Generated	:	2.10.2011
-- Author		:	Beeri Schreiber and Omer Shaked
-- Project		:	SPI Project
------------------------------------------------------------------------------------------------
-- Description: This is SPI Slave. As long as the spi_ss is active, data will be transmitted to  
--				the SPI Master:
--					(-) if fifo_empty = '0' data from the fifo will be sent.
--					(-) if fifo_empty = '1' default data will be sent.
--				When transaction is active 'BUSY' signall will be '1'.
--				The following register may be modified during normal operation, when there
--				is no active transmission:
--				(*)	Configuration Register - to configure CPOL and CPHA
-- 					(-) Bit 0	-	CPHA
-- 					(-) Bit 1	-	CPOL
--
-- Requirements:
--	 	(*)	Reset deactivation MUST be synchronized to the clock's rising edge!
--			Reset activetion may be asynchronized to the clock.
--		(*) FIFO should assert FIFO_DIN_VALID within one clock from FIFO_REQ_DATA.
------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date		Name					Description			
--			1.00		2.10.2011	Omer Shaked				Creation
------------------------------------------------------------------------------------------------
--	Todo:
--			(1) 
------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity spi_slave is
	generic (
				reset_polarity_g	:	std_logic	:= '0';		--Reset polarity. '0' is active low, '1' is active high
				ss_polarity_g		:	std_logic	:= '0';		--Slave Select polarity. '0' is active low, '1' is active high
				data_width_g		:	positive range 2 to positive'high	:= 8;		--Shift register is 8 bits. Range is from 2 - for the Shift Register
				reg_width_g			:	positive	:= 8;		--Number of bits in SPI configuration Register
				dval_cpha_g			:	std_logic	:= '0';		--Default (initial) value of CPHA
				dval_cpol_g			:	std_logic	:= '0';		--Default (initial) value of CPOL
				first_dat_lsb		:	boolean		:= true	    --TRUE: Transmit and Receive LSB first. FALSE - MSB first
				default_dat_g		:	integer		:= 0;		--Default data transmitted to master when the FIFO is empty
			);
			
	port 	(
				-- Clock and Reset
				clk					:	in std_logic;											--System Clock
				rst					:	in std_logic;											--Reset. NOTE: Reset deactivation MUST be synchronized to the clock's rising edge
				
				-- SPI Interface
				spi_clk				:	in  std_logic;											--Input SPI Clock from SPI master
				spi_mosi			:	in	std_logic;											--Data: Master output, slave input
				spi_miso			:	out std_logic;											--Data: Master input, slave output
				spi_ss				:	in	std_logic;											--Slave Select
				
				-- FIFO Interface (Input to SPI Slave)
				fifo_req_data		:	out std_logic;											--Request for data from FIFO
				fifo_din			:	in	std_logic_vector (data_width_g - 1 downto 0);		--Data from FIFO
				fifo_din_valid		:	in	std_logic;											--Input data from FIFO
				fifo_empty			:	in	std_logic;											--FIFO is empty
				
				-- Configuration Registers Ports
				reg_din				:	in std_logic_vector (reg_width_g - 1 downto 0);			--Data to registers
				reg_din_val			:	in std_logic;											--Data to registers is valid
				reg_ack				:	out std_logic;											--Data to registers has been acknowledged
				reg_err				:	out	std_logic;											--Error while trying to write data to registers
				
				-- Output from SPI slave
				busy				:	out std_logic;											--'1' - BUSY: Transaction is active
				interrupt			:	out std_logic;											--'1' - Slave Select turned NOT active in the middle of a transaction
				dout				:	out std_logic_vector (data_width_g - 1 downto 0);		--Output data
				dout_valid			:	out std_logic											--Output data is valid
			);
end entity spi_slave;

architecture rtl_spi_slave of spi_slave is

	---------------------		Constants		-----------------------
	-- constant div_reg_addr_c		:	natural 	:= 0;	--Clock Divider Register address
	-- constant conf_reg_addr_c	:	natural 	:= 1;	--Clock Configuration Register address

	---------------------		Types			-----------------------
	type spi_slave_states is (
							idle_st,		--Idle. Slave Select is NOT active, and FIFO is empty
							fifo_load_st, --Load new data from the FIFO to the output register
							ready_st,		--Slave Select is NOT active, but data from FIFO is ready inside the output register
							break_st,		--Slave Select turnrd NOT active in the middle of a transaction
							data_st			--TX and RX  data, until all data bits have been accepted 
					  );

	---------------------		Signals			-----------------------
	--General Signals
	signal cur_st		:		spi_slave_states;								--FSM Current State
	signal next_st		:		spi_slave_states;								--FSM next state
	signal spi_sr_out	:		std_logic_vector (data_width_g - 1 downto 0);	--Shift Register (Output)
	signal sr_out_data	:		std_logic;										--Output Shift Register data: '0' - default data, '1' - fifo_data  
	signal spi_sr_in	:		std_logic_vector (data_width_g - 1 downto 0);	--Shift Register (Input)
	signal sr_cnt_out	:		natural range 0 to data_width_g;				--Number of transmitted bits
	signal sr_cnt_in	:		natural range 0 to data_width_g;				--Number of received bits
	-- signal sr_cnt_in_d1	:		natural range 0 to data_width_g;				--Derive of sr_cnt_in
	signal fifo_req_sr	:		std_logic_vector (1 downto 0);					--Bit 0 => when '1' - indicates that FIFO_DIN_VALID should be asserted
	signal spi_ss_in	:		std_logic;										--Inernal Slave Select
	
	-- Configuration Registers
	signal conf_reg		:		std_logic_vector (reg_width_g - 1 downto 0);	--Configuration Register (CPOL, CPHA at this implementation)
	
	--Clock & Internal Reset:
	signal spi_clk_i	:		std_logic;										--Internal SPI_CLK
	signal spi_clk_reg	:		std_logic;										--Saves the previous sample of SPI_CLK when the slave is active
	signal int_rst		:		std_logic;										--Internal reset - at configuration change
	
	--Configuration Register:
	-- * Bit 0	-	CPHA
	-- * Bit 1	-	CPOL
	alias  cpha			:		std_logic is conf_reg (0);
	alias  cpol			:		std_logic is conf_reg (1);
	
	--Sample and Propagate Signals
	signal samp_en		:		std_logic;										--Sample data
	signal prop_en		:		std_logic;										--Propagate Data

begin

	-------------------------		Hidden Processes	----------------------
	
	busy_proc:
	busy	<= '0' when (spi_ss_in /= ss_polarity_g)
				else '1';

	interrupt_proc:
	interrupt	<=	'1' when (cur_st = break_st)
					else '0';
	
	spi_ss_in_proc:
	spi_ss_in	<=	spi_ss;
	
	spi_clk_i_proc:
	spi_clk_i	<=	spi_clk;
	
	--------------------------------------------------------------------------
	-------------------------	fsm process	----------------------------------
	--------------------------------------------------------------------------
	-- This process is the main FSM process.
	--------------------------------------------------------------------------
	fsm_state_reg_proc: process (clk,rst)
	begin
		if (rst = reset_polarity_g) then
			cur_st			<=	idle_st;	
			
		elsif rising_edge(clk) then
			cur_st			<=	next_st;
		end if;
	end process fsm_state_reg_proc;
	
	fsm_proc: process (cur_st, spi_ss_in, fifo_empty, sr_out_sel)
	begin
		
		case cur_st is
			when idle_st	=>
				if (spi_ss_in = ss_polarity_g) then
					next_st	<=	data_st;
				elsif (fifo_empty = '0') then
					next_st	<=	fifo_load_st;
				else
					next_st <=	idle_st;
				end if;
			
			when fifo_load_st	=>
				if (fifo_din_valid = '0') then
					if (fifo_req_sr (0) = '1')	then --ERROR: Expecting FIFO_DIN_VALID = '1', but it is '0'
						next_st	<= idle_st;
						report "Time: " & time'image(now) & ", SPI Slave >> Expecting FIFO_DIN_VALID = '1' but it is '0'" & LF
						& "Aborting Transmission"
						severity error;
					else -- FIFO data is not ready yet
						next_st	<=	fifo_load_st;
					end if;
				else -- fifo_din_valid = '1'
					if (spi_ss_in = ss_polarity_g) then
						next_st	<=	data_st;
					else
						next_st	<=	ready_st;
					end if;
				end if;
				
			when ready_st	=>
				if (spi_ss_in = ss_polarity_g) then
					next_st	<=	data_st;
				else
					next_st	<=	ready_st;
				end if;
				
			when data_st	=>
				if (fifo_din_valid = '0') and (fifo_req_sr (0) = '1')	then --ERROR: Expecting FIFO_DIN_VALID = '1', but it is '0'
					next_st	<= idle_st;
					report "Time: " & time'image(now) & ", SPI Slave >> Expecting FIFO_DIN_VALID = '1' but it is '0'" & LF
					& "Aborting Transmission"
					severity error;
				elsif (spi_ss_in /= ss_polarity_g) then -- Slave select NOT active
					if (sr_cnt_out /= 0) or (sr_cnt_in /= 0) then
						next_st	<=	break_st;
					else -- Slave Select was De-activated before the start of a new transaction
						if (sr_out_data = '0') then -- Default data
							next_st	<=	idle_st;
						else -- FIFO data
							next_st	<=	ready_st;
						end if;
					end if;
				else -- Slave Select is ACTIVE
					next_st	<=	data_st;
				end if;
					
			when break_st	=>
				if (spi_ss_in = ss_polarity_g) then
					next_st	<=	data_st;
				elsif (sr_out_data = '1') then --data from FIFO is inside the sh_reg
					next_st <=	ready_st;
				else
					next_st	<=	idle_st;
				end if;
		
			when others	=>
				next_st	<=	idle_st;
				report "Time: " & time'image(now) & ", SPI Slave >> Unknown state in FSM!!!"
				severity error;
			
		end case;
	end process fsm_proc;	
	
	
	--------------------------------------------------------------------------
	-------------------------	spi_clk_reg_proc process	------------------
	--------------------------------------------------------------------------
	-- This process reserves the last sample of the SPI CLK, when Slave Select is active.
	-- Else, it reserves (cpol).
	--------------------------------------------------------------------------
	spi_clk_reg_proc: process (clk,rst)
	begin
		if (rst = reset_polarity_g) then
			spi_clk_reg	<=	dval_cpol_g;
		elsif rising_edge (clk) then
			if (spi_ss_in = ss_polarity_g) then 
				spi_clk_reg	<=	spi_clk_i;
			else
				spi_clk_reg	<=	cpol;
			end if;
		end if;
	end process spi_clk_reg_proc;
	
	
	--------------------------------------------------------------------------
	--------------------------	prop_en_proc process -------------------------
	--------------------------------------------------------------------------
	-- This process asserts / negates Data Propagation Enable signal,
	-- according to CPOL, CPHA and SPI_CLK.
	-- When PROP_EN = '1', then data will be propagated to the SPI Master.
	--------------------------------------------------------------------------
	prop_en_proc: process (clk, rst)
	begin
		if (rst = reset_polarity_g) then
			prop_en 	<= '0';
		
		elsif rising_edge (clk) then
			if (spi_ss_in = ss_polarity_g) then 
				if ((cpol = '0') and (cpha = '0') and (spi_clk_reg = '1') and (spi_clk_i = '0'))		--CPOL = '0', CPHA = '0' and falling edge at SPI_CLK
				or ((cpol = '0') and (cpha = '1') and (spi_clk_reg = '0') and (spi_clk_i = '1'))		--CPOL = '0', CPHA = '1' and rising edge at SPI_CLK
				or ((cpol = '1') and (cpha = '0') and (spi_clk_reg = '0') and (spi_clk_i = '1'))		--CPOL = '1', CPHA = '0' and rising edge at SPI_CLK
				or ((cpol = '1') and (cpha = '1') and (spi_clk_reg = '1') and (spi_clk_i = '0'))		--CPOL = '1', CPHA = '1' and falling edge at SPI_CLK
				then	
					prop_en	<= '1';
				else
					prop_en	<= '0';
				end if;
			else
				prop_en		<= '0';
			end if;
		end if;
	end process prop_en_proc;

	--------------------------------------------------------------------------
	--------------------------	samp_en_proc process -------------------------
	--------------------------------------------------------------------------
	-- This process asserts / negates Data Sample Enable signal, according to
	-- CPOL, CPHA and SPI_CLK.
	-- When SAMP_EN = '1', then data will be sampled from the SPI Master.
	--------------------------------------------------------------------------
	samp_en_proc: process (clk, rst)
	begin
		if (rst = reset_polarity_g) then
			samp_en 	<= '0';
		
		elsif rising_edge (clk) then
			if (spi_ss_in = ss_polarity_g) then 
				if ((cpol = '0') and (cpha = '0') and (spi_clk_reg = '0') and (spi_clk_i = '1'))		--CPOL = '0', CPHA = '0' and rising edge at SPI_CLK (='0' since it will be '1' after spi_event)
				or ((cpol = '0') and (cpha = '1') and (spi_clk_reg = '1') and (spi_clk_i = '0'))		--CPOL = '0', CPHA = '1' and falling edge at SPI_CLK (='1' since it will be '0' after spi_event)
				or ((cpol = '1') and (cpha = '0') and (spi_clk_reg = '1') and (spi_clk_i = '0'))		--CPOL = '1', CPHA = '0' and falling edge at SPI_CLK (='1' since it will be '0' after spi_event)
				or ((cpol = '1') and (cpha = '1') and (spi_clk_reg = '0') and (spi_clk_i = '1'))		--CPOL = '1', CPHA = '1' and rising edge at SPI_CLK (='0' since it will be '1' after spi_event)
				then	
					samp_en	<= '1';
				else
					samp_en	<= '0';
				end if;
			else
				samp_en		<= '0';
			end if;
		end if;
	end process samp_en_proc;
	
	
	--------------------------------------------------------------------------
	--------------------------	spi_sr_proc process	--------------------------
	--------------------------------------------------------------------------
	-- This process handles with the input / output Shift Registers, as well
	-- as the SPI_MISO, which is fed from the output Shift Register.
	--------------------------------------------------------------------------
	spi_sr_proc: process (clk, rst)
	begin
		if (rst = reset_polarity_g) then
			spi_sr_out		<=	(others => '0');
			sr_out_data		<=	'0';
			spi_sr_in		<=	(others => '0');
			spi_miso		<=	'Z';
			sr_cnt_out		<=	0;
			sr_cnt_in		<=	0;
		
		elsif rising_edge (clk) then			
			case cur_st is
			
				when idle_st	=>	
					spi_miso	<=	'Z';
					if (spi_ss_in = ss_polarity_g) then -- start of transaction and FIFO data is NOT ready
						spi_sr_out	<=	conv_std_logic_vector (default_dat_g, data_width_g);
						sr_out_data	<=	'0';
						sr_cnt_in	<=	0;
						sr_cnt_out	<=	0;
					end if;
				
				when fifo_load_st	=>
					spi_miso	<=	'Z';
					if (fifo_din_valid = '1') then
						spi_sr_out	<=	fifo_din;
						sr_out_data	<=	'1'
						if (spi_ss_in = ss_polarity_g) then
							sr_cnt_in	<=	0;
							sr_cnt_out	<=	0;
						end if;
					end if;
					
				when ready_st	=>
					spi_miso	<=	'Z';
					if (spi_ss_in = ss_polarity_g) then
						sr_cnt_in	<=	0;
						sr_cnt_out	<=	0;
					end if;
			
				when break_st	=>
					spi_miso	<=	'Z';
					if (spi_ss_in = ss_polarity_g) then
						sr_cnt_in	<=	0;
						sr_cnt_out	<=	0;
					end if;

				when data_st	=>
					if (spi_ss_in /= ss_polarity_g) then -- Slave select NOT active
						spi_miso	<=	'Z';
					else                                 -- Slave Select is ACTIVE
						-- prepare new data in spi_sr_out to allow multiple transmitions
						if (sr_cnt_out = 0) and (fifo_din_valid = '1') then
							spi_sr_out	<=	fifo_din;
							sr_out_data	<=	'1';
						elsif (sr_cnt_out = data_width_g) then
							spi_sr_out	<=	conv_std_logic_vector (default_dat_g, data_width_g);
							sr_out_data	<=	'0';
							sr_cnt_out	<=	0;
						end if;
						
						-- prepare to receive new data to spi_sr_in to allow multiple transmitions
						if (sr_cnt_in = data_width_g) then
							sr_cnt_in 	<=	0;
						end if;
						
						-----	Propagate Data	-----
						if (prop_en = '1') then
							sr_cnt_out	<=	sr_cnt_out + 1;
							--TX Data
							if (first_dat_lsb) then		--First TX data is LSB
								spi_miso	<=	spi_sr_out (sr_cnt_out);
							else						--First TX data is MSB
								spi_miso	<=	spi_sr_out (data_width_g - 1 - sr_cnt_out);
							end if;
						----	Sample Data	-----
						elsif (samp_en = '1') then
							sr_cnt_in	<=	sr_cnt_in + 1;
							--RX Data
							if (first_dat_lsb) then		--First RX data is LSB
								spi_sr_in (sr_cnt_in)	<=	spi_mosi;
							else						--First RX data is MSB
								spi_sr_in (data_width_g - 1 - sr_cnt_out)	<=	spi_miso;
							end if;
						end if;
					end if;
					
				when others		=>
					spi_miso	<=	'Z';
				
			end case;
		end if;
	end process spi_sr_proc;


	--------------------------------------------------------------------------
	-------------------------		dout_proc process	----------------------
	--------------------------------------------------------------------------
	-- This process assert DOUT_VALID, when data from SPI Master is available.
	-- Relevant data may be read through DOUT port.
	--------------------------------------------------------------------------
	dout_proc: process (clk, rst)
	begin
		if (rst = reset_polarity_g) then
			dout		<=	(others => '0');
			dout_valid	<=	'0';
		elsif rising_edge (clk) then
			if (sr_cnt_in = data_width_g) then 
				dout		<=	spi_sr_in;
				dout_valid	<=	'1';
			else
				dout_valid	<=	'0';
			end if;
		end if;
	end process dout_proc;
	
	
	--------------------------------------------------------------------------
	-------------------------	fifo_data_proc process	----------------------
	--------------------------------------------------------------------------
	-- This process asserts FIFO_REQ_DATA (Request for data from FIFO) when
	-- the SPI Slave Shift Register should be loaded.
	--------------------------------------------------------------------------
	fifo_data_proc: process (clk, rst)
	begin
		if (rst = reset_polarity_g) then
			fifo_req_data	<= '0';	
			fifo_req_sr		<= "00";
		elsif rising_edge(clk) then
			if (cur_st = idle_st) and (fifo_empty = '0') and (spi_ss_in /= ss_polarity_g) then	--Request for data
				fifo_req_data	<= '1';
				fifo_req_sr	(0) <= fifo_req_sr (1);
				fifo_req_sr (1)	<= '1';
			elsif (cur_st = data_st) and (sr_cnt_out = data_width_g) and (fifo_empty = '0') then
				fifo_req_data	<= '1';						--End of SR TX. Request for data from FIFO
				fifo_req_sr		<= "10";
			else
				fifo_req_data		<= '0';
				fifo_req_sr	(0) 	<= fifo_req_sr (1);
				fifo_req_sr (1)		<= '0';
			end if;
		end if;
	end process fifo_data_proc;

	
	--------------------------------------------------------------------------
	------------------	spi_conf_reg_proc proces	--------------------------
	--------------------------------------------------------------------------
	-- This process stores data to Configuration Register.
	-- REG_ACK (Register Acknowledged) or REG_ERR (Register Error) will be
	-- asserted as required.
	-- If Slave Select is ACTIVE - a conf. change can't be done.
	-- If Slave Select turns ACTIVE during conf. change - the change isn't 
	-- being performed.
	--------------------------------------------------------------------------
	spi_conf_reg_proc: process (clk, rst)
	begin
		if (rst = reset_polarity_g) then
			conf_reg	<=	(0	=>	dval_cpha_g, 1	=>	dval_cpol_g, others	=>	'0');
			
		elsif rising_edge(clk) then
			if (reg_din_val = '1') then
				if (spi_ss_in = ss_polarity_g) then 		--Transmission is in progress. Cannot change configuration during transmission
					reg_ack		<= '0';
					reg_err		<= '1';
					report "Time: " & time'image(now) & ", SPI Slave >> Writing to registers during transmission is forbidden!!!" & LF &
					"Transmission will continue!!!"
					severity error;
				else										--Write to Registers
					conf_reg	<=	reg_din;
					reg_ack		<= '1';
					reg_err		<= '0';
				end if;

			else	--No action should be taken
				reg_ack	<= '0';
				reg_err	<= '0';
			end if;
		end if;
	end process spi_conf_reg_proc;
