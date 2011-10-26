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
//  Input interface instance                       //
/////////////////////////////////////////////////////

spi_master_in_interface in_intf(clk);

/////////////////////////////////////////////////////
//  SPI interface instance                         //
/////////////////////////////////////////////////////

spi_interface spi_intf(clk);


/////////////////////////////////////////////////////
//  Program block Testcase instance                //
/////////////////////////////////////////////////////

burst_testcase TC1 (in_intf, spi_intf);
//rst_testcase TC2 (in_intf, spi_intf);
//cpolpha_testcase TC3 (in_intf, spi_intf);
//clk_freq_testcase TC4 (in_intf, spi_intf);
//wr_forb_regs TC5 (in_intf, spi_intf);
//fifo_val_err TC6 (in_intf, spi_intf);
//wr_err_clk_div TC7 (in_intf, spi_intf);

/////////////////////////////////////////////////////
//  DUT instance and signal connection             //
/////////////////////////////////////////////////////


spi_master #(.bits_of_slaves_g(2)) DUT (.clk(clk),
               .rst(in_intf.rst),
               .fifo_req_data(in_intf.fifo_req_data),
               .fifo_din(in_intf.fifo_din),
               .fifo_din_valid(in_intf.fifo_din_valid),
               .fifo_empty(in_intf.fifo_empty),
               .spi_slave_addr(in_intf.spi_slave_addr),
               .reg_addr(in_intf.reg_addr),
               .reg_din(in_intf.reg_din),
               .reg_din_val(in_intf.reg_din_val),
               .reg_ack(in_intf.reg_ack),
               .reg_err(in_intf.reg_err),
               .busy(in_intf.busy),
               .dout(in_intf.dout),
               .dout_valid(in_intf.dout_valid),
               .spi_clk(spi_intf.spi_clk),
               .spi_mosi(spi_intf.spi_mosi),
               .spi_miso(spi_intf.spi_miso),
               .spi_ss(spi_intf.spi_ss));

endmodule


`endif