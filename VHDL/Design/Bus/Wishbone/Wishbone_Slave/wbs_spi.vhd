------------------------------------------------------------------------------------------------
-- Entity Name 	:	Wishbone Slave Interface of the SPI Master
-- File Name	:	wbs_spi.vhd
-- Generated	:	10.09.2011
-- Author		:	Beeri Schreiber and Omer Shaked
-- Project		:	SPI Project
------------------------------------------------------------------------------------------------
-- Description: This is the Wishbone Slave Interface to the SPI, through MessagePacks.
--				TX Data: Data is transmitted to MessagePack Encoder, and then to SPI.
--				RX Data: Data is transmitted to MessagePack Encoder, with information
--							about required data, and then received through Decoder.
--
--				Type Commands, in the Message Pack:
--					(*) x"01"	:	Write
--					(*) x"02"	:	Read
--
--				Tag Cycle (WBS_TGC)
--					(*) '1'		:	Write to SPI Master Registers
--					(*) '0'		:	Transmit / Receive using SPI

--				Tag Data (WBS_TGD)
--					(*) '1'		:	Write to SPI Slave Registers
--					(*) '0'		:	Transmit / Receive using SPI
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
		wbs_tga_i				:	in std_logic_vector (blen_width_g - 1 downto 0);	--Burst Length - 1
		wbs_dat_i				:	in std_logic_vector (data_width_g - 1 downto 0);	--Input Data
		wbs_tgc_i				:	in std_logic;										--'1' - Write to SPI Master Registers ; '0' - Transmit / recieve using SPI
		wbs_tgd_i				:	in std_logic;										--'0' - Write / Read data to / from SPI Slave ; '1' - Write / Read registers to / from SPI Slave
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
		spi_we					:	out std_logic;											--Write Enable. In case of '0' (Reading) - SPI will be commanded to transfer garbage data, in order to receive valid data
		spi_reg_addr			:	out std_logic_vector (reg_addr_width_g - 1 downto 0);	--Address to registers
		spi_reg_din				:	out std_logic_vector (reg_din_width_g - 1 downto 0);	--Data to registers
		spi_reg_din_val			:	out std_logic;											--Data to registers is valid
		spi_reg_ack				:	in	std_logic;											--SPI Registers - data acknowledged
		spi_reg_err				:	in	std_logic											--SPI Registers - error while writing data to SPI
	);
end entity wbs_spi;

architecture rtl of wbs_spi is

----------------------------------	Constants	-------------------------------
constant type_wr_c		:	std_logic_vector (data_width_g - 1 downto 0) := x"01";	--Write
constant type_rd_c		:	std_logic_vector (data_width_g - 1 downto 0) := x"02";	--Read

----------------------------------	Types	-----------------------------------
type fsm_states is
					(	idle_st,		--Idle
						reg_wr_st,		--Writing to SPI Registers
						reg_done_st,	--Expected : spi_reg_ack or spi_reg_err
						rx_prep_ram_st,	--Prepare RX: Write to RAM the required burst length
						rx_cmd_st,		--Transmit Read command
						rx_wait_data_st,--Wait until data from SPI is ready for reading (in RAM)
						neg_stall_st,	--Negate STALL
						tx_data_st,		--Transfer data from WBS I/F to M.P. Encoder
						rx_data_st,		--Receive data from WBS I/F from M.P. Decoder
						end_tx_st,		--End of transmission
						end_rx_st		--End of receive
					);

----------------------------------	Signals	-----------------------------------
signal cur_st			:	fsm_states;										--FSM
signal int_we			:	std_logic;										--Internal Write Enable
signal tx_cnt			:	std_logic_vector (blen_width_g downto 0);		--TX Counter. Extra 1 bit, for comparing MSB to '1' (Reverse counting)
signal rx_cnt			:	std_logic_vector (blen_width_g downto 0);		--RX Counter. Extra 1 bit, for comparing MSB to '1' (Reverse counting)
signal rx_blen			:	std_logic_vector (blen_width_g - 1 downto 0);	--RX Burst Length, writing to RAM
signal blen_sr_b		:	boolean;										--TRUE - All length has been transmissted to RAM (rx_blen = 0), FALSE otherwise
signal int_cyc			:	std_logic;										--Internal WBS_CYC, for validating end of cycle
signal int_cyc_d1		:	std_logic;										--Internal WBS_CYC (with one clock delay), for validating end of cycle
signal int_ram_enc_addr	:	std_logic_vector (blen_width_g - 1 downto 0);	--Internal ram_enc_addr
signal int_ram_dec_addr	:	std_logic_vector (blen_width_g - 1 downto 0);	--Internal ram_dec_addr

----------------------------------	Implementation	---------------------------
begin

--SPI Write Enable
spi_we_proc:
spi_we	<=	int_we;

--RAM Encoder Address
ram_enc_addr_int_proc:
ram_enc_addr	<=	int_ram_enc_addr;

--RAM Decoder Address
ram_dec_addr_int_proc:
ram_dec_addr	<=	int_ram_dec_addr;

--WBS_DAT_O (Output Data)
wbs_dat_o_proc:
wbs_dat_o	<=	ram_dec_dout;

--INT_CYC_d1_Process:
--int_cyc will assert at idle_st, at start of cycle, and negate when cycle is done,
--until next idle_st + wbs_cyc_i
int_cyc_d1_proc: process (clk_i, rst)
begin
	if (rst = reset_polarity_g) then
		int_cyc_d1	<=	'0';
	elsif rising_edge (clk_i) then
		if (cur_st = idle_st) and (wbs_cyc_i = '1') then	--Start of cycle
			int_cyc_d1	<=	'1';
		elsif (wbs_cyc_i = '0') then
			int_cyc_d1	<=	'0';
		else
			int_cyc_d1	<=	int_cyc_d1;
		end if;
	end if;
end process int_cyc_d1_proc;

--INT_CYC_Proc
int_cyc_proc:
int_cyc	<=	int_cyc_d1 and wbs_cyc_i;

--WBS_STALL_O
wbs_stall_o_proc: process (clk_i, rst)
begin
	if (rst = reset_polarity_g) then
		wbs_stall_o	<=	'1';
	elsif rising_edge (clk_i) then
		if (cur_st = end_tx_st) or (cur_st = end_rx_st) or (cur_st = reg_done_st) then --idle_st is not required, since it will already be there at '1'
			wbs_stall_o	<=	'1';
		elsif (cur_st = neg_stall_st) then
			wbs_stall_o	<=	'0';
		end if;
	end if;
end process wbs_stall_o_proc;

--WBS_ACK_O
wbs_ack_o_proc: process (clk_i, rst)
begin
	if (rst = reset_polarity_g) then
		wbs_ack_o	<=	'0';
	elsif rising_edge (clk_i) then
		if (cur_st = rx_data_st) then
			wbs_ack_o	<=	'1';
		elsif (cur_st = tx_data_st) then
			if (ram_dec_dout_val = '1') then
				wbs_ack_o	<=	'1';
			else
				wbs_ack_o	<=	'0';
			end if;
		else
			wbs_ack_o	<=	'0';
		end if;
	end if;
end process wbs_ack_o_proc;

--SPI Register process
width_assert_addr:
assert (reg_addr_width_g <= addr_width_g)
	report "'reg_addr_width_g' must be less or equal to 'addr_width_g'" severity failure;

width_assert_din:
assert (reg_din_width_g <= data_width_g)
	report "'reg_din_width_g' must be less or equal to 'data_width_g'" severity failure;

	spi_reg_proc: process (clk_i, rst)
begin
	if (rst = reset_polarity_g) then
		spi_reg_addr		<=	(others => '0');
		spi_reg_din			<=	(others => '0');
		spi_reg_din_val		<=	'0';
	
	elsif rising_edge (clk_i) then
		if (cur_st = reg_wr_st) then	--Write to registers
			spi_reg_addr (reg_addr_width_g - 1 downto 0)	<=	wbs_adr_i (reg_addr_width_g - 1 downto 0);
			spi_reg_din (reg_din_width_g - 1 downto 0)		<=	wbs_dat_i (reg_din_width_g - 1 downto 0);
			spi_reg_din_val		<=	'1';
		
		else
			spi_reg_addr		<=	(others => '0');
			spi_reg_din			<=	(others => '0');
			spi_reg_din_val		<=	'0';
		end if;
	end if;
end process spi_reg_proc;

--RAM for Encoder Signals' Process
ram_enc_proc: process (clk_i, rst)
variable ram_val_v	:	std_logic_vector (data_width_g - 1 downto 0);
begin
	if (rst = reset_polarity_g) then
		int_ram_enc_addr	<=	(others => '1');	--i.e: x"FF" + '1' = x"00", which is first address
		ram_enc_din			<=	(others => '0');
		ram_val_v			:=	(others => '0');
		ram_enc_din_val		<=	'0';
	
	elsif rising_edge (clk_i) then
		if (cur_st = rx_prep_ram_st) then	--Prepare Read
			int_ram_enc_addr	<=	int_ram_enc_addr + '1';
			ram_val_v			:=	(others => '0');
			if (data_width_g > blen_width_g) then
				ram_val_v (blen_width_g - 1 downto 0) := rx_blen (blen_width_g - 1 downto 0);
			else
				ram_val_v (data_width_g - 1 downto 0) := rx_blen (data_width_g - 1 downto 0);
			end if;
			ram_enc_din			<=	ram_val_v;
			ram_enc_din_val		<=	'1';
		elsif (cur_st = tx_data_st) then		--TX
			int_ram_enc_addr	<=	int_ram_enc_addr + '1';
			ram_enc_din			<=	wbs_dat_i;
			ram_enc_din_val		<=	'1';
		else
			int_ram_enc_addr	<=	(others => '0');
			ram_enc_din			<=	(others => '0');
			ram_enc_din_val		<=	'0';
		end if;
	end if;
end process ram_enc_proc;

--Decoder RAM Process (Address)
ram_dec_adr_proc: process (clk_i, rst)
begin
	if (rst = reset_polarity_g) then
		ram_dec_aout_val	<=	'0';
		int_ram_dec_addr	<=	(others => '1');	--i.e: x"FF" since x"FF" + '1' is first address
	
	elsif rising_edge(clk_i) then
		if (cur_st = rx_data_st) then
			ram_dec_aout_val	<=	'1';
			int_ram_dec_addr	<=	int_ram_dec_addr + '1';
		else
			ram_dec_aout_val	<=	'0';
			int_ram_dec_addr	<=	(others => '1');	--i.e: x"FF" since x"FF" + '1' is first address
		end if;
	end if;
end process ram_dec_adr_proc;

--Main FSM Process
fsm_proc: process (clk_i, rst)
begin
	if (rst = reset_polarity_g) then
		cur_st	<=	idle_st;
	
	elsif rising_edge(clk_i) then
		case cur_st is
			when idle_st	=>
				if (wbs_cyc_i = '1') then				--Start of Wishbone Cycle
					if (wbs_tgc_i = '0') then			--SPI transmission
						if (wbs_we_i = '1') then
							cur_st	<=	neg_stall_st;	--Negate STALL
						else
							cur_st	<=	rx_prep_ram_st;	--Prepare RAM for burst length
						end if;
					else								--Registers Transmission
						if (wbs_we_i = '1') then
							cur_st	<=	neg_stall_st;
						else
							cur_st	<=	cur_st;
							report "Time: " & time'image (now) & ", WBS_SPI >> idle_st: Read from registers is not supported."
							severity error;
						end if;
					end if;
				else
					cur_st	<=	cur_st;
				end if;
				
			when reg_wr_st =>
				cur_st	<=	reg_done_st;
				
			when reg_done_st =>
				if (spi_reg_err = '1') then
					report "Time: " & time'image (now) & ", WBS_SPI >> reg_done_st: Error while writing to SPI registers."
					severity error;
				end if;
				if (int_cyc = '0') then	--WBS_CYC was negated
					cur_st	<=	idle_st;
				else
					cur_st	<=	end_rx_st;	--Go to end_rx_st, for wait until end of WBS_CYC
				end if;
			
			when rx_prep_ram_st	=>
				if blen_sr_b then
					cur_st	<=	rx_cmd_st;
				else
					cur_st	<=	cur_st;
				end if;
				
			when rx_cmd_st	=>
				cur_st	<=	rx_wait_data_st;
				
			when rx_wait_data_st =>
				if (mp_dec_done = '1') then
					if (mp_dec_crc_err = '0') then	--No CRC Error
						cur_st	<=	neg_stall_st;
					else		--CRC Error
						cur_st	<=	end_rx_st;
						report "Time: " & time'image (now) & ", WBS_SPI >> tx_wait_data_st: CRC Error has been detected during reading. Terminating transaction."
						severity error;
					end if;
				elsif (mp_dec_eof_err = '1') then
					cur_st		<=	end_rx_st;
					report "Time: " & time'image (now) & ", WBS_SPI >> tx_wait_data_st: EOF has not been detected during reading. Terminating transaction."
					severity error;
				else
					cur_st		<=	cur_st;
				end if;
			
			when neg_stall_st	=>
				if (wbs_tgc_i = '1') then		--Write to SPI Registers
					cur_st	<=	reg_wr_st;
				elsif (int_we = '1') then			--Writing
					cur_st	<=	tx_data_st;
				else							--Reading
					cur_st	<=	rx_data_st;
				end if;
				
			when tx_data_st	=>
				if (tx_cnt (blen_width_g) = '1') then	--End of burst
					cur_st	<=	end_tx_st;
				elsif (wbs_cyc_i = '0') then			--Cycle has been ended before all data has been transmitted
					cur_st	<=	end_tx_st;
					report "Time: " & time'image (now) & ", WBS_SPI >> tx_data_st: Cycle has been closed before all data has been transmitted"
					severity error;
				else
					cur_st	<=	cur_st;
				end if;

			when rx_data_st	=>
				if (rx_cnt (blen_width_g) = '1') then	--End of burst
					cur_st	<=	end_rx_st;
				elsif (ram_dec_dout_val = '0') then
					cur_st	<=	end_rx_st;
					report "Time: " & time'image (now) & ", WBS_SPI >> rx_data_st: Data Valid from Decoder RAM has not been received"
					severity error;
				elsif (wbs_cyc_i = '0') then	--Cycle has been ended before all data has been received
					cur_st	<=	end_rx_st;
					report "Time: " & time'image (now) & ", WBS_SPI >> rx_data_st: Cycle has been closed before all data has been recieved"
					severity error;
				else
					cur_st	<=	cur_st;
				end if;
				
			when end_tx_st	=>
				if (int_cyc = '0') and (mp_enc_done = '1') then	--WBS_CYC was negated ; All data has been transmitted to SPI
					cur_st	<=	idle_st;
				else
					cur_st	<=	cur_st;
				end if;
			
			when end_rx_st	=>
				if (int_cyc = '0') then	--WBS_CYC was negated
					cur_st	<=	idle_st;
				else
					cur_st	<=	cur_st;
				end if;

			when others =>	--ERROR: This should not happen
				cur_st	<=	idle_st;
				report "Time: " & time'image (now) & ", WBS_SPI >> Current FSM State is not implemented!!!"
				severity error;
				
			end case;
	end if;
end process fsm_proc;

--Encoder Registers Process
enc_regs_proc: process (clk_i, rst)
begin
	if (rst = reset_polarity_g) then
		mp_enc_reg_ready	<=	'0';
		mp_enc_type_reg		<=	(others => '0');
		mp_enc_addr_reg		<=	(others => '0');
		mp_enc_len_reg		<=	(others => '0');
		
	elsif rising_edge(clk_i) then
		if (cur_st = idle_st) then
			mp_enc_reg_ready	<=	'0';
		    mp_enc_addr_reg		<=	wbs_adr_i;
		    mp_enc_len_reg		<=	wbs_tga_i;
		    mp_enc_type_reg		<=	(others => '0');
		elsif (cur_st = rx_cmd_st) then
			mp_enc_reg_ready	<=	'1';
		    mp_enc_type_reg		<=	type_rd_c;
		    mp_enc_type_reg(4)	<=	wbs_tgd_i; --wbs_tgd: write/read to / from SPI Registers / data
		
		elsif (cur_st = tx_data_st) and (tx_cnt (blen_width_g) = '1') then	--End of TX Burst
			mp_enc_reg_ready	<=	'1';
		    mp_enc_type_reg		<=	type_wr_c;
		    mp_enc_type_reg(4)	<=	wbs_tgd_i; --wbs_tgd: write/read to / from SPI Registers / data
		
		else
			mp_enc_reg_ready	<=	'0';
		end if;
	end if;
end process enc_regs_proc;

--WBS_ERR_O
wbs_err_o_proc: process (clk_i, rst)
begin
	if (rst = reset_polarity_g) then
		wbs_err_o	<=	'0';
	elsif rising_edge(clk_i) then
		if (cur_st = tx_data_st) and (ram_dec_dout_val = '0') then
			wbs_err_o	<=	'1';
		elsif (cur_st = rx_wait_data_st) then
			if (mp_dec_crc_err = '1') or (mp_dec_eof_err = '1') then
				wbs_err_o		<=	'1';
			elsif (mp_dec_done = '1') then
				if (mp_dec_type_reg /= type_rd_c)
				or (mp_dec_addr_reg /= wbs_adr_i)
				or (mp_dec_len_reg 	/= wbs_tga_i) then
					wbs_err_o	<=	'1';
				else
					wbs_err_o	<=	'0';
				end if;
			else
				wbs_err_o		<=	'0';
			end if;
		elsif (cur_st = reg_done_st)	--Wait for ACK / ERR from SPI Registers
			and ((spi_reg_ack = '0') or (spi_reg_err = '1')) then
			wbs_err_o	<=	'1';
		else
			wbs_err_o			<=	'0';
		end if;
	end if;
end process wbs_err_o_proc;

--Internal Write Enable Process
int_we_proc: process (clk_i, rst)
begin
	if (rst = reset_polarity_g) then
		int_we	<=	'1';
	elsif rising_edge(clk_i) then
		if (cur_st = idle_st) and (wbs_cyc_i = '1') then
			int_we	<=	wbs_we_i;
		elsif (cur_st = end_rx_st) then
			int_we	<=	'1';
		else
			int_we	<=	int_we;
		end if;
	end if;
end process int_we_proc;

--TX Counter Process
tx_cnt_proc: process (clk_i, rst)
begin
	if (rst = reset_polarity_g) then
		tx_cnt	<=	(others => '0');
	
	elsif rising_edge(clk_i) then
		if (cur_st = idle_st) and (wbs_we_i = '1') then	--Start of cycle
			tx_cnt	<=	'0' & wbs_tga_i;
		elsif (cur_st = tx_data_st) and (wbs_stb_i = '1') then	
			tx_cnt	<=	tx_cnt - '1';
		else
			tx_cnt	<=	tx_cnt;
		end if;
	end if;
end process tx_cnt_proc;

--RX Counter Process
rx_cnt_proc: process (clk_i, rst)
begin
	if (rst = reset_polarity_g) then
		rx_cnt	<=	(others => '0');
	
	elsif rising_edge(clk_i) then
		if (cur_st = idle_st) and (wbs_we_i = '0') then	--Start of cycle
			rx_cnt	<=	'0' & wbs_tga_i;
		elsif (cur_st = rx_data_st) and (wbs_stb_i = '1') then	
			rx_cnt	<=	rx_cnt - '1';
		else
			rx_cnt	<=	rx_cnt;
		end if;
	end if;
end process rx_cnt_proc;

--Rx Burst Length to RAM, to prepare Read
rx_blen_proc: process (clk_i, rst)
variable blen_val_v		:	std_logic_vector (blen_width_g - 1 downto 0);
begin
	if (rst = reset_polarity_g) then
		rx_blen		<=	(others => '0');
		blen_val_v	:= 	(others => '0');
	
	elsif rising_edge(clk_i) then
		if (cur_st = idle_st) and (wbs_cyc_i = '1') then
			rx_blen	<=	wbs_tga_i;
		elsif (cur_st = rx_prep_ram_st) then
			blen_val_v	:= rx_blen;
			for idx in 1 to data_width_g loop	--Shift Right, data_width bits
				blen_val_v (blen_width_g - 2 downto 0)	:=	blen_val_v (blen_width_g - 1 downto 1);
			end loop;
			rx_blen	<=	blen_val_v;
		else
			rx_blen	<=	rx_blen;
		end if;
	end if;
end process rx_blen_proc;

--End of transmission to RAM, for read prepate (in case blen_width_g>=data_width)
blen_sr_b_gen1:
if (blen_width_g >= data_width_g) generate
	blen_sr_b_proc: process (clk_i, rst)
	constant zero_c : std_logic_vector (blen_width_g - 1 downto data_width_g) := (others => '0'); 
	begin
		if (rst = reset_polarity_g) then
			blen_sr_b	<=	false;
		
		elsif rising_edge(clk_i) then
			blen_sr_b	<=	(rx_blen (blen_width_g - 1 downto data_width_g) = zero_c (blen_width_g - 1 downto data_width_g));	
		end if;
	end process blen_sr_b_proc;
end generate blen_sr_b_gen1;

--End of transmission to RAM, for read prepate (in case blen_width_g<data_width)
blen_sr_b_gen2:
if (blen_width_g < data_width_g) generate
	blen_sr_b_proc:
	blen_sr_b	<=	true;
end generate blen_sr_b_gen2;

end architecture rtl;