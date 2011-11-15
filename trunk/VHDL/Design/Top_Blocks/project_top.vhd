------------------------------------------------------------------------------------------------
-- Entity Name 	:	TOP
-- File Name	:	project_top.vhd
-- Generated	:	5.11.2011
-- Author		:	Beeri Schreiber and Omer Shaked
-- Project		:	SPI Project
------------------------------------------------------------------------------------------------
-- Description: This is the TOP entity of the design.
--
-- MAX BURST SIZE = 256 Bytes
--
------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date		Name					Description			
--			1.00		5.11.2011	Omer Shaked				Creation
--
--
------------------------------------------------------------------------------------------------
--	Todo:
--			(1) 
------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity project_top is
	generic (
				-- General values
				reset_polarity_g	:	std_logic 	:= '0';
				ss_polarity_g		:	std_logic	:= '0';
				data_width_g		:	positive 	:= 8;		--RAM Data Width (UART = 8 bits)
				ext_addr_width_g	:	positive 	:= 10;		--Addres Width of External RAM (RAM size = 2**(addr_width_g))
				int_addr_width_g	:	positive 	:= 8;		--Addres Width of Internal RAM (RAM size = 2**(addr_width_g))
				reg_width_g			:	positive 	:= 8;		--Registers data width
				-- SPI SLAVE
				dval_cpha_g			:	std_logic	:= '0';	
				dval_cpol_g			:	std_logic	:= '0';
				first_dat_lsb		:	boolean		:= true;
				default_dat_g		:	integer		:= 0;
				spi_timeout_g		:	std_logic_vector (10 downto 0)	:=	"00100000010";
				timeout_en_g		:	std_logic	:= '0';	
				dval_miso_g			:	std_logic	:= '0';
				-- FIFO
				depth_g 			: 	positive	:= 9;	-- Maximum elements in FIFO
				log_depth_g			: 	natural		:= 4;	-- Logarithm of depth_g (Number of bits to represent depth_g. 2^4=16 > 9)
				almost_full_g		: 	positive	:= 8; 	-- Rise almost full flag at this number of elements in FIFO
				almost_empty_g		: 	positive	:= 1; 	-- Rise almost empty flag at this number of elements in FIFO
				-- MP_ENC + MP_DEC
				len_dec1_g			:	boolean 	:= true;	--TRUE - Recieved length is decreased by 1 ,to save 1 bit
				sof_d_g				:	positive	:= 1;		--SOF Depth
				type_d_g			:	positive	:= 1;		--Type Depth
				addr_d_g			:	positive 	:= 3;		--Address Depth
				len_d_g				:	positive 	:= 1;		--Length Depth
				crc_d_g				:	positive 	:= 1;		--CRC Depth
				eof_d_g				:	positive 	:= 1;		--EOF Depth		
				sof_val_g			:	natural 	:= 100;		-- (64h) SOF block value. Upper block is MSB
				eof_val_g			:	natural 	:= 200;		-- (C8h) EOF block value. Upper block is MSB
				-- Checksum
				signed_checksum_g	:	boolean		:= false;	--TRUE to signed checksum, FALSE to unsigned checksum
				checksum_init_val_g	:	integer		:= 0;		--Note that the initial value is given as an natural number
				checksum_out_width_g:	natural 	:= 8;		--Output CheckSum width
				-- RAM Controller
				save_bit_mode_g		:	integer		:= 1;		--1 - Increase burst_size by 1, 0 - don't increase burst size
				max_burst_g			:	positive 	:= 256;		--Maximum data burst (MUST be smaller than 2**(data_width_g))
				max_ext_addr_g		:	positive 	:= 2**10;	--Maximum External RAM address (value = 2**(ext_addr_width_g))
				type_width_g		:	positive	:= 8;		--Width of type register
				len_width_g			:	positive	:= 8;		--Width of len register
				-- WBS
				bits_of_slaves_g	:	positive	:= 1;		--Number of slaves bits (determines SPI_SS bus width)
				blen_width_g		:	positive	:= 8;		--Burst length width (maximum 2^8=256 byte Burst);
				addr_width_g		:	positive	:= 10;		--Address width
				addr_bits_g 		: 	POSITIVE 	:= 10;
				width_in_g 			: 	POSITIVE 	:= 8;
				reg_addr_width_g	:	positive	:= 8		--SPI Registers address width
			);
	port
			(
				--Inputs
				clk					:	in std_logic; 	--Clock
				rst					:	in std_logic;	--Reset
				
				--Outputs
				slave_timeout		: 	out std_logic; 	--SPI_SLAVE timeout
				slave_interrupt		:	out std_logic;		
				
				-- Wishbone Interface
				wbs_cyc_i			: 	in STD_LOGIC;
				wbs_stb_i 			: 	in STD_LOGIC;
				wbs_tgc_i 			: 	in STD_LOGIC;
				wbs_tgd_i 			: 	in STD_LOGIC;
				wbs_we_i 			: 	in STD_LOGIC;
				wbs_adr_i 			: 	in STD_LOGIC_VECTOR(addr_width_g-1 downto 0);
				wbs_dat_i 			: 	in STD_LOGIC_VECTOR(data_width_g-1 downto 0);
				wbs_tga_i 			: 	in STD_LOGIC_VECTOR(blen_width_g-1 downto 0);
				wbs_ack_o 			: 	out STD_LOGIC;
				wbs_err_o 			: 	out STD_LOGIC;
				wbs_stall_o 		: 	out STD_LOGIC;
				wbs_dat_o 			: 	out STD_LOGIC_VECTOR(data_width_g-1 downto 0)
			);
end entity project_top;

architecture rtl_top of project_top is

	-------------------------------	Components	------------------------------------

	component Master_Host
	  generic(
		   reset_polarity_g		:	std_logic	:= '0'									--RESET is active lo 
	  );
	  port(
		   clk_i : in STD_LOGIC;
		   rst : in STD_LOGIC;
		   spi_miso : in STD_LOGIC;
		   wbs_cyc_i : in STD_LOGIC;
		   wbs_stb_i : in STD_LOGIC;
		   wbs_tgc_i : in STD_LOGIC;
		   wbs_tgd_i : in STD_LOGIC;
		   wbs_we_i : in STD_LOGIC;
		   wbs_adr_i : in STD_LOGIC_VECTOR(9 downto 0);
		   wbs_dat_i : in STD_LOGIC_VECTOR(7 downto 0);
		   wbs_tga_i : in STD_LOGIC_VECTOR(7 downto 0);
		   spi_clk : out STD_LOGIC;
		   spi_mosi : out STD_LOGIC;
		   wbs_ack_o : out STD_LOGIC;
		   wbs_err_o : out STD_LOGIC;
		   wbs_stall_o : out STD_LOGIC;
		   spi_ss : out STD_LOGIC_VECTOR(0 downto 0);
		   wbs_dat_o : out STD_LOGIC_VECTOR(7 downto 0)
	  );
	end component Master_Host;

	component slave_host
		generic (
				-- General values
				reset_polarity_g	:	std_logic 	:= '0';
				ss_polarity_g		:	std_logic	:= '0';
				data_width_g		:	positive 	:= 8;		--RAM Data Width (UART = 8 bits)
				ext_addr_width_g	:	positive 	:= 10;		--Addres Width of External RAM (RAM size = 2**(addr_width_g))
				int_addr_width_g	:	positive 	:= 8;		--Addres Width of Internal RAM (RAM size = 2**(addr_width_g))
				reg_width_g			:	positive 	:= 8;		--Registers data width
				-- SPI SLAVE
				dval_cpha_g			:	std_logic	:= '0';	
				dval_cpol_g			:	std_logic	:= '0';
				first_dat_lsb		:	boolean		:= true;
				default_dat_g		:	integer		:= 0;
				spi_timeout_g		:	std_logic_vector (10 downto 0)	:=	"00000100000";
				timeout_en_g		:	std_logic	:= '1';	
				dval_miso_g			:	std_logic	:= '0';
				-- FIFO
				depth_g 			: 	positive	:= 9;	-- Maximum elements in FIFO
				log_depth_g			: 	natural		:= 4;	-- Logarithm of depth_g (Number of bits to represent depth_g. 2^4=16 > 9)
				almost_full_g		: 	positive	:= 8; 	-- Rise almost full flag at this number of elements in FIFO
				almost_empty_g		: 	positive	:= 1; 	-- Rise almost empty flag at this number of elements in FIFO
				-- MP_ENC + MP_DEC
				len_dec1_g			:	boolean 	:= true;	--TRUE - Recieved length is decreased by 1 ,to save 1 bit
				sof_d_g				:	positive	:= 1;		--SOF Depth
				type_d_g			:	positive	:= 1;		--Type Depth
				addr_d_g			:	positive 	:= 3;		--Address Depth
				len_d_g				:	positive 	:= 1;		--Length Depth
				crc_d_g				:	positive 	:= 1;		--CRC Depth
				eof_d_g				:	positive 	:= 1;		--EOF Depth		
				sof_val_g			:	natural 	:= 100;		-- (64h) SOF block value. Upper block is MSB
				eof_val_g			:	natural 	:= 200;		-- (C8h) EOF block value. Upper block is MSB
				-- Checksum
				signed_checksum_g	:	boolean		:= false;	--TRUE to signed checksum, FALSE to unsigned checksum
				checksum_init_val_g	:	integer		:= 0;		--Note that the initial value is given as an natural number
				checksum_out_width_g:	natural 	:= 8;		--Output CheckSum width
				-- RAM Controller
				save_bit_mode_g		:	integer		:= 1;		--1 - Increase burst_size by 1, 0 - don't increase burst size
				max_burst_g			:	positive 	:= 256;		--Maximum data burst (MUST be smaller than 2**(data_width_g))
				max_ext_addr_g		:	positive 	:= 2**10;	--Maximum External RAM address (value = 2**(ext_addr_width_g))
				type_width_g		:	positive	:= 8;		--Width of type register
				len_width_g			:	positive	:= 8		--Width of len register
				);
		port
				(
				--Inputs
				clk					:	in std_logic; 	--Clock
				rst					:	in std_logic;	--Reset
				
				--Outputs
				timeout				: 	out std_logic; 	--SPI_SLAVE timeout
				busy				:	out std_logic;											--'1' - BUSY: Transaction is active
				interrupt			:	out std_logic;											--'1' - Slave Select turned NOT active in the mid-transaction
				
				--External RAM Interface - READ and WRITE
				wr_addr				:	out std_logic_vector (ext_addr_width_g - 1 downto 0); 	--Address for External RAM write
				rd_addr				:	out std_logic_vector (ext_addr_width_g - 1 downto 0); 	--Address for External RAM read
				wr_data				:	out std_logic_vector (data_width_g - 1 downto 0);	  	--Data for external RAM write
				wr_valid			:	out std_logic;										  	--Write data and address are valid
				rd_valid			:	out std_logic;										  	--Read address is valid
				ram_data			:	in std_logic_vector (data_width_g - 1 downto 0);	  	--Input data from External RAM
				ram_valid			:	in std_logic; 	      								  	--Data from external RAM is valid
				
				-- SPI Interface
				spi_clk				:	in  std_logic;								  	--Input SPI Clock from SPI master
				spi_mosi			:	in	std_logic;									--Data: Master output, slave input
				spi_miso			:	out std_logic;									--Data: Master input, slave output
				spi_ss				:	in	std_logic;									--Slave Select
				
				-- Configuration Interface
				reg_din				:	in std_logic_vector (reg_width_g - 1 downto 0);			--Data to registers
				reg_din_val			:	in std_logic;											--Data to registers is valid
				reg_ack				:	out std_logic											--Data to registers has been acknowledged
				);
	end component slave_host;
	
	component ram_simple
		generic (
					reset_polarity_g	:	std_logic 	:= '0';	--'0' - Active Low Reset, '1' Active High Reset
					width_in_g			:	positive 	:= 8;	--Width of data
					addr_bits_g			:	positive 	:= 10	--Depth of data	(2^10 = 1024 addresses)
				);
		port	(
					clk			:	in std_logic;									--System clock
					rst			:	in std_logic;									--System Reset
					addr_in		:	in std_logic_vector (addr_bits_g - 1 downto 0); --Input address
					addr_out	:	in std_logic_vector (addr_bits_g - 1 downto 0); --Output address
					aout_valid	:	in std_logic;									--Output address is valid
					data_in		:	in std_logic_vector (width_in_g - 1 downto 0);	--Input data
					din_valid	:	in std_logic; 									--Input data valid
					data_out	:	out std_logic_vector (width_in_g - 1 downto 0);	--Output data
					dout_valid	:	out std_logic 									--Output data valid
				);
	end component ram_simple;	


	-------------------------------------------------
	---------------  SIGNALS  -----------------------
	-------------------------------------------------
	signal spi_clk		:	std_logic;								  		--Input SPI Clock from SPI master
	signal spi_mosi		:	std_logic;										--Data: Master output, slave input
	signal spi_miso		:	std_logic;										--Data: Master input, slave output
	signal spi_ss		:	std_logic_vector(bits_of_slaves_g-1 downto 0);	--Slave Select

	--External RAM Interface - READ and WRITE
	signal wr_addr		:	std_logic_vector (ext_addr_width_g - 1 downto 0); 	--Address for External RAM write
	signal rd_addr		:	std_logic_vector (ext_addr_width_g - 1 downto 0); 	--Address for External RAM read
	signal wr_data		:	std_logic_vector (data_width_g - 1 downto 0);	  	--Data for external RAM write
	signal wr_valid		:	std_logic;										  	--Write data and address are valid
	signal rd_valid		:	std_logic;										  	--Read address is valid
	signal ram_data		:	std_logic_vector (data_width_g - 1 downto 0);	  	--Input data from External RAM
	signal ram_valid	:	std_logic; 	      								  	--Data from external RAM is valid
	

begin
	
	master_inst	:	master_host	generic map
								(
								reset_polarity_g		=>	reset_polarity_g
								)
								port map
								(
								clk_i 		=>	clk,
								rst			=>	rst,
								spi_miso	=>	spi_miso, 
								wbs_cyc_i 	=>	wbs_cyc_i,
								wbs_stb_i 	=>	wbs_stb_i,
								wbs_tgc_i 	=>	wbs_tgc_i,
								wbs_tgd_i	=>	wbs_tgd_i,
								wbs_we_i 	=>	wbs_we_i,
								wbs_adr_i 	=>	wbs_adr_i,
								wbs_dat_i 	=>	wbs_dat_i,
								wbs_tga_i 	=>	wbs_tga_i,
								spi_clk 	=>	spi_clk,
								spi_mosi 	=>	spi_mosi,
								wbs_ack_o 	=>	wbs_ack_o,
								wbs_err_o	=>	wbs_err_o, 
								wbs_stall_o =>	wbs_stall_o,
								spi_ss 		=>	spi_ss,
								wbs_dat_o	=>	wbs_dat_o
								);
								
	slave_inst	:	slave_host generic map
								(
								reset_polarity_g		=>	reset_polarity_g,
								ss_polarity_g			=>	ss_polarity_g,	
								data_width_g			=>	data_width_g,		
								ext_addr_width_g		=>	ext_addr_width_g,	
								int_addr_width_g		=>	int_addr_width_g,	
								reg_width_g				=>	reg_width_g,		
								first_dat_lsb			=>	first_dat_lsb,		
								default_dat_g			=>	default_dat_g,		
								spi_timeout_g			=>	spi_timeout_g,		
								timeout_en_g			=>	timeout_en_g,		
								len_dec1_g				=>	len_dec1_g,		
								sof_d_g					=>	sof_d_g,			
								type_d_g				=>	type_d_g,			
								addr_d_g				=>	addr_d_g,			
								len_d_g					=>	len_d_g,		
								crc_d_g					=>	crc_d_g,			
								eof_d_g					=>	eof_d_g,			
								sof_val_g				=>	sof_val_g,			
								eof_val_g				=>	eof_val_g,			
								signed_checksum_g		=>	signed_checksum_g,	
								checksum_init_val_g		=>	checksum_init_val_g,	
								checksum_out_width_g	=>	checksum_out_width_g,
								save_bit_mode_g			=>	save_bit_mode_g,
								max_burst_g				=>	max_burst_g,		
								max_ext_addr_g			=>	max_ext_addr_g,		
								type_width_g			=>	type_width_g,		
								len_width_g				=>	len_width_g
								)								
								port map
								(
								clk				=>	clk,
								rst				=>	rst,
								timeout			=>	slave_timeout,
								interrupt		=>	slave_interrupt,
								wr_addr			=>	wr_addr,
								rd_addr			=>	rd_addr,
								wr_data			=>	wr_data,
								wr_valid		=>	wr_valid,
								rd_valid		=>	rd_valid,
								ram_data		=>	ram_data,
								ram_valid		=>	ram_valid,
								spi_clk			=>	spi_clk,
								spi_mosi		=>	spi_mosi,
								spi_miso		=>	spi_miso,
								spi_ss			=>	spi_ss(0),
								reg_din			=>	(others	=>	'0'),
								reg_din_val		=>	'0'
								);

		ram_inst:  ram_simple
		generic map (
					reset_polarity_g	=>	reset_polarity_g,
					width_in_g			=>	width_in_g,
					addr_bits_g			=>	addr_bits_g
				)
		port map	(
					clk			=>	clk,
					rst			=>	rst,
					addr_in		=>	wr_addr,                               	
					addr_out	=>	rd_addr,                               	
					aout_valid	=>	rd_valid,                               	
					data_in		=>	wr_data,                               	
					din_valid	=>	wr_valid,                               	
					data_out	=>	ram_data,                               	
					dout_valid	=>	ram_valid                               
				);

								
end architecture rtl_top;



