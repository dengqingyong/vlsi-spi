`ifndef GUARD_TOP
`define GUARD_TOP

//`timescale 1ps/1ps

module top();

/////////////////////////////////////////////////////
// clk Declaration and Generation                //
/////////////////////////////////////////////////////
bit clk;

initial
  forever #10 clk = ~clk;

/////////////////////////////////////////////////////
//  Host interface instance                        //
/////////////////////////////////////////////////////

slave_host_interface host_intf(clk);

/////////////////////////////////////////////////////
//  SPI interface instance                         //
/////////////////////////////////////////////////////

slave_spi_interface spi_intf(clk);

/////////////////////////////////////////////////////
//  Configuration interface instance               //
/////////////////////////////////////////////////////

slave_config_interface conf_intf(clk);


/////////////////////////////////////////////////////
//  Program block Testcase instance                //
/////////////////////////////////////////////////////

testcase TC1 (host_intf, spi_intf, conf_intf);

/////////////////////////////////////////////////////
//  DUT instance and signal connection             //
/////////////////////////////////////////////////////

spi_slave DUT (.clk(clk),
               .rst(host_intf.DUT.rst),
               .fifo_req_data(host_intf.DUT.fifo_req_data),
               .fifo_din(host_intf.DUT.fifo_din),
               .fifo_din_valid(host_intf.DUT.fifo_din_valid),
               .fifo_empty(host_intf.DUT.fifo_empty),
               .reg_din(conf_intf.DUT.reg_din),
               .reg_din_val(conf_intf.DUT.reg_din_val),
               .reg_ack(conf_intf.DUT.reg_ack),
			   .timeout(host_intf.DUT.timeout),
               .busy(host_intf.DUT.busy),
			   .interrupt(host_intf.DUT.interrupt),
               .dout(host_intf.DUT.dout),
               .dout_valid(host_intf.DUT.dout_valid),
               .spi_clk(spi_intf.DUT.spi_clk),
               .spi_mosi(spi_intf.DUT.spi_mosi),
               .spi_miso(spi_intf.DUT.spi_miso),
               .spi_ss(spi_intf.DUT.spi_ss));

endmodule

`endif