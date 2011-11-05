-------------------------------------------------------------------------------
--
-- Title       : Master_Host
-- Design      : Beeri_VHPI
-- Author      : Beeri Schreiber
-- Company     : Technion
--
-------------------------------------------------------------------------------
--
-- Description : 
--
-------------------------------------------------------------------------------
-- Design unit header --
library IEEE;
use IEEE.std_logic_1164.all;   
use ieee.math_real.all;


entity Master_Host is
  generic(
				len_dec1_g			:	boolean := true;	--TRUE - Recieved length is decreased by 1 ,to save 1 bit
															--FALSE - Recieved length is the actual length
				
				sof_d_g				:	positive := 1;		--SOF Depth
				type_d_g			:	positive := 1;		--Type Depth
				addr_d_g			:	positive := 3;		--Address Depth
				len_d_g				:	positive := 2;		--Length Depth
				crc_d_g				:	positive := 1;		--CRC Depth
				eof_d_g				:	positive := 1;		--EOF Depth
						
				sof_val_g			:	natural := 100;		-- (64h) SOF block value. Upper block is MSB
				eof_val_g			:	natural := 200;		-- (C8h) EOF block value. Upper block is MSB
				
				width_g				:	positive := 8;		--Data Width (UART = 8 bits)
		signed_checksum_g	:	boolean	:= false;	--TRUE to signed checksum, FALSE to unsigned checksum
		checksum_init_val_g	:	integer	:= 0;		--Note that the initial value is given as an natural number, and not STD_LOGIC_VECTOR
		
		checksum_out_width_g:	natural := 8;		--Output CheckSum width
   reset_polarity_g		:	std_logic	:= '0';									--RESET is active low
		data_width_g			:	positive	:= 8;									--Data width
		blen_width_g			:	positive	:= 9;									--Burst length width (maximum 2^9=512Kbyte Burst)
	       addr_bits_g : POSITIVE := 10;
       width_in_g : POSITIVE := 8;
		addr_width_g			:	positive	:= 10;									--Address width
		bits_of_slaves_g		:	positive	:= 1;									--Number of slaves bits (determines SPI_SS bus width)
		reg_addr_width_g		:	positive	:= 8;									--SPI Registers address width
		reg_din_width_g			:	positive	:= 8									--SPI Registers data width 
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
       wbs_adr_i : in STD_LOGIC_VECTOR(addr_width_g-1 downto 0);
       wbs_dat_i : in STD_LOGIC_VECTOR(data_width_g-1 downto 0);
       wbs_tga_i : in STD_LOGIC_VECTOR(blen_width_g-1 downto 0);
       spi_clk : out STD_LOGIC;
       spi_mosi : out STD_LOGIC;
       wbs_ack_o : out STD_LOGIC;
       wbs_err_o : out STD_LOGIC;
       wbs_stall_o : out STD_LOGIC;
       spi_ss : out STD_LOGIC_VECTOR(bits_of_slaves_g-1 downto 0);
       wbs_dat_o : out STD_LOGIC_VECTOR(data_width_g-1 downto 0)
  );
end Master_Host;

architecture Master_Host of Master_Host is

---- Component declarations -----

component checksum_calc
  generic(
       checksum_init_val_g : INTEGER := 0;
       checksum_out_width_g : NATURAL := 8;
       data_width_g : NATURAL := 8;
       reset_polarity_g : STD_LOGIC := '0';
       signed_checksum_g : BOOLEAN := false
  );
  port (
       clock : in STD_LOGIC;
       data : in STD_LOGIC_VECTOR(data_width_g-1 downto 0);
       data_valid : in STD_LOGIC;
       req_checksum : in STD_LOGIC;
       reset : in STD_LOGIC;
       reset_checksum : in STD_LOGIC;
       checksum_out : out STD_LOGIC_VECTOR(checksum_out_width_g-1 downto 0);
       checksum_valid : out STD_LOGIC
  );
end component;
component general_fifo
  generic(
       almost_empty_g : POSITIVE := 1;
       almost_full_g : POSITIVE := 8;
       depth_g : POSITIVE := 9;
       log_depth_g : NATURAL := 4;
       reset_polarity_g : STD_LOGIC := '0';
       width_g : POSITIVE := 8
  );
  port (
       clk : in STD_LOGIC;
       din : in STD_LOGIC_VECTOR(width_g-1 downto 0);
       flush : in STD_LOGIC;
       rd_en : in STD_LOGIC;
       rst : in STD_LOGIC;
       wr_en : in STD_LOGIC;
       aempty : out STD_LOGIC;
       afull : out STD_LOGIC;
       dout : out STD_LOGIC_VECTOR(width_g-1 downto 0);
       dout_valid : out STD_LOGIC;
       empty : out STD_LOGIC;
       full : out STD_LOGIC;
       used : out STD_LOGIC_VECTOR(log_depth_g downto 0)
  );
end component;
component mp_dec
  generic(
       addr_d_g : POSITIVE := 3;
       crc_d_g : POSITIVE := 1;
       eof_d_g : POSITIVE := 1;
       eof_val_g : NATURAL := 200;
       len_d_g : POSITIVE := 2;
       len_dec1_g : BOOLEAN := true;
       reset_polarity_g : STD_LOGIC := '0';
       sof_d_g : POSITIVE := 1;
       sof_val_g : NATURAL := 100;
       type_d_g : POSITIVE := 1;
       width_g : POSITIVE := 8
  );
  port (
       clk : in STD_LOGIC;
       crc_in : in STD_LOGIC_VECTOR(width_g*crc_d_g-1 downto 0);
       crc_in_val : in STD_LOGIC;
       din : in STD_LOGIC_VECTOR(width_g-1 downto 0);
       rst : in STD_LOGIC;
       valid : in STD_LOGIC;
       addr_reg : out STD_LOGIC_VECTOR(width_g*addr_d_g-1 downto 0);
       crc_err : out STD_LOGIC;
       data_crc : out STD_LOGIC_VECTOR(width_g-1 downto 0);
       data_crc_val : out STD_LOGIC;
       dout : out STD_LOGIC_VECTOR(width_g-1 downto 0);
       eof_err : out STD_LOGIC;
       len_reg : out STD_LOGIC_VECTOR(width_g*len_d_g-1 downto 0);
       mp_done : out STD_LOGIC;
       req_crc : out STD_LOGIC;
       reset_crc : out STD_LOGIC;
       type_reg : out STD_LOGIC_VECTOR(width_g*type_d_g-1 downto 0);
       write_addr : out STD_LOGIC_VECTOR(width_g*len_d_g-1 downto 0);
       write_en : out STD_LOGIC
  );
end component;
component mp_enc
  generic(
       addr_d_g : POSITIVE := 3;
       crc_d_g : POSITIVE := 1;
       eof_d_g : POSITIVE := 1;
       eof_val_g : NATURAL := 200;
       len_d_g : POSITIVE := 2;
       len_dec1_g : BOOLEAN := true;
       reset_polarity_g : STD_LOGIC := '0';
       sof_d_g : POSITIVE := 1;
       sof_val_g : NATURAL := 100;
       type_d_g : POSITIVE := 1;
       width_g : POSITIVE := 8
  );
  port (
       addr_reg : in STD_LOGIC_VECTOR(width_g*addr_d_g-1 downto 0);
       clk : in STD_LOGIC;
       crc_in : in STD_LOGIC_VECTOR(width_g*crc_d_g-1 downto 0);
       crc_in_val : in STD_LOGIC;
       din : in STD_LOGIC_VECTOR(width_g-1 downto 0);
       din_valid : in STD_LOGIC;
       fifo_full : in STD_LOGIC;
       len_reg : in STD_LOGIC_VECTOR(width_g*len_d_g-1 downto 0);
       reg_ready : in STD_LOGIC;
       rst : in STD_LOGIC;
       type_reg : in STD_LOGIC_VECTOR(width_g*type_d_g-1 downto 0);
       data_crc : out STD_LOGIC_VECTOR(width_g-1 downto 0);
       data_crc_val : out STD_LOGIC;
       dout : out STD_LOGIC_VECTOR(width_g-1 downto 0);
       dout_valid : out STD_LOGIC;
       mp_done : out STD_LOGIC;
       read_addr : out STD_LOGIC_VECTOR(width_g*len_d_g-1 downto 0);
       read_addr_en : out STD_LOGIC;
       req_crc : out STD_LOGIC;
       reset_crc : out STD_LOGIC
  );
end component;
component ram_simple
  generic(
       addr_bits_g : POSITIVE := 10;
       reset_polarity_g : STD_LOGIC := '0';
       width_in_g : POSITIVE := 8
  );
  port (
       addr_in : in STD_LOGIC_VECTOR(addr_bits_g-1 downto 0);
       addr_out : in STD_LOGIC_VECTOR(addr_bits_g-1 downto 0);
       aout_valid : in STD_LOGIC;
       clk : in STD_LOGIC;
       data_in : in STD_LOGIC_VECTOR(width_in_g-1 downto 0);
       din_valid : in STD_LOGIC;
       rst : in STD_LOGIC;
       data_out : out STD_LOGIC_VECTOR(width_in_g-1 downto 0);
       dout_valid : out STD_LOGIC
  );
end component;
component spi_master
  generic(
       bits_of_slaves_g : POSITIVE := 1;
       data_width_g : POSITIVE range 2 to positive'high := 8;
       dval_clk_reg_g : POSITIVE range 2 to positive'high := 2;
       dval_conf_reg_g : NATURAL := 0;
       first_dat_lsb : BOOLEAN := true;
       reg_addr_width_g : POSITIVE := 8;
       reg_din_width_g : POSITIVE := 8;
       reg_width_g : POSITIVE := 8;
       reset_polarity_g : STD_LOGIC := '0';
       ss_polarity_g : STD_LOGIC := '0'
  );
  port (
       clk : in STD_LOGIC;
       fifo_din : in STD_LOGIC_VECTOR(data_width_g-1 downto 0);
       fifo_din_valid : in STD_LOGIC;
       fifo_empty : in STD_LOGIC;
       reg_addr : in STD_LOGIC_VECTOR(reg_addr_width_g-1 downto 0);
       reg_din : in STD_LOGIC_VECTOR(reg_din_width_g-1 downto 0);
       reg_din_val : in STD_LOGIC;
       rst : in STD_LOGIC;
       spi_miso : in STD_LOGIC;
       spi_slave_addr : in STD_LOGIC_VECTOR(integer(ceil(log(real(bits_of_slaves_g)/log(2.0)))) downto 0);
       busy : out STD_LOGIC;
       dout : out STD_LOGIC_VECTOR(data_width_g-1 downto 0);
       dout_valid : out STD_LOGIC;
       fifo_req_data : out STD_LOGIC;
       reg_ack : out STD_LOGIC;
       reg_err : out STD_LOGIC;
       spi_clk : out STD_LOGIC;
       spi_mosi : out STD_LOGIC;
       spi_ss : out STD_LOGIC_VECTOR(bits_of_slaves_g-1 downto 0)
  );
end component;
component wbs_spi
  generic(
       addr_width_g : POSITIVE := 10;
       bits_of_slaves_g : POSITIVE := 1;
       blen_width_g : POSITIVE := 9;
       data_width_g : POSITIVE := 8;
       reg_addr_width_g : POSITIVE := 8;
       reg_din_width_g : POSITIVE := 8;
       reset_polarity_g : STD_LOGIC := '0'
  );
  port (
       clk_i : in STD_LOGIC;
       mp_dec_addr_reg : in STD_LOGIC_VECTOR(addr_width_g-1 downto 0);
       mp_dec_crc_err : in STD_LOGIC;
       mp_dec_done : in STD_LOGIC;
       mp_dec_eof_err : in STD_LOGIC;
       mp_dec_len_reg : in STD_LOGIC_VECTOR(blen_width_g-1 downto 0);
       mp_dec_type_reg : in STD_LOGIC_VECTOR(data_width_g-1 downto 0);
       mp_enc_done : in STD_LOGIC;
       ram_dec_dout : in STD_LOGIC_VECTOR(data_width_g-1 downto 0);
       ram_dec_dout_val : in STD_LOGIC;
       rst : in STD_LOGIC;
       spi_reg_ack : in STD_LOGIC;
       spi_reg_err : in STD_LOGIC;
       wbs_adr_i : in STD_LOGIC_VECTOR(addr_width_g-1 downto 0);
       wbs_cyc_i : in STD_LOGIC;
       wbs_dat_i : in STD_LOGIC_VECTOR(data_width_g-1 downto 0);
       wbs_stb_i : in STD_LOGIC;
       wbs_tga_i : in STD_LOGIC_VECTOR(blen_width_g-1 downto 0);
       wbs_tgc_i : in STD_LOGIC;
       wbs_tgd_i : in STD_LOGIC;
       wbs_we_i : in STD_LOGIC;
       mp_enc_addr_reg : out STD_LOGIC_VECTOR(addr_width_g-1 downto 0);
       mp_enc_len_reg : out STD_LOGIC_VECTOR(blen_width_g-1 downto 0);
       mp_enc_reg_ready : out STD_LOGIC;
       mp_enc_type_reg : out STD_LOGIC_VECTOR(data_width_g-1 downto 0);
       ram_dec_addr : out STD_LOGIC_VECTOR(blen_width_g-1 downto 0);
       ram_dec_aout_val : out STD_LOGIC;
       ram_enc_addr : out STD_LOGIC_VECTOR(blen_width_g-1 downto 0);
       ram_enc_din : out STD_LOGIC_VECTOR(data_width_g-1 downto 0);
       ram_enc_din_val : out STD_LOGIC;
       spi_reg_addr : out STD_LOGIC_VECTOR(reg_addr_width_g-1 downto 0);
       spi_reg_din : out STD_LOGIC_VECTOR(reg_din_width_g-1 downto 0);
       spi_reg_din_val : out STD_LOGIC;
       spi_we : out STD_LOGIC;
       wbs_ack_o : out STD_LOGIC;
       wbs_dat_o : out STD_LOGIC_VECTOR(data_width_g-1 downto 0);
       wbs_err_o : out STD_LOGIC;
       wbs_stall_o : out STD_LOGIC
  );
end component;

----     Constants     -----
constant VCC_CONSTANT   : STD_LOGIC := '1';
constant GND_CONSTANT   : STD_LOGIC := '0';

---- Signal declarations used on the diagram ----

signal dec_checksum_valid : STD_LOGIC;
signal dec_crc_data_valid : STD_LOGIC;
signal dec_req_checksum : STD_LOGIC;
signal dec_reset_checksum : STD_LOGIC;
signal enc_crc_in_val : STD_LOGIC;
signal enc_data_crc_val : STD_LOGIC;
signal enc_din_valid : STD_LOGIC;
signal enc_dout_valid : STD_LOGIC;
signal enc_read_addr_en : STD_LOGIC;
signal enc_req_crc : STD_LOGIC;
signal enc_reset_crc : STD_LOGIC;
signal fifo_dout_val : STD_LOGIC;
signal fifo_empty : STD_LOGIC;
signal fifo_full : STD_LOGIC;
signal fifo_req_data : STD_LOGIC;
signal GND : STD_LOGIC;
signal mp_dec_crc_err : STD_LOGIC;
signal mp_dec_done : STD_LOGIC;
signal mp_dec_eof_err : STD_LOGIC;
signal mp_enc_done : STD_LOGIC;
signal mp_enc_reg_ready : STD_LOGIC;
signal NET4081 : STD_LOGIC;
signal ram_dec_aout_val : STD_LOGIC;
signal ram_dec_din_valid : STD_LOGIC;
signal ram_dec_dout_val : STD_LOGIC;
signal ram_enc_din_val : STD_LOGIC;
signal spi_dout_valid : STD_LOGIC;
signal spi_reg_ack : STD_LOGIC;
signal spi_reg_din_val : STD_LOGIC;
signal spi_reg_err : STD_LOGIC;
signal spi_we : STD_LOGIC;
signal VCC : STD_LOGIC;
signal dec_checksum_out : STD_LOGIC_VECTOR (checksum_out_width_g-1 downto 0);
signal dec_crc_data : STD_LOGIC_VECTOR (data_width_g-1 downto 0);
signal enc_crc_in : STD_LOGIC_VECTOR (width_g*crc_d_g-1 downto 0);
signal enc_data_crc : STD_LOGIC_VECTOR (width_g-1 downto 0);
signal enc_din : STD_LOGIC_VECTOR (width_g-1 downto 0);
signal enc_dout : STD_LOGIC_VECTOR (width_g-1 downto 0);
signal enc_read_addr : STD_LOGIC_VECTOR (width_g*len_d_g-1 downto 0);
signal fifo_din : STD_LOGIC_VECTOR (7 downto 0);
signal fifo_dout : STD_LOGIC_VECTOR (7 downto 0);
signal mp_dec_addr_reg : STD_LOGIC_VECTOR (addr_width_g-1 downto 0);
signal mp_dec_len_reg : STD_LOGIC_VECTOR (blen_width_g-1 downto 0);
signal mp_dec_type_reg : STD_LOGIC_VECTOR (data_width_g-1 downto 0);
signal mp_enc_addr_reg : STD_LOGIC_VECTOR (addr_width_g-1 downto 0);
signal mp_enc_len_reg : STD_LOGIC_VECTOR (blen_width_g-1 downto 0);
signal ram_dec_addr : STD_LOGIC_VECTOR (blen_width_g-1 downto 0);
signal ram_dec_addr_in : STD_LOGIC_VECTOR (addr_bits_g-1 downto 0);
signal ram_dec_data_in : STD_LOGIC_VECTOR (width_in_g-1 downto 0);
signal ram_dec_dout : STD_LOGIC_VECTOR (data_width_g-1 downto 0);
signal ram_enc_addr : STD_LOGIC_VECTOR (blen_width_g-1 downto 0);
signal ram_enc_din : STD_LOGIC_VECTOR (data_width_g-1 downto 0);
signal spi_dout : STD_LOGIC_VECTOR (data_width_g-1 downto 0);
signal spi_reg_addr : STD_LOGIC_VECTOR (reg_addr_width_g-1 downto 0);
signal spi_reg_din : STD_LOGIC_VECTOR (reg_din_width_g-1 downto 0);
signal spi_slave_addr : STD_LOGIC_VECTOR (0 downto 0);
signal type_reg : STD_LOGIC_VECTOR (width_g*type_d_g-1 downto 0);

begin

---- User Signal Assignments ----
fifo_din <= fifo_dout when (spi_we = '1')
			else (others => '0');

spi_slave_addr <= (others => '0');
----  Component instantiations  ----

U1 : wbs_spi
  port map(
       clk_i => clk_i,
       mp_dec_addr_reg => mp_dec_addr_reg( addr_width_g-1 downto 0 ),
       mp_dec_crc_err => mp_dec_crc_err,
       mp_dec_done => mp_dec_done,
       mp_dec_eof_err => mp_dec_eof_err,
       mp_dec_len_reg => mp_dec_len_reg( blen_width_g-1 downto 0 ),
       mp_dec_type_reg => mp_dec_type_reg( data_width_g-1 downto 0 ),
       mp_enc_addr_reg => mp_enc_addr_reg( addr_width_g-1 downto 0 ),
       mp_enc_done => mp_enc_done,
       mp_enc_len_reg => mp_enc_len_reg( blen_width_g-1 downto 0 ),
       mp_enc_reg_ready => mp_enc_reg_ready,
       mp_enc_type_reg => type_reg( width_g*type_d_g-1 downto 0 ),
       ram_dec_addr => ram_dec_addr( blen_width_g-1 downto 0 ),
       ram_dec_aout_val => ram_dec_aout_val,
       ram_dec_dout => ram_dec_dout( data_width_g-1 downto 0 ),
       ram_dec_dout_val => ram_dec_dout_val,
       ram_enc_addr => ram_enc_addr( blen_width_g-1 downto 0 ),
       ram_enc_din => ram_enc_din( data_width_g-1 downto 0 ),
       ram_enc_din_val => ram_enc_din_val,
       rst => rst,
       spi_reg_ack => spi_reg_ack,
       spi_reg_addr => spi_reg_addr( reg_addr_width_g-1 downto 0 ),
       spi_reg_din => spi_reg_din( reg_din_width_g-1 downto 0 ),
       spi_reg_din_val => spi_reg_din_val,
       spi_reg_err => spi_reg_err,
       spi_we => spi_we,
       wbs_ack_o => wbs_ack_o,
       wbs_adr_i => wbs_adr_i( addr_width_g-1 downto 0 ),
       wbs_cyc_i => wbs_cyc_i,
       wbs_dat_i => wbs_dat_i( data_width_g-1 downto 0 ),
       wbs_dat_o => wbs_dat_o( data_width_g-1 downto 0 ),
       wbs_err_o => wbs_err_o,
       wbs_stall_o => wbs_stall_o,
       wbs_stb_i => wbs_stb_i,
       wbs_tga_i => wbs_tga_i( blen_width_g-1 downto 0 ),
       wbs_tgc_i => wbs_tgc_i,
       wbs_tgd_i => wbs_tgd_i,
       wbs_we_i => wbs_we_i
  );

NET4081 <= (VCC and not spi_we) or (fifo_dout_val and spi_we);

U2 : mp_dec
  port map(
       addr_reg => mp_dec_addr_reg( addr_width_g-1 downto 0 ),
       clk => clk_i,
       crc_err => mp_dec_crc_err,
       crc_in => dec_checksum_out( checksum_out_width_g-1 downto 0 ),
       crc_in_val => dec_checksum_valid,
       data_crc => dec_crc_data( data_width_g-1 downto 0 ),
       data_crc_val => dec_crc_data_valid,
       din => spi_dout( data_width_g-1 downto 0 ),
       dout => ram_dec_data_in( width_in_g-1 downto 0 ),
       eof_err => mp_dec_eof_err,
       len_reg => mp_dec_len_reg( blen_width_g-1 downto 0 ),
       mp_done => mp_dec_done,
       req_crc => dec_req_checksum,
       reset_crc => dec_reset_checksum,
       rst => rst,
       type_reg => mp_dec_type_reg( data_width_g-1 downto 0 ),
       valid => spi_dout_valid,
       write_addr => ram_dec_addr_in( addr_bits_g-1 downto 0 ),
       write_en => ram_dec_din_valid
  );

U3 : mp_enc
  port map(
       addr_reg => mp_enc_addr_reg( addr_width_g-1 downto 0 ),
       clk => clk_i,
       crc_in => enc_crc_in( width_g*crc_d_g-1 downto 0 ),
       crc_in_val => enc_crc_in_val,
       data_crc => enc_data_crc( width_g-1 downto 0 ),
       data_crc_val => enc_data_crc_val,
       din => enc_din( width_g-1 downto 0 ),
       din_valid => enc_din_valid,
       dout => enc_dout( width_g-1 downto 0 ),
       dout_valid => enc_dout_valid,
       fifo_full => fifo_full,
       len_reg => mp_enc_len_reg( blen_width_g-1 downto 0 ),
       mp_done => mp_enc_done,
       read_addr => enc_read_addr( width_g*len_d_g-1 downto 0 ),
       read_addr_en => enc_read_addr_en,
       reg_ready => mp_enc_reg_ready,
       req_crc => enc_req_crc,
       reset_crc => enc_reset_crc,
       rst => rst,
       type_reg => type_reg( width_g*type_d_g-1 downto 0 )
  );

U9 : spi_master
  port map(
       clk => clk_i,
       dout => spi_dout( 7 downto 0 ),
       dout_valid => spi_dout_valid,
       fifo_din => fifo_din( 7 downto 0 ),
       fifo_din_valid => NET4081,
       fifo_empty => fifo_empty,
       fifo_req_data => fifo_req_data,
       reg_ack => spi_reg_ack,
       reg_addr => spi_reg_addr( reg_addr_width_g-1 downto 0 ),
       reg_din => spi_reg_din( reg_din_width_g-1 downto 0 ),
       reg_din_val => spi_reg_din_val,
       reg_err => spi_reg_err,
       rst => rst,
       spi_clk => spi_clk,
       spi_miso => spi_miso,
       spi_mosi => spi_mosi,
       spi_slave_addr => spi_slave_addr,
       spi_ss => spi_ss( bits_of_slaves_g-1 downto 0 )
  );

dec_checksum : checksum_calc
  port map(
       checksum_out => dec_checksum_out( checksum_out_width_g-1 downto 0 ),
       checksum_valid => dec_checksum_valid,
       clock => clk_i,
       data => dec_crc_data( data_width_g-1 downto 0 ),
       data_valid => dec_crc_data_valid,
       req_checksum => dec_req_checksum,
       reset => rst,
       reset_checksum => dec_reset_checksum
  );

enc_checksum : checksum_calc
  port map(
       checksum_out => enc_crc_in( width_g*crc_d_g-1 downto 0 ),
       checksum_valid => enc_crc_in_val,
       clock => clk_i,
       data => enc_data_crc( width_g-1 downto 0 ),
       data_valid => enc_data_crc_val,
       req_checksum => enc_req_crc,
       reset => rst,
       reset_checksum => enc_reset_crc
  );

ram_dec : ram_simple
  port map(
       addr_in => ram_dec_addr_in(addr_bits_g-1 downto 0 ),
       addr_out => ram_dec_addr( blen_width_g-1 downto 0 ),
       aout_valid => ram_dec_aout_val,
       clk => clk_i,
       data_in => ram_dec_data_in(width_in_g-1 downto 0 ),
       data_out => ram_dec_dout( data_width_g-1 downto 0 ),
       din_valid => ram_dec_din_valid,
       dout_valid => ram_dec_dout_val,
       rst => rst
  );

ram_enc : ram_simple
  port map(
       addr_in => ram_enc_addr( blen_width_g-1 downto 0 ),
       addr_out => enc_read_addr( width_g*len_d_g-1 downto 0 ),
       aout_valid => enc_read_addr_en,
       clk => clk_i,
       data_in => ram_enc_din( data_width_g-1 downto 0 ),
       data_out => enc_din( width_g-1 downto 0 ),
       din_valid => ram_enc_din_val,
       dout_valid => enc_din_valid,
       rst => rst
  );

spi_fifo : general_fifo
  port map(
       clk => clk_i,
       din => enc_dout( width_g-1 downto 0 ),
       dout => fifo_dout( 7 downto 0 ),
       dout_valid => fifo_dout_val,
       empty => fifo_empty,
       flush => GND,
       full => fifo_full,
       rd_en => fifo_req_data,
       rst => rst,
       wr_en => enc_dout_valid
  );


---- Power , ground assignment ----

VCC <= VCC_CONSTANT;
GND <= GND_CONSTANT;

end Master_Host;
