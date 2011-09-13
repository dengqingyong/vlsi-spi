------------------------------------------------------------------------------------------------
-- Entity Name 	:	Wishbone Slave Interface of the SPI Master
-- File Name	:	wbs_spi.vhd
-- Generated	:	10.09.2011
-- Author		:	Beeri Schreiber and Omer Shaked
-- Project		:	SPI Project
------------------------------------------------------------------------------------------------
-- Description: 
------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date		Name					Description			
--			1.00		10.09.2011	Beeri Schreiber			Creation
------------------------------------------------------------------------------------------------
--	Todo:
--			(1) 
------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity wbs_spi is
	generic
	(
		reset_polarity_g		:	std_logic	:= '0';									--RESET is active low
		data_width_g			:	positive	:= 8;									--Data width
		addr_width_g			:	positive	:= 10									--Address width
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
		mp_enc_addr_reg			:	out std_logic_vector (data_width_g - 1 downto 0);	--Message Address register
		mp_enc_len_reg			:	out std_logic_vector (data_width_g - 1 downto 0);	--Message Length Register
		
		--Message Pack Decoder Interface
		mp_dec_done				:	in std_logic;										--Message Pack has been recieved
		mp_dec_eof_err			:	in std_logic;										--EOF has not detected
		mp_dec_crc_err			:	in std_logic;										--CRC error
		mp_dec_type_reg			:	in std_logic_vector (data_width_g - 1 downto 0);	--Message Type register
		mp_dec_addr_reg			:	in std_logic_vector (data_width_g - 1 downto 0);	--Message Address register
		mp_dec_len_reg			:	in std_logic_vector (data_width_g - 1 downto 0); 	--Message Length Register
		
		--RAM, for Encoder, Interface
		ram_enc_addr			:	out std_logic_vector (addr_width_g - 1 downto 0);	--Input address to RAM
		ram_enc_din				:	out std_logic_vector (data_width_g - 1 downto 0);	--Data to RAM
		ram_enc_din_val			:	out std_logic;										--Data is valid for RAM
		
		--RAM, from Decoder, Interface
		ram_dec_addr			:	out std_logic_vector (addr_width_g - 1 downto 0);	--Output address to RAM
		ram_dec_aout_val		:	out std_logic;										--Output address to RAM is valid (request for data)
		ram_dec_dout			:	in	std_logic_vector (data_width_g - 1 downto 0);	--Output Data from RAM
		ram_dec_dout_val		:	in	std_logic;										--Output data from RAM is valid
		
		--SPI Interface
		spi_we					:	out std_logic										--Write Enable. In case of '0' (Reading) - SPI will be commanded to transfer garbage data, in order to receive valid data
	);
end entity wbs_spi;

architecture rtl of wbs_spi is

----------------------------------	Types	-----------------------------------
type fsm_states is
					(	idle_st,		--Idle
						neg_stall_st,	--Negate STALL
						tx_data_st,		--Transfer data from WBS I/F to M.P. Encoder
						rx_data_st		--Receive data from WBS I/F from M.P. Decoder
					);

----------------------------------	Signals	-----------------------------------
signal cur_st		:	fsm_states;		--FSM
signal int_we		:	std_logic;		--Internal Write Enable
signal tx_cnt		:	std_logic_vector (addr_width_g downto 0);	--TX Counter. Extra 1 bit, for comparing MSB to '1' (Reverse counting)

----------------------------------	Implementation	---------------------------
end architecture rtl;