`ifndef GUARD_TOP
`define GUARD_TOP

module top();

/////////////////////////////////////////////////////
// clk Declaration					                //
/////////////////////////////////////////////////////
bit clk;

/////////////////////////////////////////////////////
// 						WIRES              		   //
/////////////////////////////////////////////////////
wire 								spi_clk;
wire								spi_miso;
wire								spi_mosi;
wire	[bits_of_slaves_c - 1:0]	spi_ss;


initial
  forever #10 clk = ~clk;

/////////////////////////////////////////////////////
//  Master interface instance                      //
/////////////////////////////////////////////////////

spi_master_interface master_intf(clk);

/////////////////////////////////////////////////////
//  SLave interface instance                       //
/////////////////////////////////////////////////////

spi_slave_interface slave_intf[4](clk);

/////////////////////////////////////////////////////
//  Program block Testcase instance                //
/////////////////////////////////////////////////////

burst_testcase TC1 (master_intf, slave_intf);
//cpolpha_testcase TC3 (master_intf, slave_intf);
//clk_freq_testcase TC4 (master_intf, slave_intf);

/////////////////////////////////////////////////////
//  DUT instance and signal connection             //
/////////////////////////////////////////////////////

spi_master #(.bits_of_slaves_g(4)) MASTER
			  (.clk(clk),
               .rst(master_intf.rst),
               .fifo_req_data(master_intf.fifo_req_data),
               .fifo_din(master_intf.fifo_din),
               .fifo_din_valid(master_intf.fifo_din_valid),
               .fifo_empty(master_intf.fifo_empty),
               .spi_slave_addr(master_intf.spi_slave_addr),
               .reg_addr(master_intf.reg_addr),
               .reg_din(master_intf.reg_din),
               .reg_din_val(master_intf.reg_din_val),
               .reg_ack(master_intf.reg_ack),
               .reg_err(master_intf.reg_err),
               .busy(master_intf.busy),
               .dout(master_intf.dout),
               .dout_valid(master_intf.dout_valid),
               .spi_clk(spi_clk),
               .spi_mosi(spi_mosi),
               .spi_miso(spi_miso),
               .spi_ss(spi_ss));

spi_slave SLAVE0 (.clk(clk),
               .rst(slave_intf[0].rst),
               .fifo_req_data(slave_intf[0].fifo_req_data),
               .fifo_din(slave_intf[0].fifo_din),
               .fifo_din_valid(slave_intf[0].fifo_din_valid),
               .fifo_empty(slave_intf[0].fifo_empty),
               .reg_din(slave_intf[0].reg_din),
               .reg_din_val(slave_intf[0].reg_din_val),
               .reg_ack(slave_intf[0].reg_ack),
			   .timeout(slave_intf[0].timeout),
               .busy(slave_intf[0].busy),
			   .interrupt(slave_intf[0].interrupt),
               .dout(slave_intf[0].dout),
               .dout_valid(slave_intf[0].dout_valid),
               .spi_clk(spi_clk),
               .spi_mosi(spi_mosi),
               .spi_miso(spi_miso),
               .spi_ss(spi_ss[0]));
			   
spi_slave SLAVE1 (.clk(clk),
               .rst(slave_intf[1].rst),
               .fifo_req_data(slave_intf[1].fifo_req_data),
               .fifo_din(slave_intf[1].fifo_din),
               .fifo_din_valid(slave_intf[1].fifo_din_valid),
               .fifo_empty(slave_intf[1].fifo_empty),
               .reg_din(slave_intf[1].reg_din),
               .reg_din_val(slave_intf[1].reg_din_val),
               .reg_ack(slave_intf[1].reg_ack),
			   .timeout(slave_intf[1].timeout),
               .busy(slave_intf[1].busy),
			   .interrupt(slave_intf[1].interrupt),
               .dout(slave_intf[1].dout),
               .dout_valid(slave_intf[1].dout_valid),
               .spi_clk(spi_clk),
               .spi_mosi(spi_mosi),
               .spi_miso(spi_miso),
               .spi_ss(spi_ss[1]));
			   
spi_slave SLAVE2 (.clk(clk),
               .rst(slave_intf[2].rst),
               .fifo_req_data(slave_intf[2].fifo_req_data),
               .fifo_din(slave_intf[2].fifo_din),
               .fifo_din_valid(slave_intf[2].fifo_din_valid),
               .fifo_empty(slave_intf[2].fifo_empty),
               .reg_din(slave_intf[2].reg_din),
               .reg_din_val(slave_intf[2].reg_din_val),
               .reg_ack(slave_intf[2].reg_ack),
			   .timeout(slave_intf[2].timeout),
               .busy(slave_intf[2].busy),
			   .interrupt(slave_intf[2].interrupt),
               .dout(slave_intf[2].dout),
               .dout_valid(slave_intf[2].dout_valid),
               .spi_clk(spi_clk),
               .spi_mosi(spi_mosi),
               .spi_miso(spi_miso),
               .spi_ss(spi_ss[2]));
			   
spi_slave SLAVE3 (.clk(clk),
               .rst(slave_intf[3].rst),
               .fifo_req_data(slave_intf[3].fifo_req_data),
               .fifo_din(slave_intf[3].fifo_din),
               .fifo_din_valid(slave_intf[3].fifo_din_valid),
               .fifo_empty(slave_intf[3].fifo_empty),
               .reg_din(slave_intf[3].reg_din),
               .reg_din_val(slave_intf[3].reg_din_val),
               .reg_ack(slave_intf[3].reg_ack),
			   .timeout(slave_intf[3].timeout),
               .busy(slave_intf[3].busy),
			   .interrupt(slave_intf[3].interrupt),
               .dout(slave_intf[3].dout),
               .dout_valid(slave_intf[3].dout_valid),
               .spi_clk(spi_clk),
               .spi_mosi(spi_mosi),
               .spi_miso(spi_miso),
               .spi_ss(spi_ss[3]));

endmodule

`endif