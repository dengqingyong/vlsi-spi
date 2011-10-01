------------------------------------------------------------------------------------------------
-- Entity Name 	:	Wishbone Slave Interface of the SPI Master - Test Bench
-- File Name	:	tb_wbs_spi.vhd
-- Generated	:	30.09.2011
-- Author		:	Beeri Schreiber and Omer Shaked
-- Project		:	SPI Project
------------------------------------------------------------------------------------------------
-- Description: TB for WBS
--
--				Type Commands, in the Message Pack:
--					(*) x"01"	:	Write
--					(*) x"02"	:	Read
--
--				Tag Cycle (WBS_TGC)
--					(*) '1'		:	Write to SPI Registers
--					(*) '0'		:	Transmit / Receive using SPI
------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date		Name					Description			
--			1.00		30.09.2011	Beeri Schreiber			Creation
------------------------------------------------------------------------------------------------
--	Todo:
--			(1) 
------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity tb_wbs_spi is
	generic
	(
		reset_polarity_g		:	std_logic	:= '0';									--RESET is active low
		data_width_g			:	positive	:= 8;									--Data width
		blen_width_g			:	positive	:= 9;									--Burst length width (maximum 2^9=512Kbyte Burst)
		addr_width_g			:	positive	:= 10;									--Address width
		reg_addr_width_g		:	positive	:= 8;									--SPI Registers address width
		reg_din_width_g			:	positive	:= 8									--SPI Registers data width
	);								
end entity tb_wbs_spi;

architecture sim of tb_wbs_spi is

----------------------------------	Constants	-------------------------------
constant type_wr_c		:	std_logic_vector (data_width_g - 1 downto 0) := x"01";	--Write
constant type_rd_c		:	std_logic_vector (data_width_g - 1 downto 0) := x"02";	--Read


----------------------------------	Components	-------------------------------
component wbs_spi
	generic
	(
		reset_polarity_g		:	std_logic	:= '0';									--RESET is active low
		data_width_g			:	positive	:= 8;									--Data width
		blen_width_g			:	positive	:= 9;									--Burst length width (maximum 2^9=512Kbyte Burst)
		addr_width_g			:	positive	:= 10;									--Address width
		reg_addr_width_g		:	positive	:= 8;									--SPI Registers address width
		reg_din_width_g			:	positive	:= 8									--SPI Registers data width
	);								
	port 								
	(								
		--Clock and Reset								
		clk_i					:	in std_logic;										--Wishbone Clock
		rst						:	in std_logic;										--Reset (Synchronous at deactivation, asynchronous in activation ==> cannot be Wishbone Reset)
		
		--Wishbone Interface
		wbs_cyc_i				:	in std_logic;										--Input Cycle
		wbs_stb_i				:	in std_logic;										--Input Strobe
		wbs_we_i				:	in std_logic;										--Input Write Enable
		wbs_adr_i				:	in std_logic_vector (addr_width_g - 1 downto 0);	--Input Address
		wbs_tga_i				:	in std_logic_vector (blen_width_g - 1 downto 0);	--Burst Length
		wbs_dat_i				:	in std_logic_vector (data_width_g - 1 downto 0);	--Input Data
		wbs_tgc_i				:	in std_logic;										--'1' - Write to SPI Registers ; '0' - Transmit / recieve using SPI
		wbs_dat_o				:	out std_logic_vector (data_width_g - 1 downto 0);	--Output Data
		wbs_stall_o				:	out std_logic;										--Output STALL (Hold strobe) 
		wbs_ack_o				:	out std_logic;										--Output Acknowledge
		wbs_err_o				:	out std_logic;										--Output Error
		
		--Message Pack Encoder Interface
		mp_enc_done				:	in std_logic;										--Message Pack from Encoder is Ready. SPI may start the TX
		mp_enc_reg_ready		:	out std_logic; 										--Registers are ready for reading. MP Encoder can start transmitting
		mp_enc_type_reg			:	out std_logic_vector (data_width_g - 1 downto 0);	--Message Type register
		mp_enc_addr_reg			:	out std_logic_vector (addr_width_g - 1 downto 0);	--Message Address register
		mp_enc_len_reg			:	out std_logic_vector (blen_width_g - 1 downto 0);	--Message Length Register
		
		--Message Pack Decoder Interface
		mp_dec_done				:	in std_logic;										--Message Pack has been recieved
		mp_dec_eof_err			:	in std_logic;										--EOF has not detected
		mp_dec_crc_err			:	in std_logic;										--CRC error
		mp_dec_type_reg			:	in std_logic_vector (data_width_g - 1 downto 0);	--Message Type register
		mp_dec_addr_reg			:	in std_logic_vector (addr_width_g - 1 downto 0);	--Message Address register
		mp_dec_len_reg			:	in std_logic_vector (blen_width_g - 1 downto 0); 	--Message Length Register
		
		--RAM, for Encoder, Interface
		ram_enc_addr			:	out std_logic_vector (blen_width_g - 1 downto 0);	--Input address to RAM
		ram_enc_din				:	out std_logic_vector (data_width_g - 1 downto 0);	--Data to RAM
		ram_enc_din_val			:	out std_logic;										--Data is valid for RAM
		
		--RAM, from Decoder, Interface
		ram_dec_dout			:	in	std_logic_vector (data_width_g - 1 downto 0);	--Output Data from RAM
		ram_dec_dout_val		:	in	std_logic;										--Output data from RAM is valid
		ram_dec_addr			:	out std_logic_vector (blen_width_g - 1 downto 0);	--Output address to RAM
		ram_dec_aout_val		:	out std_logic;										--Output address to RAM is valid (request for data)
		
		--SPI Interface
		spi_we					:	out std_logic;										--Write Enable. In case of '0' (Reading) - SPI will be commanded to transfer garbage data, in order to receive valid data
		spi_reg_addr			:	out std_logic_vector (reg_addr_width_g - 1 downto 0);	--Address to registers
		spi_reg_din				:	out std_logic_vector (reg_din_width_g - 1 downto 0);		--Data to registers
		spi_reg_din_val			:	out std_logic;											--Data to registers is valid
		spi_reg_ack				:	in	std_logic;										--SPI Registers - data acknowledged
		spi_reg_err				:	in	std_logic										--SPI Registers - error while writing data to SPI
	);
end component wbs_spi;

----------------------------------	Signals	-------------------------------
		--Clock and Reset								
signal	clk_i					:	std_logic := '0';										--Wishbone Clock
signal	rst						:	std_logic;										--Reset (Synchronous at deactivation, asynchronous in activation ==> cannot be Wishbone Reset)
	
		--Wishbone Interface
signal	wbs_cyc_i				:	std_logic := '0';										--Input Cycle
signal	wbs_stb_i				:	std_logic := '0';										--Input Strobe
signal	wbs_we_i				:	std_logic;										--Input Write Enable
signal	wbs_adr_i				:	std_logic_vector (addr_width_g - 1 downto 0);	--Input Address
signal	wbs_tga_i				:	std_logic_vector (blen_width_g - 1 downto 0);	--Burst Length
signal	wbs_dat_i				:	std_logic_vector (data_width_g - 1 downto 0);	--Input Data
signal	wbs_tgc_i				:	std_logic;										--'1' - Write to SPI Registers ; '0' - Transmit / recieve using SPI
signal	wbs_dat_o				:	std_logic_vector (data_width_g - 1 downto 0);	--Output Data
signal	wbs_stall_o				:	std_logic;										--Output STALL (Hold strobe) 
signal	wbs_ack_o				:	std_logic;										--Output Acknowledge
signal	wbs_err_o				:	std_logic;										--Output Error
	
		--Message Pack Encoder Interface
signal	mp_enc_done				:	std_logic := '0';										--Message Pack from Encoder is Ready. SPI may start the TX
signal	mp_enc_reg_ready		:	std_logic; 										--Registers are ready for reading. MP Encoder can start transmitting
signal	mp_enc_type_reg			:	std_logic_vector (data_width_g - 1 downto 0);	--Message Type register
signal	mp_enc_addr_reg			:	std_logic_vector (addr_width_g - 1 downto 0);	--Message Address register
signal	mp_enc_len_reg			:	std_logic_vector (blen_width_g - 1 downto 0);	--Message Length Register
	
		--Message Pack Decoder Interface
signal	mp_dec_done				:	std_logic := '0';										--Message Pack has been recieved
signal	mp_dec_eof_err			:	std_logic := '0';										--EOF has not detected
signal	mp_dec_crc_err			:	std_logic := '0';										--CRC error
signal	mp_dec_type_reg			:	std_logic_vector (data_width_g - 1 downto 0);	--Message Type register
signal	mp_dec_addr_reg			:	std_logic_vector (addr_width_g - 1 downto 0);	--Message Address register
signal	mp_dec_len_reg			:	std_logic_vector (blen_width_g - 1 downto 0); 	--Message Length Register
		
		--RAM, for Encoder, Interface
signal	ram_enc_addr			:	std_logic_vector (blen_width_g - 1 downto 0);	--Input address to RAM
signal	ram_enc_din				:	std_logic_vector (data_width_g - 1 downto 0);	--Data to RAM
signal	ram_enc_din_val			:	std_logic := '0';										--Data is valid for RAM
	
		--RAM, from Decoder, Interface
signal	ram_dec_dout			:	std_logic_vector (data_width_g - 1 downto 0);	--Output Data from RAM
signal	ram_dec_dout_val		:	std_logic;										--Output data from RAM is valid
signal	ram_dec_addr			:	std_logic_vector (blen_width_g - 1 downto 0);	--Output address to RAM
signal	ram_dec_aout_val		:	std_logic := '0';										--Output address to RAM is valid (request for data)
	
		--SPI Interface
signal	spi_we					:	std_logic;										--Write Enable. In case of '0' (Reading) - SPI will be commanded to transfer garbage data, in order to receive valid data
signal	spi_reg_addr			:	std_logic_vector (reg_addr_width_g - 1 downto 0);	--Address to registers
signal	spi_reg_din				:	std_logic_vector (reg_din_width_g - 1 downto 0);		--Data to registers
signal	spi_reg_din_val			:	std_logic := '0';											--Data to registers is valid
signal	spi_reg_ack				:	std_logic;										--SPI Registers - data acknowledged
signal	spi_reg_err				:	std_logic;										--SPI Registers - error while writing data to SPI
----------------------------------	Implementation	-----------------------
begin

clk_proc: 
clk_i	<=	not clk_i after 10 ns;

rst_proc:
rst		<= reset_polarity_g, (not reset_polarity_g) after 20 ns;

--Instance: WBS
wbs_inst: wbs_spi generic map
			(
			reset_polarity_g	=>	reset_polarity_g	,
			data_width_g	    =>	data_width_g		,
			blen_width_g	    =>	blen_width_g		,
			addr_width_g	    =>	addr_width_g		,
			reg_addr_width_g    =>	reg_addr_width_g	,
			reg_din_width_g	    =>	reg_din_width_g		
			)
			port map
			(
			clk_i				=>	clk_i				,
			rst				    =>	rst					,
			wbs_cyc_i		    =>	wbs_cyc_i			,
			wbs_stb_i		    =>	wbs_stb_i			,
			wbs_we_i		    =>	wbs_we_i			,
			wbs_adr_i		    =>	wbs_adr_i			,
			wbs_tga_i		    =>	wbs_tga_i			,
			wbs_dat_i		    =>	wbs_dat_i			,
			wbs_tgc_i		    =>	wbs_tgc_i			,
			wbs_dat_o		    =>	wbs_dat_o			,
			wbs_stall_o		    =>	wbs_stall_o			,
			wbs_ack_o		    =>	wbs_ack_o			,
			wbs_err_o		    =>	wbs_err_o			,
			mp_enc_done		    =>	mp_enc_done			,
			mp_enc_reg_ready    =>	mp_enc_reg_ready	,
			mp_enc_type_reg	    =>	mp_enc_type_reg		,
			mp_enc_addr_reg	    =>	mp_enc_addr_reg		,
			mp_enc_len_reg	    =>	mp_enc_len_reg		,
			mp_dec_done		    =>	mp_dec_done			,
			mp_dec_eof_err	    =>	mp_dec_eof_err		,
			mp_dec_crc_err	    =>	mp_dec_crc_err		,
			mp_dec_type_reg	    =>	mp_dec_type_reg		,
			mp_dec_addr_reg	    =>	mp_dec_addr_reg		,
			mp_dec_len_reg	    =>	mp_dec_len_reg		,
			ram_enc_addr	    =>	ram_enc_addr		,
			ram_enc_din		    =>	ram_enc_din			,
			ram_enc_din_val	    =>	ram_enc_din_val		,
			ram_dec_dout	    =>	ram_dec_dout		,
			ram_dec_dout_val    =>	ram_dec_dout_val	,
			ram_dec_addr	    =>	ram_dec_addr		,
			ram_dec_aout_val    =>	ram_dec_aout_val	,
			spi_we			    =>	spi_we				,
			spi_reg_addr	    =>	spi_reg_addr		,
			spi_reg_din		    =>	spi_reg_din			,
			spi_reg_din_val	    =>	spi_reg_din_val		,
			spi_reg_ack		    =>	spi_reg_ack			,
			spi_reg_err		    =>	spi_reg_err			
			);

tb_proc: process

--Write Data
procedure wr_data (blen : in positive) is
begin
	wait until rising_edge(clk_i);
	wbs_cyc_i	<=	'1';
	wbs_stb_i	<=	'1';
	wbs_we_i	<=	'1';
	wbs_adr_i	<=	(others => '0');
	wbs_tga_i	<=	conv_std_logic_vector (blen - 1, blen_width_g);
	wbs_dat_i	<=	(others => '0');
	wbs_tgc_i	<=	'0';	--Write data
	wait until wbs_stall_o = '0';
	wait until rising_edge(clk_i);
	for idx in 1 to blen loop
		wbs_dat_i	<=	wbs_dat_i + '1';
		wbs_adr_i	<=	wbs_adr_i + '1';
		wait until rising_edge(clk_i);
	end loop;
	wbs_cyc_i	<=	'0';
	wbs_stb_i	<=	'0';
	wbs_we_i	<=	'0';
	wbs_adr_i	<=	(others => '0');
	wbs_tga_i	<=	(others => '0');
	wbs_dat_i	<=	(others => '0');
	wbs_tgc_i	<=	'0';
	wait for 30 ns;
	mp_enc_done	<=	'1';
	wait until rising_edge(clk_i);
	mp_enc_done	<=	'0';
	wait until rising_edge(clk_i);
end procedure wr_data;

--Read Data
procedure rd_data (blen : in positive) is
begin
	wait until rising_edge(clk_i);
	wbs_cyc_i	<=	'1';
	wbs_stb_i	<=	'1';
	wbs_we_i	<=	'0';
	wbs_adr_i	<=	(others => '0');
	wbs_tga_i	<=	conv_std_logic_vector (blen - 1, blen_width_g);
	wbs_tgc_i	<=	'0';	--Read data
	wait until rising_edge(clk_i);
	wait for 50 ns;
	mp_dec_done	<=	'1';
	wait until rising_edge(clk_i);
	mp_dec_done	<=	'0';
	wait until wbs_stall_o = '0';
	ram_dec_dout_val	<=	'1';
	-- mp_enc_done	<=	'1';
	-- wait until rising_edge(clk_i);
	-- mp_enc_done	<=	'0';
	-- wait until rising_edge(clk_i);
	wait until falling_edge(ram_dec_aout_val); 
	wait until rising_edge(clk_i);
	ram_dec_dout_val	<=	'0';
	wait until rising_edge(clk_i);
	wbs_cyc_i	<=	'0';
	wbs_stb_i	<=	'0';
	wbs_we_i	<=	'0';
	wbs_adr_i	<=	(others => '0');
	wbs_tga_i	<=	(others => '0');
	wbs_tgc_i	<=	'0';	--Read data
end procedure rd_data;

--Write Regs
procedure wr_regs is
begin
	wait until rising_edge(clk_i);
	wbs_cyc_i	<=	'1';
	wbs_stb_i	<=	'1';
	wbs_we_i	<=	'1';
	wbs_adr_i	<=	(others => '0');
	wbs_tga_i	<=	(others => '0');
	wbs_dat_i	<=	(others => '0');
	wbs_tgc_i	<=	'1';	--Write Regs
	wait until wbs_stall_o = '0';
	wait until rising_edge(clk_i);
	spi_reg_ack	<=	'1';
	wait until rising_edge(clk_i);
	spi_reg_ack	<=	'0';
	wbs_cyc_i	<=	'0';
	wbs_stb_i	<=	'0';
	wbs_we_i	<=	'0';
	wbs_adr_i	<=	(others => '0');
	wbs_tga_i	<=	(others => '0');
	wbs_dat_i	<=	(others => '0');
	wbs_tgc_i	<=	'0';
	wait until rising_edge(clk_i);
end procedure wr_regs;

begin
	wait until (rst = not reset_polarity_g);
	wr_data (10);
	wait for 200 ns;
	rd_data (10);
	wait for 200 ns;
	wr_regs;
	wait for 200 ns;
	report "End of simulation" severity failure;
	wait;
end process tb_proc;			
			
end architecture sim;