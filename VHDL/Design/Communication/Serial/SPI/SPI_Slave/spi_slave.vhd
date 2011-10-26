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
--			1.1			23.10.2011	Omer Shaked				(1) Added: Timeout handling
--															(2) Added: spi_miso output enable
--															(3) Changed : Configuration Registers handling - 
--																registers write can be done at any time.
--															(4) Bug fixing [1]: Multiple transmitions when CPHA = 0
--
-- Fixed bugs Description:
-- =======================
-- [1] When cpha = 0, at the last EDGE of spi_clk in a transmition, the first bit of the next data word is being
--     propogated, since if another transaction will start immediately (burst - more than one transaction without
--     de-asserting the SS), on the first edge the data will already be sampled.
--     Therefore, if transmition was actually terminated (No burst - SS de-asserted), we need to SHIFT-BACK the 
--	   output shift register, in order to have the correct data received from the FIFO ready for the next
--	   transaction.
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
				first_dat_lsb		:	boolean		:= true;    --TRUE: Transmit and Receive LSB first. FALSE - MSB first
				default_dat_g		:	integer		:= 0;		--Default data transmitted to master when the FIFO is empty
				spi_timeout_g		:	std_logic_vector (10 downto 0)	:=	"00000100000"; -- Number of clk cycles before timeout is declared
				timeout_en_g		:	std_logic	:= '1';		--Timeout enable. '1' - enabled, '0' - disabled
				dval_miso_g			:	std_logic	:= '0'		--Default value of spi_miso internal signal
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
				
				-- Output from SPI slave
				busy				:	out std_logic;											--'1' - BUSY: Transaction is active
				timeout				:	out std_logic;											--'1' : SPI TIMEOUT - spi_clk stuck for spi_timeout_g clk cycles
				interrupt			:	out std_logic;											--'1' - Slave Select turned NOT active in the middle of a transaction
				dout				:	out std_logic_vector (data_width_g - 1 downto 0);		--Output data
				dout_valid			:	out std_logic											--Output data is valid
			);
end entity spi_slave;

architecture rtl_spi_slave of spi_slave is

	---------------------		Constants		-----------------------


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
	signal fifo_req_sr	:		std_logic_vector (1 downto 0);					--Bit 0 => when '1' - indicates that FIFO_DIN_VALID should be asserted
	signal spi_ss_in	:		std_logic;										--Inernal Slave Select
	signal spi_miso_i	:		std_logic;										--Internal spi_miso signal
	signal spi_tout_cnt : 		std_logic_vector (11 downto 0);					--SPI timeout counter => MSBit is checked
	
	-- Configuration Registers
	signal conf_reg		:		std_logic_vector (reg_width_g - 1 downto 0);	--Configuration Register (CPOL, CPHA at this implementation)
	
	--Clock & Internal Reset:
	signal spi_clk_i	:		std_logic;										--Internal SPI_CLK
	signal spi_clk_reg	:		std_logic;										--Saves the previous sample of SPI_CLK when the slave is active
	
	--Configuration Register:
	-- * Bit 0	-	CPHA
	-- * Bit 1	-	CPOL
	signal cpha			:		std_logic; -- spi protocol CPHA value - isn't updated during transaction!
	signal cpol			:		std_logic; -- spi protocol CPOL value - isn't updated during transaction!
	
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
	
	spi_miso_en_proc:
	spi_miso	<=	spi_miso_i when (spi_ss_in = ss_polarity_g)
							   else 'Z';
	
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
	
	fsm_proc: process (cur_st, spi_ss_in, fifo_empty, fifo_din_valid, sr_out_data, fifo_req_sr(0), sr_cnt_out, sr_cnt_in)
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
					if (cpha = '0') and (sr_cnt_out > 1) then
						next_st	<=	break_st;
					elsif (cpha = '0') and (sr_cnt_in /= 0) then
						next_st	<=	break_st;
					elsif (cpha = '1') and (sr_cnt_out /= 0) then
						next_st	<=	break_st;
					elsif (cpha = '1') and (sr_cnt_in /= 0) then
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
	variable default_data	:	std_logic_vector (data_width_g - 1 downto 0)	:=	(others => '0');
	begin
		if (rst = reset_polarity_g) then
			spi_sr_out		<=	(others => '0');
			sr_out_data		<=	'0';
			spi_sr_in		<=	(others => '0');
			spi_miso_i		<=	dval_miso_g; --Default spi_miso value
			sr_cnt_out		<=	0;
			sr_cnt_in		<=	0;
		
		elsif rising_edge (clk) then			
			case cur_st is
			
				when idle_st	=>	
					spi_miso_i	<=	dval_miso_g;
					if (spi_ss_in = ss_polarity_g) then -- start of transaction and FIFO data is NOT ready
						if (cpha = '0') then -- need to propogate first bit of Tx data
							sr_cnt_out		<=	1; -- first bit is being propogated
							sr_cnt_in		<=	0;
							default_data	:=	conv_std_logic_vector (default_dat_g, data_width_g);
							sr_out_data		<=	'0';
							--TX Data
							if (first_dat_lsb) then		--First TX data is LSB
								spi_miso_i								<=	default_data (0);
								spi_sr_out (data_width_g - 2 downto 0)	<= 	default_data (data_width_g - 1 downto 1);
							else						--First TX data is MSB
								spi_miso_i								<=	default_data (data_width_g - 1);
								spi_sr_out (data_width_g - 1 downto 1)	<= 	default_data (data_width_g - 2 downto 0);
							end if;
						else -- cpha = 1
							spi_sr_out	<=	conv_std_logic_vector (default_dat_g, data_width_g);
							sr_out_data	<=	'0';
							sr_cnt_in	<=	0;
							sr_cnt_out	<=	0;
						end if;
					end if;
				
				when fifo_load_st	=>
					spi_miso_i	<=	dval_miso_g;
					if (fifo_din_valid = '1') then
						if (spi_ss_in /= ss_polarity_g) then
							spi_sr_out	<=	fifo_din;
							sr_out_data	<=	'1';
						else
							if (cpha = '0') then -- need to propogate first bit of Tx data
								sr_cnt_out		<=	1; -- first bit is being propogated
								sr_cnt_in		<=	0;
								default_data	:=	fifo_din;
								sr_out_data		<=	'1';
								--TX Data
								if (first_dat_lsb) then		--First TX data is LSB
									spi_miso_i								<=	default_data (0);
									spi_sr_out (data_width_g - 2 downto 0)	<= 	default_data (data_width_g - 1 downto 1);
								else						--First TX data is MSB
									spi_miso_i								<=	default_data (data_width_g - 1);
									spi_sr_out (data_width_g - 1 downto 1)	<= 	default_data (data_width_g - 2 downto 0);
								end if;
							else -- cpha = 1
								spi_sr_out	<=	fifo_din;
								sr_out_data	<=	'1';
								sr_cnt_in	<=	0;
								sr_cnt_out	<=	0;
							end if;
						end if;
					end if;
					
				when ready_st	=>
					spi_miso_i	<=	dval_miso_g;
					if (spi_ss_in = ss_polarity_g) then
						if (cpha = '0') then -- need to propogate first bit of Tx data
							sr_cnt_out		<=	1; -- first bit is being propogated
							sr_cnt_in		<=	0;
							--TX Data
							if (first_dat_lsb) then		--First TX data is LSB
								spi_miso_i								<=	spi_sr_out (0);
								spi_sr_out (data_width_g - 2 downto 0)	<= 	spi_sr_out (data_width_g - 1 downto 1);
							else						--First TX data is MSB
								spi_miso_i								<=	spi_sr_out (data_width_g - 1);
								spi_sr_out (data_width_g - 1 downto 1)	<= 	spi_sr_out (data_width_g - 2 downto 0);
							end if;
						else -- cpha = 1
							sr_cnt_in	<=	0;
							sr_cnt_out	<=	0;
						end if;
					end if;
			
				when break_st	=>
					spi_miso_i	<=	dval_miso_g;
					if (spi_ss_in = ss_polarity_g) then
						if (cpha = '0') then -- need to propogate first bit of Tx data
							sr_cnt_out		<=	1; -- first bit is being propogated
							sr_cnt_in		<=	0;
							default_data	:=	conv_std_logic_vector (default_dat_g, data_width_g);
							sr_out_data		<=	'0';
							--TX Data
							if (first_dat_lsb) then		--First TX data is LSB
								spi_miso_i								<=	default_data (0);
								spi_sr_out (data_width_g - 2 downto 0)	<= 	default_data (data_width_g - 1 downto 1);
							else						--First TX data is MSB
								spi_miso_i								<=	default_data (data_width_g - 1);
								spi_sr_out (data_width_g - 1 downto 1)	<= 	default_data (data_width_g - 2 downto 0);
							end if;
						else -- cpha = 1
							spi_sr_out	<=	conv_std_logic_vector (default_dat_g, data_width_g);
							sr_out_data	<=	'0';
							sr_cnt_in	<=	0;
							sr_cnt_out	<=	0;
						end if;
					end if;

				when data_st	=>
					if (spi_ss_in /= ss_polarity_g) then -- Slave select NOT active
						spi_miso_i	<=	dval_miso_g;
						if (cpha = '0') and (sr_cnt_out = 1) then -- Shift-BACK the data of out_sr
							if (first_dat_lsb) then		--First TX data is LSB
								spi_sr_out (data_width_g - 1 downto 1)	<= 	spi_sr_out (data_width_g - 2 downto 0);
								spi_sr_out (0)							<=	spi_miso_i;
							else						--First TX data is MSB
								spi_sr_out (data_width_g - 2 downto 0)	<= 	spi_sr_out (data_width_g - 1 downto 1);
								spi_sr_out (data_width_g - 1)			<=	spi_miso_i;
							end if;
						end if;
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
								spi_miso_i								<=	spi_sr_out (0);
								spi_sr_out (data_width_g - 2 downto 0)	<= 	spi_sr_out (data_width_g - 1 downto 1);
							else						--First TX data is MSB
								spi_miso_i								<=	spi_sr_out (data_width_g - 1);
								spi_sr_out (data_width_g - 1 downto 1)	<= 	spi_sr_out (data_width_g - 2 downto 0);
							end if;
						----	Sample Data	-----
						elsif (samp_en = '1') then
							sr_cnt_in	<=	sr_cnt_in + 1;
							--RX Data
							if (first_dat_lsb) then		--First RX data is LSB
								spi_sr_in (data_width_g - 1)			<=	spi_mosi;
								spi_sr_in (data_width_g - 2 downto 0)	<= 	spi_sr_in (data_width_g - 1 downto 1);
							else						--First RX data is MSB
								spi_sr_in (0)							<=	spi_mosi;
								spi_sr_in (data_width_g - 1 downto 1)	<= 	spi_sr_in (data_width_g - 2 downto 0);
							end if;
						end if;
					end if;
					
				when others		=>
					spi_miso_i	<=	dval_miso_g;
				
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
	------------------	spi_conf process	----------------------------------
	--------------------------------------------------------------------------
	-- This process deals with Configuration values.
	-- Configuration change - write to the configuration register, can be done
	-- AT ANY TIME.
	-- REG_ACK (Register Acknowledged) will be asserted as required.
	-- CPHA and CPOL are sampled at the begining of the transaction,
	-- so a configuration change at the middle of an active transaction, will
	-- only take place at the following transaction (when SS turns NOT active).
	--------------------------------------------------------------------------
	spi_conf_reg_proc: process (clk, rst)
	begin
		if (rst = reset_polarity_g) then
			conf_reg(0)	<=	dval_cpha_g;
			conf_reg(1)	<=	dval_cpol_g;
			conf_reg(reg_width_g - 1 downto 2)	<=	(others	=>	'0');
			reg_ack		<= '0';
			
		elsif rising_edge(clk) then
			if (reg_din_val = '1') then		--Write to Registers
				conf_reg	<=	reg_din;
				reg_ack		<= '1';
			else							--No action should be taken
				reg_ack	<= '0';
			end if;
		end if;
	end process spi_conf_reg_proc;
	
	spi_conf_val_proc: process (clk, rst)
	begin
		if (rst = reset_polarity_g) then
			cpha	<=	dval_cpha_g;
			cpol	<=	dval_cpol_g;
		
		elsif rising_edge(clk) then
			if (cur_st /= data_st) and (spi_ss_in /= ss_polarity_g) then 	-- Allow sampling of new values
				cpha	<=	conf_reg(0);
				cpol	<=	conf_reg(1);
			end if;
		end if;
	end process spi_conf_val_proc;
		
	--------------------------------------------------------------------------
	------------------		spi_timeout process		  ------------------------
	--------------------------------------------------------------------------
	-- This process handles with the timeout output signal.
	-- Timeout is asserted if:
	-- (1) Transaction is active (SS = '0')
	-- (2) spi_clk is STUCK at the same value for spi_timout_g clk cycles
	--------------------------------------------------------------------------
	spi_timeout_cnt_proc: process (clk, rst)
	begin
		if (rst = reset_polarity_g) then
			spi_tout_cnt (10 downto 0)	<=	spi_timeout_g;
			spi_tout_cnt (11)			<=	'0';
			
		elsif rising_edge(clk) then
			if (spi_ss_in /= ss_polarity_g) then -- transaction is NOT active
				spi_tout_cnt (10 downto 0)	<=	spi_timeout_g;
				spi_tout_cnt (11)			<=	'0';
			else -- spi_ss is ACTIVE
				if (spi_clk_i /= spi_clk_reg) then -- spi_clk was toggled
					spi_tout_cnt (10 downto 0)	<=	spi_timeout_g;
					spi_tout_cnt (11)			<=	'0';
				elsif (spi_tout_cnt(11) /= '1') then -- Timeout isn't asserted
						spi_tout_cnt	<=	spi_tout_cnt - 1;
				end if;
			end  if;
		end if;
	end process spi_timeout_cnt_proc;
	
	spi_timeout_proc: process (clk, rst)
	begin
		if (rst = reset_polarity_g) then
			timeout	<=	'0';
			
		elsif rising_edge(clk) then
			if (timeout_en_g = '0') then -- Timeout signal is disabled
				timeout	<=	'0';
			else -- timeout enabled
				if (spi_tout_cnt(11) = '1') then -- counter has reached timeout
					timeout	<=	'1';
				else 
					timeout	<=	'0';
				end if;
			end if;
		end if;
	end process spi_timeout_proc;

end architecture rtl_spi_slave;