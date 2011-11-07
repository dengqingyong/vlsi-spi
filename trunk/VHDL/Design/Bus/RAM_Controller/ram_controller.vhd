------------------------------------------------------------------------------------------------
-- Model Name 	:	Ram Controller
-- File Name	:	ram_controller.vhd
-- Generated	:	11.10.2011
-- Author		:	Beeri Schreiber Omer Shaked
-- Project		:	SPI Project
------------------------------------------------------------------------------------------------
-- Description: RAM Controller implements the interface between the slave host and the DATA RAM.
--
--				(1) RAM READ
--					--------
--					The controller receives the base address and the number of data words that
--					are required, and returns the data received from the External RAM.
--
--				(2) RAM WRITE
--					---------
--					The controller receives the base address and the burst size,
--					reads the data from the internal RAM and writes it to the External RAM.
--				
--				(3) Finish - The signal turns ACTIVE when the read/write transaction has finished.
--
--				(4) Overflow Interrupt - When base_address + burst_size are greater than External RAM size,
--					the overflow interrupt signal turns ACTIVE and transaction is ended.
--
--
------------------------------------------------------------------------------------------------
-- Revision :
--			Number		Date		Name				Description
--			1.00		11.10.2011	Omer Shaked			Creation
------------------------------------------------------------------------------------------------
--	Todo:
--			(1)
------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity ram_controller is
   generic (
				reset_polarity_g			:	std_logic := '0'; 	--'0' = Active Low, '1' = Active High
				data_width_g				:	positive := 8;		--RAM Data Width (UART = 8 bits)
				ext_addr_width_g			:	positive := 10;		--Addres Width of External RAM (RAM size = 2**(addr_width_g))
				int_addr_width_g			:	positive := 8;		--Addres Width of Internal RAM (RAM size = 2**(addr_width_g))
				save_bit_mode_g				:	integer	:= 1;		--1 - Increase burst_size by 1, 0 - don't increase burst size
				reg_width_g					:	positive := 8;		--Registers data width
				type_width_g				:	positive := 8;		--Width of type register
				len_width_g					:	positive := 8;		--Width of len register
				max_burst_g					:	positive := 256;	--Maximum data burst (MUST be smaller than 2**(data_width_g))
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
				dout_addr	:	out	std_logic_vector (int_addr_width_g - 1 downto 0); --Dout data address for ENC_RAM
				finish		:	out std_logic;										--Finish FLAG - end of external RAM read/write 
				overflow_int:	out std_logic;										--Interrupt FLAG for External RAM address OVERFLOW
				
				--Message Pack Interface
				mp_done		:	in std_logic;	--Message Pack Decoder has finished to unpack, and registers values are valid 
				
				--Registers Interface
				type_reg	:	in std_logic_vector (type_width_g - 1 downto 0); -- Action Type : Read, Write or Config
				addr_reg	:	in std_logic_vector (ext_addr_width_g - 1 downto 0); -- Base address for external RAM access
				len_reg		:	in std_logic_vector (len_width_g - 1 downto 0); -- Number of entries saved at the internal RAM

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
end entity ram_controller;

architecture rtl_ram_controller of ram_controller is

	------------------	Types	--------------------

	type controller_states is (
							idle_st,		--Idle states
							burst_calc_st,  --Calculate the data burst value
							read_st,		--Read data from RAM
							write_st		--Write data to RAM
							);


	------------------  CONSTANTS ------------------
	constant read_type	:	std_logic_vector (type_width_g - 1 downto 0)	:= x"02";	--Read
	constant write_type	:	std_logic_vector (type_width_g - 1 downto 0)	:= x"01";	--Write


	------------------  SIGNALS  -------------------
	signal base_addr	:	integer range 0 to max_ext_addr_g;					--Base address for external RAM access
	signal ifinish		:	std_logic;											--Internal finish signal
	signal cur_st		:	controller_states;									--FSM state
	signal burst_size	:	integer range 0 to max_burst_g;						--Data burst size
	signal count_ext	:	integer range 0 to 2*max_burst_g;						--Counts the number of read/write cycles in order to access the 
																				--correct Ext RAM address
	signal count_int	:	integer range 0 to 2*max_burst_g;						--Counts the number of read cycles in order to access the 
																				--correct Int RAM address
	signal count_val	:	integer range 0 to 2*max_burst_g;						--Counts valid data words read from the Ext RAM
	signal burst_valid	:	std_logic;											--Indicates burst_size value is updated
	signal ilen_reg		:	std_logic_vector (len_width_g - 1 downto 0); 		-- Number of entries saved at the internal RAM
	signal itype_reg	:	std_logic_vector (type_width_g - 1 downto 0); 		-- Action Type : Read, Write or Config


begin

	-----------------    Hidden Processes -------------------

	finish_proc:
	finish	<=	ifinish;

	--------------------------------------------------------
	----------------  Process fsm_proc ---------------------
	--------------------------------------------------------
	-- This process is the state machine of the controller.
	--------------------------------------------------------
	
	fsm_proc: process (clk, rst)
	begin
		if (rst = reset_polarity_g) then --Reset
			cur_st 		<= idle_st;
			overflow_int	<=	'0';
			
		elsif rising_edge(clk) then
			--default value
			overflow_int	<=	'0';
			
			case cur_st is
				when idle_st	=>
					if (mp_done = '1') then
						if (type_reg = read_type) or (type_reg = write_type) then -- READ or WRITE action
							cur_st	<=	burst_calc_st;
						end if;
					end if;
					
				when burst_calc_st	=>
					if (itype_reg = read_type) then
						if (burst_valid = '1') then
							cur_st	<=	read_st;
						end if;
					elsif (itype_reg = write_type) then
						cur_st	<=	write_st;
					else
						cur_st	<=	idle_st;
						report "Time: " & time'image(now) & ", RAM Controller >> Entered burst_calc_st with invalid action"
						& "Aborting Transmission"
						severity error;
					end if;
						
				when read_st	=>
					if (base_addr + count_ext > max_ext_addr_g) then --There is an address overflow when accessing the Ext RAM
						cur_st	<=	idle_st;
						overflow_int	<=	'1';
					elsif (burst_size = count_val) then
						cur_st	<=	idle_st;
					end if;
					
				when write_st	=>
					if (base_addr + count_ext > max_ext_addr_g) then --There is an address overflow when accessing the Ext RAM
						cur_st	<=	idle_st;
						overflow_int	<=	'1';
					elsif (burst_size = count_ext) then
						cur_st	<=	idle_st;
					end if;
					
				when others	=>
					cur_st	<=	idle_st;
					report "Time: " & time'image(now) & ", RAM Controller >> Unknown state in FSM!!!"
					severity error;
					
			end case;
		end if;
	end process fsm_proc;
	
	
	--------------------------------------------------------
	----------------  Process ifinish_proc -----------------
	--------------------------------------------------------
	-- This process handles with the ifinish signal.
	-- ifinish is set ACTIVE when read or write actions 
	-- were finished.
	--------------------------------------------------------
	
	ifinish_proc: process (clk, rst)
	begin
		if (rst = reset_polarity_g) then --Reset
			ifinish	<=	'0';
			
		elsif rising_edge(clk) then
			if (cur_st = read_st) and (burst_size = count_val) then 	--READ cycle has been finished
				ifinish	<=	'1';
			elsif (cur_st = write_st) and (burst_size = count_ext) then --WRITE cycle has been finished
				ifinish <=	'1';
			else
				ifinish	<=	'0';
			end if;
		end if;
	end process ifinish_proc;
	
	
	--------------------------------------------------------
	----------------  Process burst_proc -----------------
	--------------------------------------------------------
	-- This process calculates the burst size - number of 
	-- words that needs to read from external RAM or to be
	-- written to it.
	--------------------------------------------------------
	
	burst_proc: process (clk, rst)
	begin
		if (rst = reset_polarity_g) then --Reset
			burst_size	<=	0;
			burst_valid	<=	'0';
			
		elsif rising_edge(clk) then
			if (cur_st = burst_calc_st) then --Need to calculate new burst value
				if (itype_reg = read_type) then --Internal RAM contains the burst size
					if (din_valid = '1') then -- Data from internal RAM is valid
						burst_size	<=	conv_integer(data_in) + save_bit_mode_g;
						burst_valid	<=	'1';
					else
						burst_valid	<=	'0';
					end if;
				elsif (itype_reg = write_type) then --burst_size = the value of the length register
					burst_size	<=	conv_integer(ilen_reg) + save_bit_mode_g;
					burst_valid	<=	'1';
				else
					burst_valid	<=	'0';
				end if;
			else
				burst_valid	<=	'0';
			end if;
		end if;
	end process burst_proc;
	
	
	--------------------------------------------------------
	----------------  Process int_reg_proc -----------------
	--------------------------------------------------------
	-- This process saves the value of the external registers
	-- into the controller internal registers, when mp_done
	-- is active.
	--------------------------------------------------------
	
	int_reg_proc: process (clk, rst)
	begin
		if (rst = reset_polarity_g) then --Reset
			itype_reg	<=	(others	=>	'0');
			base_addr	<=	0;
			ilen_reg	<=	(others	=>	'0');
		
		elsif rising_edge(clk) then
			if (mp_done = '1') then --Need to store new register values
				itype_reg	<=	type_reg;
				base_addr	<=	conv_integer(addr_reg);
				ilen_reg	<=	len_reg;
			end if;
		end if;
	end process int_reg_proc;
	
	
	--------------------------------------------------------
	----------------  Process int_ram_proc -----------------
	--------------------------------------------------------
	-- This process handles the interface with the internal RAM.
	-- Read action: need to read the burst size.
	-- Write action: need to read all the data from the RAM.
	--------------------------------------------------------
	
	int_ram_proc: process (clk, rst)
	begin
		if (rst = reset_polarity_g) then --Reset
			addr	<=	(others => '0');
			addr_valid	<=	'0';
		
		elsif rising_edge(clk) then
			case cur_st is
			
				when idle_st	=>
					if (mp_done = '1') and (type_reg = read_type) then --New READ transaction, need to read burst size
						addr	<=	(others => '0');
						addr_valid	<=	'1';
					else
						addr_valid	<=	'0';
					end if;
					
				when burst_calc_st	=>
					if (itype_reg = write_type) then -- Need to read first data from internal RAM
						addr		<=	conv_std_logic_vector(count_int, int_addr_width_g);
						addr_valid	<=	'1';
					else
						addr_valid	<=	'0';
					end if;
				
				when write_st	=>	
					if (count_int < burst_size) then
						addr		<=	conv_std_logic_vector(count_int, int_addr_width_g);
						addr_valid	<=	'1';
					else
						addr_valid	<=	'0';
					end if;
					
				when others	=>
					addr_valid	<=	'0';
					
			end case;
		end if;
	end process int_ram_proc;

					
	--------------------------------------------------------
	----------------  Process ext_ram_proc -----------------
	--------------------------------------------------------
	-- This process handles the interface with the external RAM.
	-- Read action: need to read the data from the external RAM,
	-- and transfer it to the slave host mp_encoder.
	-- Write action: need to write all the data read from the 
	-- internal RAM, to the external RAM.
	--------------------------------------------------------
	
	ext_ram_proc: process (clk, rst)
	begin
		if (rst = reset_polarity_g) then --Reset
			wr_addr	<=	(others	=>	'0');
			wr_data	<=	(others	=>	'0');
			wr_valid	<=	'0';
			rd_addr	<=	(others	=>	'0');
			rd_valid	<=	'0';
		elsif rising_edge(clk) then
			case cur_st is
					
				when read_st	=>	-- Need to read data from the external RAM
					wr_valid	<=	'0';
					if (count_ext	<	burst_size) then
						rd_addr		<=	conv_std_logic_vector(base_addr + count_ext, ext_addr_width_g);
						rd_valid	<=	'1';
					else
						rd_valid	<=	'0';
					end if;
				
				when write_st	=>	-- Need to write data to the external RAM
					rd_valid	<=	'0';
					if (din_valid = '1') then
						wr_data	<=	data_in;
						wr_addr	<=	conv_std_logic_vector(base_addr + count_ext, ext_addr_width_g);
						wr_valid	<=	'1';
					else
						wr_valid	<=	'0';
					end if;
					
				when others	=>
					rd_valid	<=	'0';
					wr_valid	<=	'0';
					
			end case;
		end if;
	end process ext_ram_proc;


	--------------------------------------------------------
	----------------  Process dout_proc --------------------
	--------------------------------------------------------
	-- The process handles the delivery of the data that was
	-- read from the external RAM, to the slave host mp_enc.
	--------------------------------------------------------
	
	dout_proc: process (clk, rst)
	begin
		if (rst = reset_polarity_g) then --Reset
			dout		<=	(others => '0');
			dout_valid	<=	'0';
			dout_addr	<=	(others => '0');
		
		elsif rising_edge(clk) then
			if (ram_valid = '1') then --Input data from external RAM is valid, transfer it back to slave host
				dout		<=	ram_data;
				dout_valid	<=	'1';
				dout_addr	<=	conv_std_logic_vector(count_val, int_addr_width_g);
			else
				dout_valid	<=	'0';
			end if;
		end if;
	end process dout_proc;
		
		
	--------------------------------------------------------
	----------------  Process cnt_proc --------------------
	--------------------------------------------------------
	-- The process handles with the controller counters;
	-- count_int: counts accesses to Int RAM
	-- count_ext: counts accesses to Ext RAM
	-- count_val: counts valid data received from Ext RAM
	--------------------------------------------------------
	
	cnt_proc: process (clk, rst)
	begin
		if (rst = reset_polarity_g) then --Reset
			count_int	<=	0;
			count_ext	<=	0;
			count_val	<=	0;
		elsif rising_edge(clk) then
			case cur_st is
			
				when idle_st	=>
					count_int	<=	0;
					count_ext	<=	0;
					count_val	<=	0;
					
				when burst_calc_st	=>
					if (itype_reg = write_type) then
						count_int	<=	count_int + 1;
					end if;
					
				when read_st	=>
					count_ext	<=	count_ext + 1;
					if (ram_valid = '1') then -- Data from External RAM is valid
						count_val	<=	count_val + 1;
					end if;
					
				when write_st	=>
					count_int	<=	count_int + 1;
					if (din_valid = '1') then -- Data from internal RAM is valid
						count_ext	<=	count_ext + 1;
					end if;
		
				when others	=>
					count_int	<=	0;
					count_ext	<=	0;
					count_val	<=	0;
					
			end case;
		end if;
	end process cnt_proc;

end architecture rtl_ram_controller;	
	