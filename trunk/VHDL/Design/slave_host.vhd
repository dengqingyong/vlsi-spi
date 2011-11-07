
------------------------------------------------------------------------------------------------
-- Entity Name 	:	Slave Host
-- File Name	:	slave_host.vhd
-- Generated	:	3.11.2011
-- Author		:	Beeri Schreiber and Omer Shaked
-- Project		:	SPI Project
------------------------------------------------------------------------------------------------
-- Description: This is the TOP entity of the slave host.
--
-- MAX BURST SIZE = 256 Bytes
--
-- Requirements:
--	 	(*)	Reset deactivation MUST be synchronized to the clock's rising edge!
--			Reset activetion may be asynchronized to the clock.
--		(*) FIFO should assert FIFO_DIN_VALID within one clock from FIFO_REQ_DATA. 
------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date		Name					Description			
--			1.00		3.11.2011	Omer Shaked				Creation
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

entity slave_host is
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
end entity slave_host;
		   
architecture rtl_slave_host of slave_host is

	-------------------------------	Components	------------------------------------
	component spi_slave
		generic (
				reset_polarity_g	:	std_logic	:= '0';		--Reset polarity. '0' is active low, '1' is active high
				ss_polarity_g		:	std_logic	:= '0';		--Slave Select polarity. '0' is active low, '1' is active high
				data_width_g		:	positive range 2 to positive'high	:= 8;		--Shift register is 8 bits. Range is from 2 - for the Shift Register
				reg_width_g			:	positive	:= 8;		--Number of bits in SPI configuration Register
				dval_cpha_g			:	std_logic	:= '0';		--Default (initial) value of CPHA
				dval_cpol_g			:	std_logic	:= '0';		--Default (initial) value of CPOL
				first_dat_lsb		:	boolean		:= true;	--TRUE: Transmit and Receive LSB first. FALSE - MSB first
				default_dat_g		:	integer		:= 0;		--Default data transmitted to master when the FIFO is empty
				spi_timeout_g		:	std_logic_vector (10 downto 0)	:=	"00000100000"; -- Number of clk cycles before timeout is declared
				timeout_en_g		:	std_logic	:= '1';		--Timeout enable. '1' - enabled, '0' - disabled
				dval_miso_g			:	std_logic	:= '0'		--Default value of spi_miso internal signal
				);	
		port 	(
				-- Clock and Reset
				clk					:	in 	std_logic;											--System Clock
				rst					:	in 	std_logic;											--Reset. NOTE: Reset deactivation MUST be synchronized to the clock's rising edge
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
				reg_din				:	in 	std_logic_vector (reg_width_g - 1 downto 0);		--Data to registers
				reg_din_val			:	in 	std_logic;											--Data to registers is valid
				reg_ack				:	out std_logic;											--Data to registers has been acknowledged
				-- Output from SPI slave
				busy				:	out std_logic;											--'1' - BUSY: Transaction is active
				interrupt			:	out std_logic;											--'1' - Slave Select turned NOT active in the middle of a transaction
				timeout				:	out std_logic;											--'1' : SPI TIMEOUT - spi_clk stuck for spi_timeout_g clk cycles
				dout				:	out std_logic_vector (data_width_g - 1 downto 0);		--Output data
				dout_valid			:	out std_logic											--Output data is valid
				);
	end component spi_slave;

	component general_fifo 
		generic	(	 
				reset_polarity_g	: 	std_logic	:= '0';	-- Reset Polarity
				width_g				: 	positive	:= 8; 	-- Width of data
				depth_g 			: 	positive	:= 9;	-- Maximum elements in FIFO
				log_depth_g			: 	natural		:= 4;	-- Logarithm of depth_g (Number of bits to represent depth_g. 2^4=16 > 9)
				almost_full_g		: 	positive	:= 8; 	-- Rise almost full flag at this number of elements in FIFO
				almost_empty_g		: 	positive	:= 1 	-- Rise almost empty flag at this number of elements in FIFO
				);
		port	(
				clk 				: 	in 	std_logic;									-- Clock
				rst 				: 	in 	std_logic;                                  -- Reset
				din 				: 	in 	std_logic_vector (width_g-1 downto 0);      -- Input Data
				wr_en 				: 	in 	std_logic;                                  -- Write Enable
				rd_en 				: 	in 	std_logic;                                  -- Read Enable (request for data)
				flush				: 	in	std_logic;									-- Flush data
				dout 				: 	out std_logic_vector (width_g-1 downto 0);	    -- Output Data
				dout_valid			: 	out std_logic;                                  -- Output data is valid
				afull  				: 	out std_logic;                                  -- FIFO is almost full
				full 				: 	out std_logic;	                                -- FIFO is full
				aempty 				: 	out std_logic;                                  -- FIFO is almost empty
				empty 				: 	out std_logic;                                  -- FIFO is empty
				used 				: 	out std_logic_vector (log_depth_g  downto 0) 	-- Current number of elements is FIFO. Note the range. In case depth_g is 2^x, then the extra bit will be used
				);
	end component general_fifo;
	
	component mp_enc
		generic (
				reset_polarity_g	:	std_logic := '0'; 	--'0' = Active Low, '1' = Active High
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
				width_g				:	positive := 8		--Data Width (UART = 8 bits)
				);
		port	(
				--Inputs
				clk					:	in std_logic; 											--Clock
				rst					:	in std_logic; 											--Reset
				fifo_full			:	in std_logic;											--When '0' - Can receive data, When '1' - FIFO Full		
				--Message Pack
				mp_done				:	out std_logic;											--Message Pack has been transmitted
				dout				:	out std_logic_vector (width_g - 1 downto 0); 			--Output data
				dout_valid			:	out std_logic;											--Output data is valid .Goes to 'write_en' of FIFO	
				--Registers
				reg_ready			:	in std_logic; 											--Registers are ready for reading. MP Encoder can start transmitting
				type_reg			:	in std_logic_vector (width_g * type_d_g - 1 downto 0);	--Type register
				addr_reg			:	in std_logic_vector (width_g * addr_d_g - 1 downto 0);	--Address register
				len_reg				:	in std_logic_vector (width_g * len_d_g - 1 downto 0);	--Length Register
				--CRC / CheckSum
				data_crc_val		:	out std_logic; 											--'1' when new data for CRC is valid, '0' otherwise
				data_crc			:	out std_logic_vector (width_g - 1 downto 0); 			--Data to be calculated by CRC
				reset_crc			:	out std_logic; 											--'1' to reset CRC value
				req_crc				:	out std_logic; 											--'1' to request for current caluclated CRC
				crc_in				:	in std_logic_vector (width_g * crc_d_g -1 downto 0); 	--CRC value
				crc_in_val			:	in std_logic;  											--'1' when CRC is valid
				--Data (Payload)
				din					:	in std_logic_vector (width_g - 1 downto 0); 			--Input from RAM
				din_valid			:	in std_logic;											--Data from RAM is valid
				read_addr_en		:	out std_logic;											--Output RAM address is valid
				read_addr			:	out std_logic_vector (width_g * len_d_g - 1 downto 0) 	--RAM Address
				);
	end component mp_enc;
	
	component checksum_calc	
		generic (
				reset_polarity_g	:	std_logic := '0'; 	--'0' = active low
				signed_checksum_g	:	boolean	:= false;	--TRUE to signed checksum, FALSE to unsigned checksum
				checksum_init_val_g	:	integer	:= 0;		--Note that the initial value is given as an natural number, and not STD_LOGIC_VECTOR
				checksum_out_width_g:	natural := 8;		--Output CheckSum width
				data_width_g		:	natural := 8		--Input data width
				);
		port	(           
				clock				:	in  std_logic;												--Clock 
				reset				: 	in  std_logic; 												--Reset
				data				: 	in  std_logic_vector (data_width_g - 1 downto 0); 			--Data to calculate
				data_valid			: 	in  std_logic; 												--Data is Valid
				reset_checksum		: 	in  std_logic;												--Reset the current checksum to the initial value
				req_checksum		: 	in  std_logic;												--Request for valid checksum
				checksum_out		: 	out std_logic_vector (checksum_out_width_g - 1 downto 0); 	--Checksum value
				checksum_valid		: 	out std_logic 												--CheckSum valid
				);	
	end component checksum_calc;
		
	component ram_controller
		generic (
				reset_polarity_g	:	std_logic := '0'; 	--'0' = Active Low, '1' = Active High
				data_width_g		:	positive := 8;		--RAM Data Width (UART = 8 bits)
				ext_addr_width_g	:	positive := 10;		--Addres Width of External RAM (RAM size = 2**(addr_width_g))
				int_addr_width_g	:	positive := 8;		--Addres Width of Internal RAM (RAM size = 2**(addr_width_g))
				save_bit_mode_g		:	integer	:= 1;		--1 - Increase burst_size by 1, 0 - don't increase burst size
				reg_width_g			:	positive := 8;		--Registers data width
				type_width_g		:	positive := 8;		--Width of type register
				len_width_g			:	positive := 8;		--Width of len register
				max_burst_g			:	positive := 256;	--Maximum data burst (MUST be smaller than 2**(data_width_g))
				max_ext_addr_g		:	positive := 1024	--Maximum External RAM address (value = 2**(ext_addr_width_g))
				);
		port	(
				--Inputs
				clk					:	in std_logic; 										--Clock
				rst					:	in std_logic;										--Reset
				--Outputs
				dout				:	out std_logic_vector (data_width_g - 1 downto 0);	--Data that was read from external RAM
				dout_valid			:	out std_logic;										--Dout data is valid
				dout_addr			:	out	std_logic_vector (int_addr_width_g - 1 downto 0); --Dout data address for ENC_RAM
				finish				:	out std_logic;										--Finish FLAG - end of external RAM read/write 
				overflow_int		:	out std_logic;										--Interrupt FLAG for External RAM address OVERFLOW
				--Message Pack Interface
				mp_done				:	in std_logic;	--Message Pack Decoder has finished to unpack, and registers values are valid 
				--Registers Interface
				type_reg			:	in std_logic_vector (type_width_g - 1 downto 0); 	-- Action Type : Read, Write or Config
				addr_reg			:	in std_logic_vector (ext_addr_width_g - 1 downto 0); -- Base address for external RAM access
				len_reg				:	in std_logic_vector (len_width_g - 1 downto 0); 	-- Number of entries saved at the internal RAM
				--Internal RAM Interface - READ only
				addr				:	out std_logic_vector (int_addr_width_g - 1 downto 0); --Address for internal RAM read
				addr_valid			:	out std_logic;										  --Output address is valid
				data_in				:	in std_logic_vector (data_width_g - 1 downto 0);	  --Data received from internal RAM
				din_valid			:	in std_logic; 							     		  --Input data valid
				--External RAM Interface - READ and WRITE
				wr_addr				:	out std_logic_vector (ext_addr_width_g - 1 downto 0); --Address for External RAM write
				rd_addr				:	out std_logic_vector (ext_addr_width_g - 1 downto 0); --Address for External RAM read
				wr_data				:	out std_logic_vector (data_width_g - 1 downto 0);	  --Data for external RAM write
				wr_valid			:	out std_logic;										  --Write data and address are valid
				rd_valid			:	out std_logic;										  --Read address is valid
				ram_data			:	in std_logic_vector (data_width_g - 1 downto 0);	  --Input data from External RAM
				ram_valid			:	in std_logic 									      --Data from external RAM is valid		
				);
	end component ram_controller;	
	
	
	component mp_dec
		generic (
				reset_polarity_g	:	std_logic := '0'; 	--'0' = Active Low, '1' = Active High
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
				width_g				:	positive := 8		--Data Width (UART = 8 bits)
				);
		port	(
				--Inputs
				clk					:	in std_logic; 	--Clock
				rst					:	in std_logic;	--Reset
				din					:	in std_logic_vector (width_g - 1 downto 0); --Input data_d_g
				valid				:	in std_logic;	--Data valid	
				--Message Pack Status
				mp_done				:	out std_logic;	--Message Pack has been recieved
				eof_err				:	out std_logic;	--EOF has not found
				crc_err				:	out std_logic;	--CRC error
				--Registers
				type_reg			:	out std_logic_vector (width_g * type_d_g - 1 downto 0);
				addr_reg			:	out std_logic_vector (width_g * addr_d_g - 1 downto 0);
				len_reg				:	out std_logic_vector (width_g * len_d_g - 1 downto 0);
				--CRC / CheckSum
				data_crc_val		:	out std_logic; --'1' when new data for CRC is valid, '0' otherwise
				data_crc			:	out std_logic_vector (width_g - 1 downto 0); --Data to be calculated by CRC
				reset_crc			:	out std_logic; --'1' to reset CRC value
				req_crc				:	out std_logic; --'1' to request for current caluclated CRC
				crc_in				:	in std_logic_vector (width_g * crc_d_g -1 downto 0); --CRC value
				crc_in_val			:	in std_logic;  --'1' when CRC is valid
				--Data (Payload)
				write_en			:	out std_logic; --'1' = Data is available (width_g length)
				write_addr			:	out std_logic_vector (width_g * len_d_g - 1 downto 0); --RAM Address
				dout				:	out std_logic_vector (width_g - 1 downto 0) --Data to RAM
				);
	end component mp_dec;

	component ram_simple
		generic (
				reset_polarity_g	:	std_logic 	:= '0';	--'0' - Active Low Reset, '1' Active High Reset
				width_in_g			:	positive 	:= 8;	--Width of data
				addr_bits_g			:	positive 	:= 10	--Depth of data	(2^10 = 1024 addresses)
				);
		port	(
				clk					:	in std_logic;									--System clock
				rst					:	in std_logic;									--System Reset
				addr_in				:	in std_logic_vector (addr_bits_g - 1 downto 0); --Input address
				addr_out			:	in std_logic_vector (addr_bits_g - 1 downto 0); --Output address
				aout_valid			:	in std_logic;									--Output address is valid
				data_in				:	in std_logic_vector (width_in_g - 1 downto 0);	--Input data
				din_valid			:	in std_logic; 									--Input data valid
				data_out			:	out std_logic_vector (width_in_g - 1 downto 0);	--Output data
				dout_valid			:	out std_logic 									--Output data valid
				);
	end component ram_simple;
	
	------------------	Types	--------------------

	type fsm_states is (
						idle_st,	--Idle state - no new data_read / conf_write message has been received
						rd_ram_st,	--New data_read / conf_write - read releavant data from DEC_RAM
						read_st,	--Wait for the finish of external RAM read
						conf_st,  	--Perform write transaction to SPI SLAVE configuration registr
						wait_st,	--Read_type - wait for the returning packet to be transmitted
									--Conf_type - wait to receive reg_ack from SPI SLAVE
						drop_st		--Checksum ERROR - DROP the message
						);

	------------------  CONSTANTS ------------------
	constant read_type	:	std_logic_vector (reg_width_g - 1 downto 0)	:= x"02";	--Read from external RAM
	constant conf_type	:	std_logic_vector (reg_width_g - 1 downto 0)	:= x"17";   --Write to configuration register
	constant zero_addr 	:	std_logic_vector (int_addr_width_g - 1 downto 0) := (others => '0');
	
	-------------------------------------------------
	---------------  SIGNALS  -----------------------
	-------------------------------------------------
	
	--------- Internal host signals -----------------
	signal cur_st			:	fsm_states;							--FSM state		

	--------- MUX select signals --------------------
	signal dec_rd_sel		:	std_logic;		-- '0' - ram_controller, '1' - slave_host
		   
	--------- Internal host Registers ---------------
	signal type_reg_d		:	std_logic_vector (data_width_g * type_d_g - 1 downto 0); --Type register output
	signal addr_reg_d		:	std_logic_vector (data_width_g * addr_d_g - 1 downto 0); --Address register output
	signal len_reg_d		:	std_logic_vector (data_width_g * len_d_g - 1 downto 0);	 --Length Register output
	signal type_reg_q		:	std_logic_vector (data_width_g * type_d_g - 1 downto 0); --Type register input
	signal addr_reg_q		:	std_logic_vector (data_width_g * addr_d_g - 1 downto 0); --Address register input
	signal len_reg_q		:	std_logic_vector (data_width_g * len_d_g - 1 downto 0);	 --Length Register input
	---- host_fsm : dec_ram
	signal en_host_read		:	std_logic;											--Read data from dec_ram
	signal burst_reg		:	std_logic_vector (data_width_g - 1 downto 0); 		--READ burst size (received from DEC_RAM)
	signal conf_reg			:	std_logic_vector (data_width_g - 1 downto 0); 		--Configuration data read from DEC_RAM
	
	---------------- WIRES --------------------------
	---- spi_slave : fifo
	signal fifo_req_data 	:	std_logic;											--Request for data from FIFO
	signal fifo_din			:	std_logic_vector (data_width_g - 1 downto 0);		--Data from FIFO
	signal fifo_din_valid	:	std_logic;											--Input data from FIFO
	signal fifo_empty		:	std_logic;											--FIFO is empty
	---- spi_slave : host fsm		
	signal int_reg_din		:	std_logic_vector (reg_width_g - 1 downto 0);		--Data to registers
	signal int_reg_din_val	:	std_logic;											--Data to registers is valid
	signal int_reg_ack		:	std_logic;			
	---- spi_slave : mp_dec
	signal dout				:	std_logic_vector (data_width_g - 1 downto 0);		--Output data
	signal dout_valid		:	std_logic;											--Output data is valid
	
	---- fifo : host_fsm
	signal flush			:	std_logic;											-- Flush FIFO data
	signal afull  			:	std_logic;											-- FIFO is almost full
	signal aempty 			: 	std_logic;              							-- FIFO is almost empty
	signal used 			: 	std_logic_vector (log_depth_g  downto 0); 			-- Current number of elements is FIFO.
	---- fifo : mp_enc
	signal full 			: 	std_logic;	                                		-- FIFO is full
	signal mp_enc_data		:	std_logic_vector (data_width_g - 1 downto 0);		--Output data from mp_enc to FIFO
	signal mp_enc_data_val	:	std_logic;											--Data from mp_enc is valid
	
	---- mp_enc : host_fsm
	signal mp_enc_done		:	std_logic;											--MP_enc has finished transmitting data to the FIFO
	signal reg_ready		:	std_logic;											--Registers are ready for reading by mp_enc
	---- mp_enc : checksum_calc
	signal data_crc			:	std_logic_vector (data_width_g - 1 downto 0); 		--Data from mp_enc to be calculated by CRC
	signal data_crc_val		:	std_logic; 											--'1' when new data for CRC is valid, '0' otherwise
	signal reset_crc		:	std_logic; 											--'1' to reset CRC value
	signal req_crc			:	std_logic; 											--'1' to request for current caluclated CRC
	signal crc_in			:	std_logic_vector (data_width_g * crc_d_g -1 downto 0); 	--CRC value
	signal crc_in_val		:	std_logic;  											--'1' when CRC is valid
	---- mp_enc : enc_ram
	signal enc_ram_dout		:	std_logic_vector (data_width_g - 1 downto 0); 		--Data from ENC_RAM to mp_enc
	signal enc_ram_dout_val	:	std_logic;											--Data from RAM is valid
	signal enc_read_en		:	std_logic;											--Output RAM address from mp_enc is valid
	signal enc_rd_addr		:	std_logic_vector (int_addr_width_g - 1 downto 0); 	--ENC_RAM read Address
	
	---- ram_controller : enc_ram
	signal enc_ram_din		:	std_logic_vector (data_width_g - 1 downto 0);		--Data that was read from external RAM
	signal enc_ram_din_val	:	std_logic;											--Data from ram controller to buffer fifo is valid	
	signal enc_ram_wr_addr	:	std_logic_vector (int_addr_width_g - 1 downto 0); 	--ENC_RAM write Address
	---- ram_controller : host_fsm
	signal finish			:	std_logic;										--Finish FLAG - end of external RAM read/write 
	signal overflow_int		:	std_logic;										--Interrupt FLAG for External RAM address OVERFLOW
	---- ram_controller : dec_ram
	signal ram_rd_addr		:	std_logic_vector (int_addr_width_g - 1 downto 0); 	--Address for Decoder RAM read
	signal ram_addr_valid	:	std_logic;											--enable DEC_RAM read
	signal dec_ram_dout		:	std_logic_vector (data_width_g - 1 downto 0); 		--Data from DEC_RAM to ram_controller
	signal dec_ram_dout_val	:	std_logic;											--Data from RAM is valid

	---- dec_ram
	signal dec_read_en		:	std_logic;											--enable DEC_RAM read
	signal dec_rd_addr		:	std_logic_vector (int_addr_width_g - 1 downto 0); 	--Address for Decoder RAM read
	
	---- mp_dec : host_fsm
	signal mp_dec_done		:	std_logic;										--MP_dec has finished unpacking the incoming message
	signal eof_err			:	std_logic;										--EOF has not been found by mp_dec
	signal crc_err			:	std_logic;										--CRC error found within incoming packet
	---- mp_dec : checksum_calc
	signal dec_data_crc		:	std_logic_vector (data_width_g - 1 downto 0); 		--Data from mp_dec to be calculated by CRC
	signal dec_data_crc_val	:	std_logic; 											--'1' when new data for CRC is valid, '0' otherwise
	signal dec_reset_crc	:	std_logic; 											--'1' to reset CRC value
	signal dec_req_crc		:	std_logic; 											--'1' to request for current caluclated CRC
	signal dec_crc_in		:	std_logic_vector (data_width_g * crc_d_g -1 downto 0); 	--CRC value
	signal dec_crc_in_val	:	std_logic;  											--'1' when CRC is valid
	---- mp_dec : dec_ram
	signal dec_wr_en		:	std_logic; 											--'1' = Data from mp_dec is availble
	signal dec_wr_addr		:	std_logic_vector (int_addr_width_g - 1 downto 0); 	--Address for DEC_RAM write
	signal dec_wr_data		:	std_logic_vector (data_width_g - 1 downto 0); 		--Data to DEC_RAM
	
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
								default_dat_g		=>	default_dat_g,
								spi_timeout_g		=>	spi_timeout_g,
								timeout_en_g		=>	timeout_en_g,
								dval_miso_g			=>	dval_miso_g
								)
								port map
								(
								clk					=>	clk,			--port
								rst					=>	rst,			--port
								spi_clk				=>	spi_clk,		--port
								spi_mosi			=>	spi_mosi,		--port
								spi_miso			=>	spi_miso,		--port
								spi_ss				=>	spi_ss,			--port
								fifo_req_data		=>	fifo_req_data,	--signal
								fifo_din			=>	fifo_din,		--signal
								fifo_din_valid		=>	fifo_din_valid,	--signal
								fifo_empty			=>	fifo_empty,		--signal
								reg_din				=>	int_reg_din,		--signal
								reg_din_val			=>	int_reg_din_val,	--signal
								reg_ack				=>	int_reg_ack,		--signal
								timeout				=>	timeout,		--port
								busy				=>	busy,			--port
								interrupt			=>	interrupt,		--port
								dout				=>	dout,			--signal
								dout_valid			=>	dout_valid		--signal
								);		   
		   
	general_fifo_inst	:	general_fifo	generic map
								(	   
								reset_polarity_g	=>	reset_polarity_g,
								width_g				=> 	data_width_g,	
								depth_g 			=>	depth_g,
								log_depth_g			=>	log_depth_g,
								almost_full_g		=>	almost_full_g,
								almost_empty_g		=> 	almost_empty_g
								)
								port map
								(
								clk					=>	clk,			--port
								rst					=>	rst,			--port
								din 				=>	mp_enc_data,	--signal
								wr_en 				=>	mp_enc_data_val,--signal
								rd_en 				=>	fifo_req_data,	--signal
								flush				=>	flush,			--signal
								dout 				=>	fifo_din,		--signal
								dout_valid			=>	fifo_din_valid,	--signal
								afull  				=>	afull,			--signal
								full 				=>	full,			--signal
								aempty 				=>	aempty,	        --signal
								empty 				=>	fifo_empty,     --signal
								used 				=>	used			--signal
								);
								
	mp_enc_inst	:	mp_enc	generic map
								(
								reset_polarity_g	=>	reset_polarity_g,
								len_dec1_g			=>	len_dec1_g,										
								sof_d_g				=>	sof_d_g,
								type_d_g			=>	type_d_g,
								addr_d_g			=>	addr_d_g,
								len_d_g				=>	len_d_g,
								crc_d_g				=>	crc_d_g,								
								eof_d_g				=>	eof_d_g,
								sof_val_g			=>	sof_val_g,
								eof_val_g			=>	eof_val_g,
								width_g				=>	data_width_g
								)	   
								port map
								(
								clk					=>	clk,	
								rst					=>	rst,
								fifo_full			=>	full,			--signal
								mp_done				=>	mp_enc_done,	--signal
								dout				=>	mp_enc_data,	--signal
								dout_valid			=>	mp_enc_data_val,--signal
								reg_ready			=>	reg_ready,		--signal
								type_reg			=>	type_reg_q,		--signal
								addr_reg			=>	addr_reg_q,		--signal
								len_reg				=>	burst_reg,		--signal
								data_crc_val		=>	data_crc_val,	--signal
								data_crc			=>	data_crc,		--signal
								reset_crc			=>	reset_crc,		--signal
								req_crc				=>	req_crc,		--signal
								crc_in				=>	crc_in,			--signal
								crc_in_val			=>	crc_in_val,		--signal
								din					=>	enc_ram_dout,	--signal
								din_valid			=>	enc_ram_dout_val, --signal	
								read_addr_en		=>	enc_read_en,  	--signal
								read_addr			=>	enc_rd_addr		--signal
								);
	
	enc_checksum_calc	:	checksum_calc generic map
								(
								reset_polarity_g	=>	reset_polarity_g,
								signed_checksum_g	=>	signed_checksum_g,
								checksum_init_val_g	=>	checksum_init_val_g,
								checksum_out_width_g =>	checksum_out_width_g,
								data_width_g		=>	data_width_g
								)
								port map
								(
								clock				=>	clk,
								reset				=>	rst,
								data				=>	data_crc,		--signal
								data_valid			=>	data_crc_val,	--signal
								reset_checksum		=>	reset_crc,		--signal
								req_checksum		=>	req_crc,		--signal
								checksum_out		=>	crc_in,			--signal
								checksum_valid		=>	crc_in_val		--signal
								);	
		   
	ram_controller_inst	:	ram_controller generic map
								(
								reset_polarity_g	=>	reset_polarity_g,
								data_width_g		=>	data_width_g,
								ext_addr_width_g	=>	ext_addr_width_g,
								int_addr_width_g	=>	int_addr_width_g,
								save_bit_mode_g		=>	save_bit_mode_g,
								reg_width_g			=>	reg_width_g,
								type_width_g		=>	type_width_g,
								len_width_g			=>	len_width_g,
								max_burst_g			=>	max_burst_g,
								max_ext_addr_g		=>	max_ext_addr_g
								)
								port map
								(
								clk					=>	clk,	
								rst					=>	rst,
								dout				=>	enc_ram_din,		--signal
								dout_valid			=>	enc_ram_din_val,	--signal
								dout_addr			=>	enc_ram_wr_addr,	--signal
								finish				=>	finish,				--signal
								overflow_int		=>	overflow_int,		--signal
								mp_done				=>	mp_dec_done,		--signal
								type_reg			=>	type_reg_d,			--signal
								addr_reg			=>	addr_reg_d (ext_addr_width_g - 1 downto 0),	--signal
								len_reg				=>	len_reg_d,			--signal
								addr				=>	ram_rd_addr,		--signal
								addr_valid			=>	ram_addr_valid,		--signal
								data_in				=>	dec_ram_dout,		--signal
								din_valid			=>	dec_ram_dout_val,	--signal
								wr_addr				=>	wr_addr,			--port
								rd_addr				=>	rd_addr,			--port
								wr_data				=>	wr_data,			--port
								wr_valid			=>	wr_valid,			--port
								rd_valid			=>	rd_valid,			--port
								ram_data			=>	ram_data,			--port
								ram_valid			=>	ram_valid			--port
								);	   
		   
	mp_dec_inst	:	mp_dec generic map
								(
								reset_polarity_g	=>	reset_polarity_g,
								len_dec1_g			=>	len_dec1_g,										
								sof_d_g				=>	sof_d_g,
								type_d_g			=>	type_d_g,
								addr_d_g			=>	addr_d_g,
								len_d_g				=>	len_d_g,
								crc_d_g				=>	crc_d_g,								
								eof_d_g				=>	eof_d_g,
								sof_val_g			=>	sof_val_g,
								eof_val_g			=>	eof_val_g,
								width_g				=>	data_width_g				
								)
								port map
								(
								clk					=>	clk,
								rst					=>	rst,			
								din					=>	dout,			--signal
								valid				=>	dout_valid,		--signal
								mp_done				=>	mp_dec_done,	--signal
								eof_err				=>	eof_err,		--signal
								crc_err				=>	crc_err,		--signal
								type_reg			=>	type_reg_d,		--signal
								addr_reg			=>	addr_reg_d,		--signal
								len_reg				=>	len_reg_d,		--signal
								data_crc_val		=>	dec_data_crc_val,	--signal
								data_crc			=>	dec_data_crc,		--signal
								reset_crc			=>	dec_reset_crc,		--signal
								req_crc				=>	dec_req_crc,		--signal
								crc_in				=>	dec_crc_in,			--signal
								crc_in_val			=>	dec_crc_in_val,		--signal
								write_en			=>	dec_wr_en,			--signal
								write_addr			=>	dec_wr_addr,		--signal
								dout				=>	dec_wr_data			--signal
								);	   
		   
	dec_checksum_calc	:	checksum_calc generic map
								(
								reset_polarity_g	=>	reset_polarity_g,
								signed_checksum_g	=>	signed_checksum_g,
								checksum_init_val_g	=>	checksum_init_val_g,
								checksum_out_width_g =>	checksum_out_width_g,
								data_width_g		=>	data_width_g
								)
								port map
								(
								clock				=>	clk,
								reset				=>	rst,
								data				=>	dec_data_crc,		--signal
								data_valid			=>	dec_data_crc_val,	--signal
								reset_checksum		=>	dec_reset_crc,		--signal
								req_checksum		=>	dec_req_crc,		--signal
								checksum_out		=>	dec_crc_in,			--signal
								checksum_valid		=>	dec_crc_in_val		--signal
								);		   
		   
	enc_ram_inst	:	ram_simple generic map
								(
								reset_polarity_g		=>	reset_polarity_g,
								width_in_g				=>	data_width_g,
								addr_bits_g				=>	int_addr_width_g
								)
								port map
								(
								clk						=>	clk,
								rst						=>	rst,
								addr_in					=>	enc_ram_wr_addr,	--signal
								addr_out				=>	enc_rd_addr,		--signal
								aout_valid				=>	enc_read_en,		--signal
								data_in					=>	enc_ram_din,		--signal
								din_valid				=>	enc_ram_din_val,	--signal
								data_out				=>	enc_ram_dout,		--signal
								dout_valid				=>	enc_ram_dout_val	--signal
								);	   	
	
	dec_ram_inst	:	ram_simple generic map
								(
								reset_polarity_g		=>	reset_polarity_g,
								width_in_g				=>	data_width_g,
								addr_bits_g				=>	int_addr_width_g
								)
								port map
								(
								clk						=>	clk,
								rst						=>	rst,
								addr_in					=>	dec_wr_addr,		--signal
								addr_out				=>	dec_rd_addr,		--signal
								aout_valid				=>	dec_read_en,		--signal
								data_in					=>	dec_wr_data,		--signal
								din_valid				=>	dec_wr_en,			--signal
								data_out				=>	dec_ram_dout,		--signal
								dout_valid				=>	dec_ram_dout_val	--signal
								);	   
		   
	--------------- Hidden Processes -----------------------
	
	dec_ram_rd_mux_proc:
	dec_read_en	<=	en_host_read when (dec_rd_sel = '1')
					else ram_addr_valid;
					
	dec_rd_addr <=	zero_addr when (dec_rd_sel = '1')
					else ram_rd_addr;
		  
	reg_ack_proc:
	reg_ack		<=	int_reg_ack;
	
	fifo_flush_proc:
	flush		<=	'0';  --Don't flush
	
	--------------------------------------------------------
	---------------  Process mp_reg_proc -------------------
	--------------------------------------------------------
	-- This process handles with the registers in the slave
	-- host that holds the message information.
	--------------------------------------------------------
		   
	mp_reg_proc: process (clk, rst)
	begin
		if (rst = reset_polarity_g) then 	--Reset
			type_reg_q	<=	(others => '0');
			addr_reg_q	<=	(others => '0');
			len_reg_q	<=	(others => '0');
			
		elsif rising_edge(clk) then	   
			if (mp_dec_done = '1') then 	--Save values to registers
				type_reg_q	<=	type_reg_d;
				addr_reg_q	<=	addr_reg_d;
				len_reg_q	<=	len_reg_d;
			end if;
		end if;
	end process mp_reg_proc;
			
	--------------------------------------------------------
	---------------  Process spi_conf_proc -----------------
	--------------------------------------------------------
	-- This process executes spi configuration changes
	-- (new CPOL, CPHA values for spi_slave).
	--------------------------------------------------------		
			
	spi_conf_proc : process (rst, clk)
	begin
		if (rst = reset_polarity_g) then 	--Reset
			int_reg_din		<=	(others => '0');
			int_reg_din_val	<=	'0';
			
		elsif rising_edge(clk) then	   
			if (cur_st = conf_st) then 				-- Write to SPI configuration register
				int_reg_din		<=	conf_reg;
				int_reg_din_val	<=	'1';
			elsif (reg_din_val = '1') then 			-- External write to SPI configuration register
				int_reg_din		<=	reg_din;
				int_reg_din_val	<=	'1';
			else											
				int_reg_din_val	<=	'0';
			end if;
		end if;
	end process spi_conf_proc;
	
	--------------------------------------------------------
	---------------  Process rd_dec_ram_proc ---------------
	--------------------------------------------------------
	-- This process reads and stores values from dec RAM when
	-- needed:
	-- read_type = get burst size from dec_ram
	-- conf_write_type = get new configuration data from dec_ram
	--------------------------------------------------------	
	
	rd_dec_ram_proc : process (rst, clk)
	begin
		if (rst = reset_polarity_g) then 	--Reset
			burst_reg		<=	(others => '0');
			conf_reg		<=	(others => '0');
			
		elsif rising_edge(clk) then	   
			if (cur_st = rd_ram_st) then 	-- Need to read data from ram
				if (type_reg_q = read_type) and (dec_ram_dout_val = '1') then
					burst_reg	<=	dec_ram_dout;
				elsif (type_reg_q = conf_type) and (dec_ram_dout_val = '1') then
					conf_reg	<=	dec_ram_dout;
				end if;
			end if;
		end if;
	end process rd_dec_ram_proc;
	
	--------------------------------------------------------
	------------------  Process fsm_proc -------------------
	--------------------------------------------------------
	-- This is the main FSM for the slave host.
	-- The fsm deals with read & configuration change messages,
	-- and also handles spi_timeout and external RAM overflow.
	--------------------------------------------------------	

	fsm_proc : process (clk, rst)
	begin
		if (rst = reset_polarity_g) then --Reset
			cur_st 		<= idle_st;

		elsif rising_edge(clk) then	  
			-- Default values
			en_host_read	<=	'0';
			dec_rd_sel		<=	'0';
			reg_ready		<=	'0';
			
			case cur_st is	
			
				when idle_st	=>
					if (mp_dec_done = '1') then -- Finished receiving a new message
						if (type_reg_d = read_type) then -- New read request
							cur_st			<=	rd_ram_st;
							
						elsif (type_reg_d = conf_type) then -- New write to cinfiguration register
							dec_rd_sel 		<= 	'1';		-- Slave host reads from DEC_RAM
							en_host_read	<=	'1';		-- Read value from dec_ram
							cur_st			<=	rd_ram_st;
						end if;
					elsif (crc_err = '1') then -- Received message with CRC_ERR - need to DROP the packet
						cur_st		<=	drop_st;
					end if;
				
				when rd_ram_st	=>
					if (type_reg_q = read_type) and (dec_ram_dout_val = '1') then
						cur_st		<=	read_st;
					elsif (type_reg_q = conf_type) and (dec_ram_dout_val = '1') then
						cur_st		<=	conf_st;
					end if;
				
				when read_st	=>
					if (finish = '1') or (overflow_int = '1') then 		-- RAM_Controller finished writing the data to the ENC_RAM
						reg_ready		<=	'1';
						cur_st			<=	wait_st;
					end if;
						
				when conf_st	=>
					cur_st		<=	wait_st;
					
				when wait_st	=>
					if (type_reg_q = read_type) and (mp_enc_done = '1') then --Finished building returning message
						cur_st	<=	idle_st;
					elsif (type_reg_q = conf_type) and (int_reg_ack = '1') then --Finished writing new configuration values
						cur_st	<=	idle_st;
					end if;
					
				when drop_st	=>
					if (mp_dec_done = '1') then
						cur_st	<=	idle_st;
					end if;
					
				when others		=>
					report "Time: " & time'image(now) & ", Slave Host - Unimplemented state is being executed in FSM"
					severity error;
			
			end case;
		end if;
	end process fsm_proc;
		   
end architecture rtl_slave_host;		   