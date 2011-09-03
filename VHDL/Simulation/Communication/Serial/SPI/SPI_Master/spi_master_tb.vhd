------------------------------------------------------------------------------------------------
-- Entity Name 	:	SPI Master Test Bench
-- File Name	:	spi_master_tb.vhd
-- Generated	:	02.09.2011
-- Author		:	Beeri Schreiber and Omer Shaked
-- Project		:	SPI Project
------------------------------------------------------------------------------------------------
-- Description: This is SPI Master TB
------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date		Name					Description			
--			1.00		02.09.2011	Beeri Schreiber			Creation
------------------------------------------------------------------------------------------------
--	Todo:
--			(1) 
------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity spi_master_tb is
	generic (
				reset_polarity_g	:	std_logic	:= '0';		--Reset polarity. '0' is active low, '1' is active high
				ss_polarity_g		:	std_logic	:= '0';		--Slave Select polarity. '0' is active low, '1' is active high
				data_width_g		:	positive range 2 to positive'high	:= 8;		--Shift register is 8 bits. Range is from 2 - for the Shift Register
				num_of_slaves_g		:	positive	:= 1;		--Number of slaves (determines SPI_SS bus width)
				reg_width_g			:	positive	:= 8;		--Number of bits in SPI Clock Divider Register
				dval_conf_reg_g		:	natural		:= 0;		--Default (initial) value of Configuration Register
				dval_clk_reg_g		:	positive range 2 to positive'high		:= 2;		--Default (initial) value of Clock Divide Register (Divide system clock by 2 is the minimum)
				reg_addr_width_g	:	positive	:= 8;		--Registers Configuration Address Width
				reg_din_width_g 	:	positive	:= 8;		--Registers Configuration Input Data Width
				first_dat_lsb		:	boolean		:= true;	--TRUE: Transmit and Receive LSB first. FALSE - MSB first
				
				clk_period_g		:	natural		:=	50000000--Clock Period (50MHz)
			);
end entity spi_master_tb;

architecture sim of spi_master_tb is

-------------------------------	Components	------------------------------------
component spi_master
	generic (
				reset_polarity_g	:	std_logic	:= '0';		--Reset polarity. '0' is active low, '1' is active high
				ss_polarity_g		:	std_logic	:= '0';		--Slave Select polarity. '0' is active low, '1' is active high
				data_width_g		:	positive range 2 to positive'high	:= 8;		--Shift register is 8 bits. Range is from 2 - for the Shift Register
				num_of_slaves_g		:	positive	:= 1;		--Number of slaves (determines SPI_SS bus width)
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
				spi_ss				:	out	std_logic_vector (num_of_slaves_g - 1 downto 0);	--Slave Select
				
				-- FIFO Interface (Input to SPI Master)
				fifo_req_data		:	out std_logic;											--Request for data from FIFO
				fifo_din			:	in	std_logic_vector (data_width_g - 1 downto 0);		--Data from FIFO
				fifo_din_valid		:	in	std_logic;											--Input data from FIFO
				fifo_empty			:	in	std_logic;											--FIFO is empty
				
				--Additional Ports:
				spi_slave_addr		:	in natural range 0 to (num_of_slaves_g - 1);			--Addressed slave
				
				-- Configuration Registers Ports
				reg_addr			:	in std_logic_vector (reg_addr_width_g - 1 downto 0);	--Address to registers
				reg_din				:	in std_logic_vector (reg_din_width_g - 1 downto 0);		--Data to registers
				reg_din_val			:	in std_logic;											--Data to registers is valid
				reg_ack				:	out std_logic;											--Data to registers has been acknowledged
				reg_err				:	out	std_logic;											--Error while trying to write data to registers
				
				-- Output from SPI Master
				dout				:	out std_logic_vector (data_width_g - 1 downto 0);		--Output data
				dout_valid			:	out std_logic											--Output data is valid
			);
end component spi_master;

-------------------------------------------	Signals	---------------------------------
signal clk				:	std_logic := '0';
signal rst				:	std_logic := not reset_polarity_g;

signal spi_clk			:	std_logic;
signal spi_mosi			:	std_logic;
signal spi_miso			:	std_logic;
signal spi_ss			:	std_logic_vector (num_of_slaves_g - 1 downto 0);

signal fifo_req_data	:	std_logic;											
signal fifo_din			:	std_logic_vector (data_width_g - 1 downto 0);		
signal fifo_din_valid	:	std_logic := '0';											
signal fifo_empty		:	std_logic;											

signal spi_slave_addr	:	natural range 0 to (num_of_slaves_g - 1);

signal reg_addr			:	std_logic_vector (reg_addr_width_g - 1 downto 0) := (others => '0');
signal reg_din			:	std_logic_vector (reg_din_width_g - 1 downto 0) := (others => '0');	
signal reg_din_val		:	std_logic := '0';
signal reg_ack			:	std_logic;										
signal reg_err			:	std_logic;

signal dout				:	std_logic_vector (data_width_g - 1 downto 0);											
signal dout_valid		:	std_logic;										


begin

clk_proc:
clk	<=	not clk after 1 sec / (real(clk_period_g*2));

rst_proc:
rst	<=	reset_polarity_g, not reset_polarity_g after 100 ns;

change_div_rate_proc: process 
begin
	wait for 1.4 us;
	wait until rising_edge (clk);
	reg_addr	<=	x"00";
	reg_din		<=	x"04";
	reg_din_val	<=	'1';
	wait until rising_edge (clk);
	reg_addr	<=	x"00";
	reg_din		<=	x"00";
	reg_din_val	<=	'0';
	wait;
end process change_div_rate_proc;

fifo_empty_proc: process
begin
	fifo_empty	<=	'0';
	wait for 600 ns;
	fifo_empty	<=	'1';
	wait for 1 us;
end process fifo_empty_proc;

spi_slave_addr_proc:
spi_slave_addr	<=	0;

fifo_data_proc: process
variable rand_val		:		std_logic_vector (data_width_g - 1 downto 0) := (others => '0');
begin
	wait until fifo_req_data = '1';
	rand_val		:=	rand_val + x"11";
	fifo_din		<=	rand_val;
	wait until rising_edge(clk);
	fifo_din_valid 	<= '1';
	wait until rising_edge(clk);
	fifo_din_valid 	<= '0';
end process fifo_data_proc;

spi_master_inst	:	spi_master generic map
							(
							reset_polarity_g	=>	reset_polarity_g,
							ss_polarity_g	    =>	ss_polarity_g	,
							data_width_g	    =>	data_width_g	,
							num_of_slaves_g	    =>	num_of_slaves_g	,
							reg_width_g		    =>	reg_width_g		,
							dval_conf_reg_g	    =>	dval_conf_reg_g	,
							dval_clk_reg_g	    =>	dval_clk_reg_g	,
							reg_addr_width_g    =>	reg_addr_width_g,
							reg_din_width_g     =>	reg_din_width_g ,
							first_dat_lsb	    =>	first_dat_lsb	
							)
							port map
							(
							clk					=>	clk				,			
							rst				    =>	rst				,
							spi_clk			    =>	spi_clk			,
							spi_mosi			=>	spi_mosi		,
							spi_miso			=>	spi_miso		,
							spi_ss			    =>	spi_ss			,
							fifo_req_data	    =>	fifo_req_data	,
							fifo_din			=>	fifo_din		,
							fifo_din_valid	    =>	fifo_din_valid	,
							fifo_empty		    =>	fifo_empty		,
							spi_slave_addr	    =>	spi_slave_addr	,
							reg_addr			=>	reg_addr		,
							reg_din			    =>	reg_din			,
							reg_din_val		    =>	reg_din_val		,
							reg_ack			    =>	reg_ack			,
							reg_err			    =>	reg_err			,
							dout				=>	dout			,
							dout_valid		    =>	dout_valid		
						);


end architecture sim;
