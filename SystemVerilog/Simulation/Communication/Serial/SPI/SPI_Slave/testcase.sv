`ifndef GUARD_TESTCASE
`define GUARD_TESTCASE
`include "environment.sv"

//`timescale 1ps/1ps

program testcase(slave_host_interface.SLAVE_HOST host_intf, slave_spi_interface.SLAVE_SPI spi_intf, slave_config_interface.SLAVE_CONFIG conf_intf);

	Environment env;

	initial
	begin
		$display(" ******************* Start of testcase ****************");
		env = new(host_intf, spi_intf, conf_intf);
		$display(" ******************* Executing Testcase ***************");
		env.run();
		#1000;
	end

	final
	$display(" ******************** End of testcase *****************");

endprogram 

`endif
