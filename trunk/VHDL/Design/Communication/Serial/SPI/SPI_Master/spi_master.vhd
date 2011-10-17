------------------------------------------------------------------------------------------------
-- Entity Name 	:	SPI Master
-- File Name	:	spi_master.vhd
-- Generated	:	5.08.2011
-- Author		:	Beeri Schreiber and Omer Shaked
-- Project		:	SPI Project
------------------------------------------------------------------------------------------------
-- Description: This is SPI Master. As long as the input FIFO is not empty, data will be
--				transmitted to the relevant SPI Slave, which is determined by SPI slave address.
--				When transaction is active 'BUSY' signall will be '1'.
--				The following registers may be modified during normal operation, when there
--				is no active transmission:
--				(*)	Configuration Register - to configure CPOL and CPHA
-- 					(-) Bit 0	-	CPHA
-- 					(-) Bit 1	-	CPOL
--				(*) Clock Divide Register - to configure system clock divide rate to the SPI clock:
--					(-)	When this register is '1', then divide rate is 2,
--					(-)	When this register is '2', then divide rate is 3, etc...
--
-- Requirements:
--	 	(*)	Reset deactivation MUST be synchronized to the clock's rising edge!
--			Reset activetion may be asynchronized to the clock.
--		(*) FIFO should assert FIFO_DIN_VALID within one clock from FIFO_REQ_DATA.
------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date		Name					Description			
--			1.00		5.08.2011	Beeri Schreiber			Creation
------------------------------------------------------------------------------------------------
--	Todo:
--			(1) 
------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.math_real.all;

entity spi_master is
	generic (
				reset_polarity_g	:	std_logic	:= '0';		--Reset polarity. '0' is active low, '1' is active high
				ss_polarity_g		:	std_logic	:= '0';		--Slave Select polarity. '0' is active low, '1' is active high
				data_width_g		:	positive range 2 to positive'high	:= 8;		--Shift register is 8 bits. Range is from 2 - for the Shift Register
				bits_of_slaves_g	:	positive	:= 1;		--Number of slaves bits (determines SPI_SS bus width)
				reg_width_g			:	positive	:= 8;		--Number of bits in SPI Clock Divider Register
				dval_conf_reg_g		:	natural		:= 0;		--Default (initial) value of Configuration Register
				dval_clk_reg_g		:	positive range 2 to positive'high		:= 2;		--Default (initial) value of Clock Divide Register (Divide system clock by 2 is the minimum)
				reg_addr_width_g	:	positive	:= 8;		--Registers Configuration Address Width
				reg_din_width_g 	:	positive	:= 8;		--Registers Configuration Input Data Width
				first_dat_lsb		:	boolean		:= true	--TRUE: Transmit and Receive LSB first. FALSE - MSB first
			);
			
	port 	(
				-- Clock and Reset
				clk					:	in std_logic;											--System Clock
				rst					:	in std_logic;											--Reset. NOTE: Reset deactivation MUST be synchronized to the clock's rising edge
				
				-- SPI Interface
				spi_clk				:	out std_logic;											--Output SPI Clock to SPI Slave
				spi_mosi			:	out	std_logic;											--Data: Master output, slave input
				spi_miso			:	in 	std_logic;											--Data: Master input, slave output
				spi_ss				:	out	std_logic_vector (bits_of_slaves_g - 1 downto 0);	--Slave Select
				
				-- FIFO Interface (Input to SPI Master)
				fifo_req_data		:	out std_logic;											--Request for data from FIFO
				fifo_din			:	in	std_logic_vector (data_width_g - 1 downto 0);		--Data from FIFO
				fifo_din_valid		:	in	std_logic;											--Input data from FIFO
				fifo_empty			:	in	std_logic;											--FIFO is empty
				
				--Additional Ports:
				spi_slave_addr		:	in std_logic_vector (integer(ceil(log(real(bits_of_slaves_g)) / log(2.0))) - 1 downto 0);	--Addressed slave
				
				-- Configuration Registers Ports
				reg_addr			:	in std_logic_vector (reg_addr_width_g - 1 downto 0);	--Address to registers
				reg_din				:	in std_logic_vector (reg_din_width_g - 1 downto 0);		--Data to registers
				reg_din_val			:	in std_logic;											--Data to registers is valid
				reg_ack				:	out std_logic;											--Data to registers has been acknowledged
				reg_err				:	out	std_logic;											--Error while trying to write data to registers
				
				-- Output from SPI Master
				busy				:	out std_logic;											--'1' - BUSY: Transaction is active
				dout				:	out std_logic_vector (data_width_g - 1 downto 0);		--Output data
				dout_valid			:	out std_logic											--Output data is valid
			);
end entity spi_master;

architecture rtl_spi_master of spi_master is

	---------------------		Constants		-----------------------
	constant div_reg_addr_c		:	natural 	:= 0;	--Clock Divider Register address
	constant conf_reg_addr_c	:	natural 	:= 1;	--Clock Configuration Register address

	---------------------		Types			-----------------------
	type spi_states is (
							idle_st,		--Idle. FIFO is empty
							load_sr_st,		--FIFO is not empty:
											--		Store data into the S.R (Shift Register)
							assert_ss_st,	--Asserts SPI_SS and enable SPI_CLK
											--		Assert relevant SPI_SS
							data_st			--TX and RX  data, and load new data from FIFO when all data bits have been transmisted, in case it is not empty
					  );

	---------------------		Signals			-----------------------
	--General Signals
	signal cur_st		:		spi_states;										--FSM Current State
	signal spi_sr_out	:		std_logic_vector (data_width_g - 1 downto 0);	--Shift Register (Output)
	signal spi_sr_in	:		std_logic_vector (data_width_g - 1 downto 0);	--Shift Register (Input)
	signal sr_cnt_out	:		natural range 0 to data_width_g;				--Number of transmitted bits
	signal sr_cnt_in	:		natural range 0 to data_width_g;				--Number of received bits
	signal sr_cnt_in_d1	:		natural range 0 to data_width_g;				--Derive of sr_cnt_in
	signal fifo_req_sr	:		std_logic_vector (1 downto 0);					--Bit 0 => when '1' - indicates that FIFO_DIN_VALID should be asserted
	signal int_spi_ss	:		std_logic_vector (bits_of_slaves_g - 1 downto 0);--Inernal Slave Select
	
	-- Configuration Registers
	signal div_reg		:		std_logic_vector (reg_width_g - 1 downto 0);	--Divide System Clock by (this number - 2)
	signal conf_reg		:		std_logic_vector (reg_width_g - 1 downto 0);	--Configuration Register (CPOL, CPHA at this implementation)
	
	--Clock & Internal Reset:
	signal spi_clk_i	:		std_logic;										--Internal SPI_CLK
	signal clk_cnt		:		std_logic_vector (reg_width_g downto 0);		--Clock counter - reversed. NOTE: One bit extra, to reduce '=' operation
	alias  spi_event	:		std_logic is clk_cnt (reg_width_g);				--'1' - inverse spi_clk_i value
	signal spi_clk_en	:		boolean;										--Enable (TRUE)/ Disable (FLASE) SPI clk
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
	spi_clk_out_proc:
	spi_clk	<= 	spi_clk_i when spi_clk_en
				else cpol;
	
	spi_ss_out_proc:
	spi_ss	<=	int_spi_ss;
	
	busy_proc:
	busy	<= '0' when (cur_st = idle_st)
				else '1';


	--------------------------------------------------------------------------
	-------------------------		dout_proc proces	----------------------
	--------------------------------------------------------------------------
	-- This process assert DOUT_VALID, when data from SPI Slave is available.
	-- Relevant data may be read through DOUT port.
	--------------------------------------------------------------------------
	dout_proc: process (clk, rst)
	begin
		if (rst = reset_polarity_g) then
			dout		<=	(others => '0');
			dout_valid	<=	'0';
		elsif rising_edge (clk) then
			sr_cnt_in_d1	<=	sr_cnt_in;
			if (sr_cnt_in_d1 = data_width_g) and (sr_cnt_in_d1 /= sr_cnt_in) then	--Different values ==> DOUT is valid
				dout		<=	spi_sr_in;
				dout_valid	<=	'1';
			else
				dout_valid	<=	'0';
			end if;
		end if;
	end process dout_proc;

	--------------------------------------------------------------------------
	-------------------------		spi_ss_proc proces	----------------------
	--------------------------------------------------------------------------
	-- This process latches the Slave Select Address and Slave Select
	-- Negation at transaction initialization.
	--------------------------------------------------------------------------
	spi_ss_proc: process (clk, rst)
	begin
		if (rst = reset_polarity_g) then
			int_spi_ss							<= (others => (not ss_polarity_g));
		
		elsif rising_edge(clk) then
			if (cur_st = assert_ss_st) then
				int_spi_ss										<= (others => (not ss_polarity_g));
				if (conv_integer(spi_slave_addr) < bits_of_slaves_g) then
					int_spi_ss(conv_integer(spi_slave_addr))	<= ss_polarity_g;
				else
					report "Time: " & time'image(now) & ", SPI Master >> SPI Slave Address (" & integer'image(conv_integer(spi_slave_addr)) & ") is out of range" & LF
					& "SPI_SS will not assert"
					severity error;
				end if;
				
			elsif (cur_st = data_st) then
				int_spi_ss		<= int_spi_ss;

			else
				int_spi_ss						<= (others => (not ss_polarity_g));
			end if;
		end if;
	end process spi_ss_proc;
	
	--------------------------------------------------------------------------
	-------------------------	spi_clk_en_proc proces	----------------------
	--------------------------------------------------------------------------
	-- This process enables / disables the SPI_CLK.
	-- SPI Clock will be enabled when asserting SPI_SS, and during data
	-- transmission.
	--------------------------------------------------------------------------
	spi_clk_en_proc: process (clk, rst)
	begin
		if (rst = reset_polarity_g) then
			spi_clk_en	<= false;
			
		elsif rising_edge(clk) then
			if (cur_st = assert_ss_st) or (cur_st = data_st) then
				spi_clk_en	<= true;
			else
				spi_clk_en	<= false;
			end if;
		end if;
	end process spi_clk_en_proc;
	
	--------------------------------------------------------------------------
	-------------------------	fifo_data_proc proces	----------------------
	--------------------------------------------------------------------------
	-- This process asserts FIFO_REQ_DATA (Request for data from FIFO) when
	-- the SPI Master Shift Register should be loaded.
	--------------------------------------------------------------------------
	fifo_data_proc: process (clk, rst)
	begin
		if (rst = reset_polarity_g) then
			fifo_req_data	<= '0';	
			fifo_req_sr		<= "00";
		elsif rising_edge(clk) then
			if (cur_st = idle_st) and (fifo_empty = '0') then	--Request for data
				fifo_req_data	<= '1';
				fifo_req_sr	(0) <= fifo_req_sr (1);
				fifo_req_sr (1)	<= '1';
			elsif (cur_st = data_st) then
				if (sr_cnt_out = data_width_g) and (fifo_empty = '0') then
					fifo_req_data	<= '1';						--End of SR TX. Request for data from FIFO
					fifo_req_sr		<= "10";
				else
					fifo_req_data	<= '0';
					fifo_req_sr	(0) <= fifo_req_sr (1);
					fifo_req_sr (1)	<= '0';
				end if;
			else
				fifo_req_data		<= '0';
				fifo_req_sr	(0) 	<= fifo_req_sr (1);
				fifo_req_sr (1)		<= '0';
			end if;
		end if;
	end process fifo_data_proc;

	--------------------------------------------------------------------------
	-------------------------	fsm_proc proces		--------------------------
	--------------------------------------------------------------------------
	-- This process is the main FSM process.
	--------------------------------------------------------------------------
	fsm_proc: process (clk, rst)
	begin
		if (rst = reset_polarity_g) then
			cur_st			<=	idle_st;	
			
		elsif rising_edge(clk) then
			case cur_st is
				when idle_st	=>
					if (fifo_empty = '0') then
						cur_st			<= load_sr_st;
					else	--FIFO is empty
						cur_st			<= cur_st;
					end if;
					
				when load_sr_st	=>
					cur_st	<=	assert_ss_st;
					
				when assert_ss_st =>
					if ((fifo_din_valid = '0') and (fifo_req_sr (0) = '1'))	then --ERROR: Expecting FIFO_DIN_VALID = '1', but it is '0'
				    	cur_st	<= idle_st;
						report "Time: " & time'image(now) & ", SPI Master >> Expecting FIFO_DIN_VALID = '1' but it is '0'" & LF
						& "Aborting Transmission"
						severity error;
					else
						cur_st	<=	data_st;
					end if;
				
				when data_st	=>
					if (sr_cnt_in = 0) and (sr_cnt_out = 0) and (fifo_empty = '1') then
				    	cur_st	<= idle_st;
					elsif ((fifo_din_valid = '0') and (fifo_req_sr (0) = '1'))	then --ERROR: Expecting FIFO_DIN_VALID = '1', but it is '0'
				    	cur_st	<= idle_st;
						report "Time: " & time'image(now) & ", SPI Master >> Expecting FIFO_DIN_VALID = '1' but it is '0'" & LF
						& "Aborting Transmission"
						severity error;
					else
						cur_st	<=	cur_st;
					end if;
						
				when others		=> --No more states
					cur_st	<= idle_st;
					report "Time: " & time'image(now) & ", SPI Master >> Unknown state in FSM!!!"
					severity error;
			end case;
		end if;
	end process fsm_proc;
	
	--------------------------------------------------------------------------
	------------------	spi_conf_reg_proc proces	--------------------------
	--------------------------------------------------------------------------
	-- This process stores data to Configuration and Clock Devide Registers.
	-- REG_ACK (Register Acknowledged) or REG_ERR (Register Error) will be
	-- asserted as required.
	-- During write phase, the SPI Master will assert INT_RST (Internal Reset),
	-- to prevent transmission during configuration change.
	--------------------------------------------------------------------------
	spi_conf_reg_proc: process (clk, rst)
	variable reg_addr_v		:	natural range 0 to 2**reg_addr_width_g - 1;
	begin
		if (rst = reset_polarity_g) then
			conf_reg	<=	conv_std_logic_vector (dval_conf_reg_g, reg_width_g);
			div_reg		<=	conv_std_logic_vector (dval_clk_reg_g - 2, reg_width_g);
			int_rst		<=	'0';
			reg_ack		<= 	'0';
			reg_err		<= 	'0';
			
		elsif rising_edge(clk) then
			if (reg_din_val = '1') then
				if (cur_st /= idle_st) then 		--Transmission is in progress. Cannot change configuration during transmission
					reg_ack		<= '0';
					reg_err		<= '1';
					int_rst		<= '0';
					report "Time: " & time'image(now) & ", SPI Master >> Writing to registers during transmission is forbidden!!!" & LF &
					"Transmission will continue!!!"
					severity error;
				else								--Write to Registers
					reg_addr_v	:= conv_integer (unsigned (reg_addr));
					int_rst	<= '1';
					case reg_addr_v is
						when div_reg_addr_c		=>	--Write to Clock Divide Register
							if (conv_integer (reg_din)	> 1) then
								div_reg		<= reg_din - "10"; -- (-2 which is minimum divide factor)
								reg_ack		<= '1';
								reg_err		<= '0';
							else
								div_reg		<= div_reg;
								reg_ack		<= '0';
								reg_err		<= '1';
								report "Time: " & time'image(now) & ", SPI Master >> Register number " & natural'image (reg_addr_v) & " (Divide Register): Only values greater or equal to 2 are allowed"
								severity error;
							end if;
						
						when conf_reg_addr_c	=>	--Write to Configuration Register
							conf_reg	<= reg_din;
							reg_ack		<= '1';
							reg_err		<= '0';
	
						when others 			=>	--No such address
							reg_ack		<= '0';
							reg_err		<= '1';
							report "Time: " & time'image(now) & ", SPI Master >> Register number " & natural'image (reg_addr_v) & " is not mapped!"
							severity error;
					end case; 
				end if;

			else	--No action should be taken
				reg_ack	<= '0';
				reg_err	<= '0';
				int_rst	<= '0';
			end if;
		end if;
	end process spi_conf_reg_proc;

	--------------------------------------------------------------------------
	--------------------------	spi_sr_proc proces	--------------------------
	--------------------------------------------------------------------------
	-- This process handles with the input / output Shift Registers, as well
	-- as the SPI_MOSI, which is fed from the Shift Register.
	--------------------------------------------------------------------------
	spi_sr_proc: process (clk, rst)
	begin
		if (rst = reset_polarity_g) then
			spi_sr_out		<=	(others => '0');
			spi_sr_in		<=	(others => '0');
			spi_mosi		<=	'0';
			sr_cnt_out		<=	0;
			sr_cnt_in		<=	0;
		
		elsif rising_edge(clk) then
			if (cur_st = load_sr_st) then	--Load Shift Register. NOTE: (fifo_din_valid = '1') condition is not validated, since in case it is '0', current state will not change, so the input data is not relevant.
											--	In that way, the tPD between to FF here will diminish
				spi_sr_out	<=	fifo_din;
				sr_cnt_in	<=	0;
				sr_cnt_out	<=	0;
			
			elsif (cur_st = assert_ss_st) then	--Prepare MOSI for data propagation
				if (first_dat_lsb) then			--LSB First
					spi_mosi		<=	spi_sr_out(0);
				else							--MSB First
					spi_mosi		<=	spi_sr_out (data_width_g - 1);
				end if;
				
			elsif (cur_st = data_st) then	--TX data
				--Load SR at end of burst
				if (sr_cnt_out = 0) and (fifo_din_valid = '1') then
					spi_sr_out	<=	fifo_din;
					--Input SR Counter (Check for Zero)
					if (sr_cnt_in = data_width_g) then
						sr_cnt_in	<=	0;
					else
						sr_cnt_in 	<= sr_cnt_in;
					end if;

				-----	Propagate Data	-----
				elsif (prop_en = '1') then
					--Output SR Counter
					sr_cnt_out	<=	sr_cnt_out + 1;

					--Input SR Counter (Check for Zero)
					if (sr_cnt_in = data_width_g) then
						sr_cnt_in	<=	0;
					else
						sr_cnt_in 	<= sr_cnt_in;
					end if;
					
					--TX Data
					if (first_dat_lsb) then		--First TX data is LSB
						spi_mosi								<=	spi_sr_out (0);
						spi_sr_out (data_width_g - 2 downto 0)	<= 	spi_sr_out (data_width_g - 1 downto 1);
					else						--First TX data is MSB
						spi_mosi								<=	spi_sr_out (data_width_g - 1);
						spi_sr_out (data_width_g - 1 downto 1)	<= 	spi_sr_out (data_width_g - 2 downto 0);
					end if;
				
				----	Sample Data	-----
				elsif (samp_en = '1') then
					--Inupt SR Counter
					sr_cnt_in	<=	sr_cnt_in + 1;
					
					--Output SR Counter (Check for zero)
					if (sr_cnt_out = data_width_g)  then
						sr_cnt_out	<=	0;
					else
						sr_cnt_out <= sr_cnt_out;
					end if;

					--RX Data
					if (first_dat_lsb) then		--First RX data is LSB
						spi_sr_in (data_width_g - 1)			<=	spi_miso;
						spi_sr_in (data_width_g - 2 downto 0)	<= 	spi_sr_in (data_width_g - 1 downto 1);
					else						--First RX data is MSB
						spi_sr_in (0)							<=	spi_miso;
						spi_sr_in (data_width_g - 1 downto 1)	<= 	spi_sr_in (data_width_g - 2 downto 0);
					end if;
				
				--Idle (or in the middle of the transaction, between SPI_CLK edges)
				else
					if (sr_cnt_out = data_width_g) then
						sr_cnt_out	<=	0;
					else
						sr_cnt_out <= sr_cnt_out;
					end if;
					
					if (sr_cnt_in = data_width_g) then
						sr_cnt_in	<=	0;
					else
						sr_cnt_in <= sr_cnt_in;
					end if;
					spi_sr_out	<=	spi_sr_out;
					spi_sr_in	<=	spi_sr_in;
				end if;
			else
				spi_sr_out		<= spi_sr_out;
				spi_sr_in		<= spi_sr_in;
			end if;
		end if;
	end process spi_sr_proc;


	--------------------------------------------------------------------------
	--------------------------	spi_clk_proc proces	--------------------------
	--------------------------------------------------------------------------
	-- This process determines whether the SPI_CLK should be '1' or '0',
	-- according to CPOL and current divide clock counter.
	--------------------------------------------------------------------------
	spi_clk_proc: process (clk, rst)
	begin
		if (rst = reset_polarity_g) then
			spi_clk_i	<=	'0';
		
		elsif rising_edge(clk) then
			if (int_rst = '1') then	--Internal reset
				spi_clk_i	<= cpol;
			else
				if (cur_st = idle_st) then
					spi_clk_i	<=	cpol;
				elsif (spi_event = '1') then 
					spi_clk_i	<= not spi_clk_i;
				else
					spi_clk_i	<=	spi_clk_i;
				end if;
			end if;
		end if;
	end process spi_clk_proc;
	
	--------------------------------------------------------------------------
	--------------------------	spi_clk_cnt_proc proces	----------------------
	--------------------------------------------------------------------------
	-- This process handles with a clock counter, which count backwords the
	-- number of System Clock's rising edges, in order to divide the System
	-- Clock to SPI_CLK.
	--------------------------------------------------------------------------
	spi_clk_cnt_proc: process (clk, rst)
	begin
		if (rst = reset_polarity_g) then
			clk_cnt	<=	'0' & conv_std_logic_vector (dval_clk_reg_g - 2, reg_addr_width_g);
		
		elsif rising_edge(clk) then
			if (cur_st = assert_ss_st) then
				clk_cnt	<=	'0' & div_reg (reg_width_g - 1 downto 0);
			elsif (clk_cnt (reg_width_g) = '1') then --Clock should be inverted
				clk_cnt (reg_width_g) 	<= '0';
				clk_cnt	(reg_width_g - 1 downto 0)	<= div_reg	(reg_width_g - 1 downto 0); --TODO: Think about how many cycles...
			elsif (cur_st = data_st) then
				clk_cnt	<= clk_cnt - '1';
			else
				clk_cnt	<=	clk_cnt;
			end if;
		end if;
	end process spi_clk_cnt_proc;
	
	
	--------------------------------------------------------------------------
	--------------------------	prop_en_proc proces	--------------------------
	--------------------------------------------------------------------------
	-- This process asserts / negates Data Propagation Enable signal,
	-- according to CPOL, CPHA and SPI_CLK.
	-- When PROP_EN = '1', then data will be propagated to the SPI Slave.
	--------------------------------------------------------------------------
	prop_en_proc: process (clk, rst)
	begin
		if (rst = reset_polarity_g) then
			prop_en 	<= '0';
		
		elsif rising_edge(clk) then
			if (spi_event = '1') then
				if ((cpol = '0') and (cpha = '0') and (spi_clk_i = '1')) 		--CPOL = '0', CPHA = '0' and falling edge at SPI_CLK (='1' since it will be '0' after spi_event)
				or ((cpol = '0') and (cpha = '1') and (spi_clk_i = '0'))		--CPOL = '0', CPHA = '1' and rising edge at SPI_CLK (='0' since it will be '1' after spi_event)
				or ((cpol = '1') and (cpha = '0') and (spi_clk_i = '0'))		--CPOL = '1', CPHA = '0' and rising edge at SPI_CLK (='0' since it will be '1' after spi_event)
				or ((cpol = '1') and (cpha = '1') and (spi_clk_i = '1'))		--CPOL = '1', CPHA = '1' and falling edge at SPI_CLK (='1' since it will be '0' after spi_event)
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
	--------------------------	samp_en_proc proces	--------------------------
	--------------------------------------------------------------------------
	-- This process asserts / negates Data Sample Enable signal, according to
	-- CPOL, CPHA and SPI_CLK.
	-- When SAMP_EN = '1', then data will be sampled from the SPI Slave.
	--------------------------------------------------------------------------
	samp_en_proc: process (clk, rst)
	begin
		if (rst = reset_polarity_g) then
			samp_en 	<= '0';
		
		elsif rising_edge(clk) then
			if (spi_event = '1') then
				if ((cpol = '0') and (cpha = '0') and (spi_clk_i = '0')) 		--CPOL = '0', CPHA = '0' and rising edge at SPI_CLK (='0' since it will be '1' after spi_event)
				or ((cpol = '0') and (cpha = '1') and (spi_clk_i = '1'))		--CPOL = '0', CPHA = '1' and falling edge at SPI_CLK (='1' since it will be '0' after spi_event)
				or ((cpol = '1') and (cpha = '0') and (spi_clk_i = '1'))		--CPOL = '1', CPHA = '0' and falling edge at SPI_CLK (='1' since it will be '0' after spi_event)
				or ((cpol = '1') and (cpha = '1') and (spi_clk_i = '0'))		--CPOL = '1', CPHA = '1' and rising edge at SPI_CLK (='0' since it will be '1' after spi_event)
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
	
end architecture rtl_spi_master;