------------------------------------------------------------------------------------------------
-- Model Name 	:	Ram Controller TB 2
-- File Name	:	ram_controller_tb_2.vhd
-- Generated	:	14.10.2011
-- Author		:	Beeri Schreiber Omer Shaked
-- Project		:	SPI Project
------------------------------------------------------------------------------------------------
-- Description: RAM controller basic test bench.
--				
--				(1) TB case : External RAM WRITE
--
--				(2) Internal and External RAM's are real ram_simple design modules.
--
------------------------------------------------------------------------------------------------
-- Revision :
--			Number		Date		Name				Description
--			1.00		14.10.2011	Omer Shaked			Creation
------------------------------------------------------------------------------------------------
--	Todo:
--			(1)
------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity ram_controller_tb is
   generic (
				reset_polarity_g			:	std_logic := '0'; 	--'0' = Active Low, '1' = Active High
				data_width_g				:	positive := 8;		--RAM Data Width (UART = 8 bits)
				ext_addr_width_g			:	positive := 10;		--Addres Width of External RAM (RAM size = 2**(addr_width_g))
				int_addr_width_g			:	positive := 8;		--Addres Width of Internal RAM (RAM size = 2**(addr_width_g))
				reg_width_g					:	positive := 8;		--Registers data width
				max_burst_g					:	positive := 255;	--Maximum data burst (MUST be smaller than 2**(data_width_g))
				max_ext_addr_g				:	positive := 1023	--Maximum External RAM address (value = 2**(ext_addr_width_g))
           );
end entity ram_controller_tb;

architecture sim of ram_controller_tb is

-------------------------------------------------
---------------  SIGNALS  -----------------------
-------------------------------------------------

-------------------- Externals ----------------------
	signal clk			:	std_logic := '0'; 	--Clock
	signal rst			:	std_logic;	--Reset
	signal dout			:	std_logic_vector (data_width_g - 1 downto 0);	--Data that was read from external RAM
	signal dout_valid	:	std_logic;										--Dout data is valid
	signal finish		:	std_logic;										--Finish FLAG - end of external RAM read/write 
	signal overflow_int :	std_logic;										--Interrupt FLAG for External RAM address OVERFLOW
	signal mp_done		:	std_logic;	--Message Pack Decoder has finished to unpack, and registers values are valid 
	signal type_reg		:	std_logic_vector (reg_width_g - 1 downto 0); -- Action Type : Read, Write or Config
	signal addr_reg		:	std_logic_vector (ext_addr_width_g - 1 downto 0); -- Base address for external RAM access
	signal len_reg		:	std_logic_vector (reg_width_g - 1 downto 0); -- Number of entries saved at the internal RAM

--------------------- WIRES -------------------------
				--Internal RAM interface
	signal addr			:	std_logic_vector (int_addr_width_g - 1 downto 0); --Address for internal RAM read
	signal addr_valid	:	std_logic;										  --Output address is valid
	signal data_in		:	std_logic_vector (data_width_g - 1 downto 0);	  --Data received from internal RAM
	signal din_valid	:	std_logic; 							     		  --Input data valid
				--External RAM Interface
	signal wr_addr		:	std_logic_vector (ext_addr_width_g - 1 downto 0); --Address for External RAM write
	signal rd_addr		:	std_logic_vector (ext_addr_width_g - 1 downto 0); --Address for External RAM read
	signal wr_data		:	std_logic_vector (data_width_g - 1 downto 0);	  --Data for external RAM write
	signal wr_valid		:	std_logic;										  --Write data and address are valid
	signal rd_valid		:	std_logic;										  --Read address is valid
	signal ram_data		:	std_logic_vector (data_width_g - 1 downto 0);	  --Input data from External RAM
	signal ram_valid	:	std_logic;
   
----------------- RAM INTIALIZATION -----------------
	signal int_wr_addr	: 	std_logic_vector (int_addr_width_g - 1 downto 0);
	signal int_wr_data	:	std_logic_vector (data_width_g - 1 downto 0);
	signal int_wr_valid :	std_logic;
	
  
  
	component ram_controller
		generic (
				reset_polarity_g			:	std_logic := '0'; 	--'0' = Active Low, '1' = Active High
				data_width_g				:	positive := 8;		--RAM Data Width (UART = 8 bits)
				ext_addr_width_g			:	positive := 10;		--Addres Width of External RAM (RAM size = 2**(addr_width_g))
				int_addr_width_g			:	positive := 8;		--Addres Width of Internal RAM (RAM size = 2**(addr_width_g))
				reg_width_g					:	positive := 8;		--Registers data width
				max_burst_g					:	positive := 255;	--Maximum data burst (MUST be smaller than 2**(data_width_g))
				max_ext_addr_g				:	positive := 1023	--Maximum External RAM address (value = 2**(ext_addr_width_g))
           );
		port
			(
				--Inputs
				clk			:	in std_logic; 	--Clock
				rst			:	in std_logic;	--Reset
				
				--Outputs
				dout		:	out std_logic_vector (data_width_g - 1 downto 0);	--Data that was read from external RAM
				dout_valid	:	out std_logic;										--Dout data is valid
				finish		:	out std_logic;										--Finish FLAG - end of external RAM read/write 
				overflow_int:	out std_logic;										--Interrupt FLAG for External RAM address OVERFLOW
				
				--Message Pack Interface
				mp_done		:	in std_logic;	--Message Pack Decoder has finished to unpack, and registers values are valid 
				
				--Registers Interface
				type_reg	:	in std_logic_vector (reg_width_g - 1 downto 0); -- Action Type : Read, Write or Config
				addr_reg	:	in std_logic_vector (reg_width_g - 1 downto 0); -- Base address for external RAM access
				len_reg		:	in std_logic_vector (reg_width_g - 1 downto 0); -- Number of entries saved at the internal RAM

				--Internal RAM Interface - READ only
				addr		:	out std_logic_vector (int_addr_width_g - 1 downto 0); --Address for internal RAM read
				addr_valid	:	out std_logic;										  --Output address is valid
				data_in		:	in std_logic_vector (data_width_g - 1 downto 0);	  --Data received from internal RAM
				din_valid	:	in std_logic; 							     		  --Input data valid
				
				--External RAM Interface - READ and WRITE
				wr_addr		:	out std_logic_vector (ext_addr_width_g - 1 downto 0); --Address for External RAM write
				rd_addr		:	out std_logic_vector (ext_addr_width_g - 1 downto 0); --Address for External RAM read
				wr_data		:	out std_logic_vector (data_width_g - 1 downto 0);	  --Data for external RAM write
				wr_valid	:	out std_logic;										  --Write data and address are valid
				rd_valid	:	out std_logic;										  --Read address is valid
				ram_data	:	in std_logic_vector (data_width_g - 1 downto 0);	  --Input data from External RAM
				ram_valid	:	in std_logic 									      --Data from external RAM is valid
			);
	end component ram_controller;
	
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
	
begin

	ram_controller_inst	:	ram_controller generic map
										(
										reset_polarity_g	=>	reset_polarity_g,
										data_width_g		=>	data_width_g,
										ext_addr_width_g	=>	ext_addr_width_g,
										int_addr_width_g	=>	int_addr_width_g,
										reg_width_g			=>	reg_width_g,
										max_burst_g			=>	max_burst_g,
										max_ext_addr_g		=>	max_ext_addr_g
										)
										port map
										(
										clk					=>	clk,	
										rst					=>	rst,
										dout				=>	dout,
										dout_valid			=>	dout_valid,
										finish				=>	finish,
										overflow_int		=>	overflow_int,
										mp_done				=>	mp_done,
										type_reg			=>	type_reg,
										addr_reg			=>	addr_reg,
										len_reg				=>	len_reg,
										addr				=>	addr,
										addr_valid			=>	addr_valid,
										data_in				=>	data_in,
										din_valid			=>	din_valid,
										wr_addr				=>	wr_addr,
										rd_addr				=>	rd_addr,
										wr_data				=>	wr_data,
										wr_valid			=>	wr_valid,
										rd_valid			=>	rd_valid,
										ram_data			=>	ram_data,
										ram_valid			=>	ram_valid
										);
										
	ext_ram_inst	:	ram_simple generic map
									(
									reset_polarity_g		=>	reset_polarity_g,
									width_in_g				=>	data_width_g,
									addr_bits_g				=>	ext_addr_width_g
									)
									port map
									(
									clk						=>	clk,
									rst						=>	rst,
									addr_in					=>	wr_addr,
									addr_out				=>	rd_addr,
									aout_valid				=>	rd_valid,
									data_in					=>	wr_data,
									din_valid				=>	wr_valid,
									data_out				=>	ram_data,
									dout_valid				=>	ram_valid
									);
			
	int_ram_inst	:	ram_simple generic map		
									(
									reset_polarity_g		=>	reset_polarity_g,
									width_in_g				=>	data_width_g,
									addr_bits_g				=>	int_addr_width_g
									)
									port map
									(
									clk						=>	clk,
									rst						=>	rst,
									addr_in					=>	int_wr_addr,
									addr_out				=>	addr,
									aout_valid				=>	addr_valid,
									data_in					=>	int_wr_data,
									din_valid				=>	int_wr_valid,
									data_out				=>	data_in,
									dout_valid				=>	din_valid
									);
			
	clk_proc:
	clk	<=	not clk after 50 ns;
	
	rst_proc:
	rst	<=	reset_polarity_g, not reset_polarity_g after 50 ns;
	
	int_ram_init_proc: process
	begin
		int_wr_valid	<=	'0';
		wait for 100 ns;
		int_wr_data	<=	"00000100";
		int_wr_addr	<=	"00000000";
		int_wr_valid	<=	'1';
		wait for 100 ns;
		int_wr_data	<=	"00001000";
		int_wr_addr	<=	"00000001";
		int_wr_valid	<=	'1';
		wait for 100 ns;
		int_wr_data	<=	"00010000";
		int_wr_addr	<=	"00000010";
		int_wr_valid	<=	'1';
		wait for 100 ns;
		int_wr_data	<=	"00100000";
		int_wr_addr	<=	"00000011";
		int_wr_valid	<=	'1';
		wait for 100 ns;
		int_wr_data	<=	"01000000";
		int_wr_addr	<=	"00000100";
		int_wr_valid	<=	'1';
		wait for 100 ns;
		int_wr_valid	<=	'0';
		wait;
	end process int_ram_init_proc;
	
	data_write_proc: process
	begin
		mp_done	<=	'0';
		type_reg	<=	(others	=>	'0');
		len_reg		<=	(others	=>	'0');
		addr_reg	<=	(others	=>	'0');
		wait for 700 ns;
		mp_done	<=	'1';
		type_reg	<=	"00000010";	-- WRITE
		len_reg		<=	"00000101";	-- burst size	=	5
		addr_reg	<=	"0100000000";	-- Base address = 256
		wait for 100 ns;
		mp_done	<=	'0';
		wait;
	end process data_write_proc;
	
end architecture sim;