------------------------------------------------------------------------------------------------
-- Entity Name 	:	SPI Slave Test Bench 2
-- File Name	:	spi_slave_tb_2.vhd
-- Generated	:	06.10.2011
-- Author		:	Beeri Schreiber and Omer Shaked
-- Project		:	SPI Project
------------------------------------------------------------------------------------------------
-- Description: This is a SPI Slave TB 
-- differences from tb1:
--						(1) Checks reading information from the FIFO
--						(2)	Checks the FSM handling of mid-transaction SS toggle 
--							(becoming NOT ACTIVE during transaction).
--						(3) Working with CPOL = CPHA = 1.
------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date		Name					Description			
--			1.00		04.10.2011	Omer Shaked				Creation
------------------------------------------------------------------------------------------------
--	Todo:
--			(1) 
------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity spi_slave_tb_2 is
	generic (	reset_polarity_g	:	std_logic	:= '0';		--Reset polarity. '0' is active low, '1' is active high
				ss_polarity_g		:	std_logic	:= '0';		--Slave Select polarity. '0' is active low, '1' is active high
				data_width_g		:	positive range 2 to positive'high	:= 8;		--Shift register is 8 bits. Range is from 2 - for the Shift Register
				reg_width_g			:	positive	:= 8;		--Number of bits in SPI configuration Register
				dval_cpha_g			:	std_logic	:= '0';		--Default (initial) value of CPHA
				dval_cpol_g			:	std_logic	:= '0';		--Default (initial) value of CPOL
				first_dat_lsb		:	boolean		:= true;	--TRUE: Transmit and Receive LSB first. FALSE - MSB first
				default_dat_g		:	integer		:= 5;		--Default data transmitted to master when the FIFO is empty
				clk_period_g		:	natural		:= 50000000	--Clock Period (50MHz)
			);
end entity spi_slave_tb_2;

architecture sim of spi_slave_tb_2 is

-------------------------------	Components	------------------------------------
component spi_slave
	generic (
				reset_polarity_g	:	std_logic	:= '0';		--Reset polarity. '0' is active low, '1' is active high
				ss_polarity_g		:	std_logic	:= '0';		--Slave Select polarity. '0' is active low, '1' is active high
				data_width_g		:	positive range 2 to positive'high	:= 8;		--Shift register is 8 bits. Range is from 2 - for the Shift Register
				reg_width_g			:	positive	:= 8;		--Number of bits in SPI configuration Register
				dval_cpha_g			:	std_logic	:= '0';		--Default (initial) value of CPHA
				dval_cpol_g			:	std_logic	:= '0';		--Default (initial) value of CPOL
				first_dat_lsb		:	boolean		:= true;	    --TRUE: Transmit and Receive LSB first. FALSE - MSB first
				default_dat_g		:	integer		:= 0		--Default data transmitted to master when the FIFO is empty
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
end component spi_slave;

-------------------------------------------	Signals	---------------------------------
	signal clk				:	std_logic := '0';
	signal rst				:	std_logic := not reset_polarity_g;

	signal spi_clk			:	std_logic := dval_cpol_g;
	signal spi_mosi			:	std_logic := '0';
	signal spi_miso			:	std_logic;
	signal spi_ss			:	std_logic;

	signal fifo_req_data	:	std_logic;											
	signal fifo_din			:	std_logic_vector (data_width_g - 1 downto 0);		
	signal fifo_din_valid	:	std_logic := '0';											
	signal fifo_empty		:	std_logic;											

	signal reg_din			:	std_logic_vector (reg_width_g - 1 downto 0) := (others => '0');	
	signal reg_din_val		:	std_logic := '0';
	signal reg_ack			:	std_logic;										
	signal reg_err			:	std_logic;

	signal busy				: 	std_logic;
	signal interrupt		:	std_logic;
	signal dout				:	std_logic_vector (data_width_g - 1 downto 0);											
	signal dout_valid		:	std_logic;	

begin

	spi_slave_inst	:	spi_slave	generic map
								(
								reset_polarity_g	=>	reset_polarity_g,
								ss_polarity_g		=>	ss_polarity_g,
								data_width_g		=>	data_width_g,
								reg_width_g			=>	reg_width_g,
								dval_cpha_g			=>	dval_cpha_g,
								dval_cpol_g			=>	dval_cpol_g,
								first_dat_lsb		=>	first_dat_lsb,
								default_dat_g		=>	default_dat_g
								)
								port map
								(
								clk					=>	clk,
								rst					=>	rst,
								spi_clk				=>	spi_clk,
								spi_mosi			=>	spi_mosi,		
								spi_miso			=>	spi_miso,
								spi_ss				=>	spi_ss,
								fifo_req_data		=>	fifo_req_data,	
								fifo_din			=>	fifo_din,
								fifo_din_valid		=>	fifo_din_valid,
								fifo_empty			=>	fifo_empty,
								reg_din				=>	reg_din,
								reg_din_val			=>	reg_din_val,
								reg_ack				=>	reg_ack,
								reg_err				=>	reg_err,
								busy				=>	busy,
								interrupt			=>	interrupt,
								dout				=>	dout,
								dout_valid			=>	dout_valid
								);
								
	clk_proc:
	clk	<=	not clk after 1 sec / (real(clk_period_g*2));

	spi_clk_proc: process
	begin
		wait until falling_edge(spi_ss);
		wait for 100 ns;
		for i in 0 to 16 loop
			spi_clk	<=	not spi_clk;	-- SCK freq is 5 MHz
			wait for 100 ns;
		end loop;
		spi_clk	<=	'1';
		wait until falling_edge(spi_ss);
		wait for 100 ns;
		for i in 0 to 20 loop
			spi_clk	<=	not spi_clk;	-- SCK freq is 5 MHz
			wait for 100 ns;
		end loop;
	end process spi_clk_proc;

	rst_proc:
	rst	<=	reset_polarity_g, not reset_polarity_g after 100 ns;

	slave_select_proc: process
	begin	
		spi_ss	<=	'1';
		wait for 200 ns;
		spi_ss	<=	'0';
		wait for 1600 ns;
		spi_ss	<=	'1';
		wait for 300 ns;
		spi_ss	<=	'0';
		wait for 1000 ns;
		spi_ss	<=	'1';
		wait;
	end process slave_select_proc;

	spi_data_proc: process
	begin
		wait for 200 ns;
		for i in 0 to 3 loop
			spi_mosi	<= '0';
			wait for 200 ns;
			spi_mosi	<=	'1';
			wait for 200 ns;
		end loop;
		wait until falling_edge(spi_ss);
		wait for 100 ns;
		for i in 0 to 3 loop
			spi_mosi	<= '1';
			wait for 200 ns;
			spi_mosi	<=	'0';
			wait for 200 ns;
		end loop;
		wait;
	end process spi_data_proc;
	
	fifo_data_proc: process
	begin
		fifo_empty	<=	'0';
		fifo_din	<=	"00110011";
		fifo_din_valid	<=	'0';
		wait until rising_edge(fifo_req_data);
		wait for 20 ns;
		fifo_din_valid	<=	'1';
		wait for 20 ns;
		fifo_empty	<=	'1';
		fifo_din_valid	<=	'0';
		wait;
	end process fifo_data_proc;

	conf_reg_proc: process
	begin
		reg_din	<=	(0	=>	'1', 1	=>	'1', others	=>	'0');
		reg_din_val	<=	'0';
		wait for 300 ns;
		wait until (spi_ss	=	'1');
		wait for 100 ns;
		wait until rising_edge(clk);
		reg_din_val	<=	'1';
		wait until rising_edge(reg_ack);
		reg_din_val	<=	'0';
		wait;
	end process conf_reg_proc;
	
end architecture sim;









								
								
								
								
								
								