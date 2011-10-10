------------------------------------------------------------------------------------------------
-- Model Name 	:	General FIFO tb
-- File Name	:	general_fifo_tb.vhd
-- Generated	:	10.10.2011
-- Author		:	Beeri Shreiber and Ome Shaked
-- Project		:	SPI Project
------------------------------------------------------------------------------------------------
-- Description: The file is a TB that checks several FIFO cases:
-- 				(1) R & W on the same clk.
--				(2) R & W on the same clk when FIFO is empty
--				(3) R & W on the same clk when FIFO is full.
--				(4) R when fifo is empty.
--				(5) Comparison between read_addr and read_addr_dup.
--
--
------------------------------------------------------------------------------------------------
-- Revision :
--			Number		Date		Name				Description
--			1.00		10.10.2011	Omer Shaked			Creation
--
------------------------------------------------------------------------------------------------
--	Todo:
--	(1)
------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all; 

entity general_fifo_tb is 
	generic(	 
		reset_polarity_g	: std_logic	:= '0';	-- Reset Polarity
		width_g				: positive	:= 8; 	-- Width of data
		depth_g 			: positive	:= 5;	-- Maximum elements in FIFO
		log_depth_g			: natural	:= 3;	-- Logarithm of depth_g (Number of bits to represent depth_g. 2^4=16 > 9)
		almost_full_g		: positive	:= 4; 	-- Rise almost full flag at this number of elements in FIFO
		almost_empty_g		: positive	:= 1 	-- Rise almost empty flag at this number of elements in FIFO
		);
end entity general_fifo_tb;

architecture sim of general_fifo_tb is

--------------------------------- Signals ----------------------------------------------------------------
signal clk 			:  	std_logic:=	'0';												-- Clock
signal rst 			:  	std_logic:= not reset_polarity_g;          						-- Reset
signal din 			:  	std_logic_vector (width_g-1 downto 0):= (others	=>	'0');       -- Input Data
signal wr_en 		:  	std_logic:= '0';                            					-- Write Enable
signal rd_en 		:  	std_logic:= '0';                            					-- Read Enable (request for data)
signal flush		: 	std_logic:= '0';												-- Flush data
signal dout 		:  	std_logic_vector (width_g-1 downto 0);	    					-- Output Data
signal dout_valid	:  	std_logic;                                 						-- Output data is valid
signal afull  		: 	std_logic;                                  					-- FIFO is almost full
signal full 		:  	std_logic;	                                					-- FIFO is full
signal aempty 		: 	std_logic;                                  					-- FIFO is almost empty
signal empty 		:  	std_logic;                                  					-- FIFO is empty
signal used 		:  	std_logic_vector (log_depth_g  downto 0) ;						-- number of used FIFO slots

component general_fifo 
	generic(	 
		reset_polarity_g	: std_logic	:= '0';	-- Reset Polarity
		width_g				: positive	:= 8; 	-- Width of data
		depth_g 			: positive	:= 9;	-- Maximum elements in FIFO
		log_depth_g			: natural	:= 4;	-- Logarithm of depth_g (Number of bits to represent depth_g. 2^4=16 > 9)
		almost_full_g		: positive	:= 8; 	-- Rise almost full flag at this number of elements in FIFO
		almost_empty_g		: positive	:= 1 	-- Rise almost empty flag at this number of elements in FIFO
		);
	 port(
		 clk 		: in 	std_logic;									-- Clock
		 rst 		: in 	std_logic;                                  -- Reset
		 din 		: in 	std_logic_vector (width_g-1 downto 0);      -- Input Data
		 wr_en 		: in 	std_logic;                                  -- Write Enable
		 rd_en 		: in 	std_logic;                                  -- Read Enable (request for data)
		 flush		: in	std_logic;									-- Flush data
		 dout 		: out 	std_logic_vector (width_g-1 downto 0);	    -- Output Data
		 dout_valid	: out 	std_logic;                                  -- Output data is valid
		 afull  	: out 	std_logic;                                  -- FIFO is almost full
		 full 		: out 	std_logic;	                                -- FIFO is full
		 aempty 	: out 	std_logic;                                  -- FIFO is almost empty
		 empty 		: out 	std_logic;                                  -- FIFO is empty
		 used 		: out 	std_logic_vector (log_depth_g  downto 0) 	-- Current number of elements is FIFO. Note the range. In case depth_g is 2^x, then the extra bit will be used
	     );
end component general_fifo;

begin
	general_fifo_inst	:	general_fifo generic map
									(
									reset_polarity_g	=>	reset_polarity_g,
									width_g				=>	width_g,
									depth_g				=>	depth_g,
									log_depth_g			=>	log_depth_g,
									almost_full_g		=>	almost_full_g,
									almost_empty_g		=>	almost_empty_g
									)
									port map
									(
									clk 				=>	clk,
									rst 				=>	rst,
									din 				=>	din,
									wr_en 				=>	wr_en,
									rd_en 				=>	rd_en,
									flush				=>	flush,
									dout 				=>	dout,
									dout_valid			=>	dout_valid,
									afull  				=>	afull,
									full 				=>	full,
									aempty 				=>	aempty,
									empty 				=>	empty,
									used 				=>	used
									);
									
	clk_proc:
	clk	<=	not clk after 20 ns;
	
	rst_proc:
	rst	<=	reset_polarity_g, not reset_polarity_g after 20 ns;
	
	data_proc: process
	begin
		wait for 80 ns;
		-- (1) R & W on the same clk
		din		<=	"00000001";
		wr_en	<=	'1';
		rd_en	<=	'0';
		wait until falling_edge(clk);
		din		<=	"00000010";
		wr_en	<=	'1';
		rd_en	<=	'1';
		wait until falling_edge(clk);
		wr_en	<=	'0';
		rd_en	<=	'0';
		wait for 100 ns;
		-- (2) R & W when fifo is empty
		wait until falling_edge(clk);
		flush	<=	'1';
		wait until falling_edge(clk);
		flush	<=	'0';
		din		<=	"00000100";
		wr_en	<=	'1';
		rd_en	<=	'1';
		wait until falling_edge(clk);
		wr_en	<=	'0';
		rd_en	<=	'0';
		wait for 100 ns;
		-- (3) R & W when fifo is full
		wait until falling_edge(clk);
		flush	<=	'1';
		wait until falling_edge(clk);
		flush	<=	'0';
		din		<=	"00001000";
		wr_en	<=	'1';
		rd_en	<=	'0';
		wait until falling_edge(clk);
		din		<=	"00010000";
		wr_en	<=	'1';
		rd_en	<=	'0';
		wait until falling_edge(clk);
		din		<=	"00100000";
		wr_en	<=	'1';
		rd_en	<=	'0';
		wait until falling_edge(clk);
		din		<=	"01000000";
		wr_en	<=	'1';
		rd_en	<=	'0';
		wait until falling_edge(clk);
		din		<=	"10000000";
		wr_en	<=	'1';
		rd_en	<=	'0';
		wait until falling_edge(clk);
		wr_en	<=	'0';
		rd_en	<=	'0';
		wait until falling_edge(clk);
		din		<=	"00000001";
		wr_en	<=	'1';
		rd_en	<=	'1';
		wait until falling_edge(clk);
		wr_en	<=	'0';
		rd_en	<=	'0';
		wait for 100 ns;
		-- (4) R when fifo is empty
		wait until falling_edge(clk);
		flush	<=	'1';
		wait until falling_edge(clk);
		flush	<=	'0';
		wr_en	<=	'0';
		rd_en	<=	'1';
		wait until falling_edge(clk);
		wr_en	<=	'0';
		rd_en	<=	'0';
		wait for 100 ns;
		wait;
	end process data_proc;
	
end architecture sim;	
	
	
	
	
	
	


