`ifndef GUARD_TOP
`define GUARD_TOP

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
               .rst(host_intf.rst),
               .fifo_req_data(host_intf.fifo_req_data),
               .fifo_din(host_intf.fifo_din),
               .fifo_din_valid(host_intf.fifo_din_valid),
               .fifo_empty(host_intf.fifo_empty),
               .reg_din(conf_intf.reg_din),
               .reg_din_val(conf_intf.reg_din_val),
               .reg_ack(conf_intf.reg_ack),
			   .reg_err(conf_intf.reg_err),
               .busy(host_intf.busy),
			   .interrupt(host_intf.interrupt),
               .dout(host_intf.dout),
               .dout_valid(host_intf.dout_valid),
               .spi_clk(spi_intf.cb.spi_clk),
               .spi_mosi(spi_intf.cb.spi_mosi),
               .spi_miso(spi_intf.cb.spi_miso),
               .spi_ss(spi_intf.cb.spi_ss));

endmodule

`endif