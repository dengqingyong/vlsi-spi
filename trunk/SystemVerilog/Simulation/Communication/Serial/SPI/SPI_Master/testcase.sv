`ifndef GUARD_TESTCASE
`define GUARD_TESTCASE
`include "Environemnt.sv"

//Normal Burst
program burst_testcase(spi_master_in_interface.MASTER_INPUT in_intf, spi_interface.MASTER_SPI spi_intf);

	Environment env;

	initial
	begin
	$display(" ******************* Start of Burst testcase ****************");
	env = new(in_intf,spi_intf);
	//packet::payload_data_c.constraint_mode(0);
	$display(" ******************* Executing Testcase	 ******************");
	env.run();
	#1000;
	end

	final
	$display(" ******************** End of Burst testcase *****************");

endprogram 

//Reset, swing inputs
program rst_testcase(spi_master_in_interface.MASTER_INPUT in_intf, spi_interface.MASTER_SPI spi_intf);

	Environment env;

	initial
	begin
	$display(" ******************* Start of Reset testcase ****************");
	env = new(in_intf,spi_intf);
	$display(" ******************* Executing Testcase	 ******************");
	env.rst_val_outs();
	#1000;
	end

	final
	$display(" ******************** End of Reset testcase *****************");

endprogram 

//All CPOL, CPHA (4 states) burst
program cpolpha_testcase(spi_master_in_interface.MASTER_INPUT in_intf, spi_interface.MASTER_SPI spi_intf);

	Environment env;

	initial
	begin
	$display(" ******************* Start of CPOL, CPHA testcase ****************");
	env = new(in_intf,spi_intf);
	$display(" ******************* Executing Testcase	 ******************");
	env.run_4_clk_cfg();
	#1000;
	end

	final
	$display(" ******************** End of CPOL, CPHA testcase *****************");

endprogram 

//All CPOL, CPHA (4 states) burst, with all Clock Frequency Range
program clk_freq_testcase(spi_master_in_interface.MASTER_INPUT in_intf, spi_interface.MASTER_SPI spi_intf);

	Environment env;

	initial
	begin
	$display(" ******************* Start of Clock Frequency testcase ****************");
	env = new(in_intf,spi_intf);
	$display(" ******************* Executing Testcase	 ******************");
	env.run_clk_freq();
	#1000;
	end

	final
	$display(" ******************** End of Clock Frequency testcase *****************");

endprogram 

//Writing to registes while it is forbidden
program wr_forb_regs (spi_master_in_interface.MASTER_INPUT in_intf, spi_interface.MASTER_SPI spi_intf);

	Environment env;

	initial
	begin
	$display(" ******************* Start of Forbidden Register Write testcase ****************");
	env = new(in_intf,spi_intf);
	$display(" ******************* Executing Testcase	 ******************");
	env.wr_forb_regs();
	#1000;
	end

	final
	$display(" ******************** End of Forbidden Register Write testcase *****************");

endprogram 

//FIFO_DIN_VALID is not asserted when it should
program fifo_val_err (spi_master_in_interface.MASTER_INPUT in_intf, spi_interface.MASTER_SPI spi_intf);

	Environment env;

	initial
	begin
	$display(" ******************* Start of FIFO_DIN_VALID Error testcase ****************");
	env = new(in_intf,spi_intf);
	$display(" ******************* Executing Testcase	 ******************");
	env.fifo_val_err();
	#1000;
	end

	final
	$display(" ******************** End of FIFO_DIN_VALID Error testcase *****************");

endprogram 

//Write Clock Divide Values which are not supported (0, 1)
program wr_err_clk_div (spi_master_in_interface.MASTER_INPUT in_intf, spi_interface.MASTER_SPI spi_intf);

	Environment env;

	initial
	begin
	$display(" ******************* Start of Clock Divide Error testcase ****************");
	env = new(in_intf,spi_intf);
	$display(" ******************* Executing Testcase	 ******************");
	env.wr_err_clk_div();
	#1000;
	end

	final
	$display(" ******************** End of Clock Divide Error testcase *****************");

endprogram 

`endif
