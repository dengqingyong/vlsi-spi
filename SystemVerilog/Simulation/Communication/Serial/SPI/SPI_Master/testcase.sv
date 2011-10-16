`ifndef GUARD_TESTCASE
`define GUARD_TESTCASE

//Normal Burst
program burst_testcase(spi_master_in_interface.MASTER_INPUT in_intf, spi_interface.MASTER_SPI spi_intf);

Environment env;

initial
begin
$display(" ******************* Start of Burst testcase ****************");
env = new(in_intf,spi_intf);
env.run();
#1000;
end

final
$display(" ******************** End of Burst testcase *****************");

endprogram 

`endif
