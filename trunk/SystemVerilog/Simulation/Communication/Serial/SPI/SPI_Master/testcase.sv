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

`endif
