`ifndef GUARD_ENV
`define GUARD_ENV
`include "globals.sv"
`include "packet.sv"
`include "driver.sv"
`include "receiver.sv"
`include "scoreboard.sv"

//`timescale 1ps/1ps

class Environment ;


  //Declare Interfaces
  virtual slave_host_interface.SLAVE_HOST	host_intf;	//Host Interface
  virtual slave_spi_interface.SLAVE_SPI		spi_intf;	//SPI Interface
  virtual slave_config_interface.SLAVE_CONFIG	conf_intf;	//Configuration Interface
  
  Driver drvr;
  Receiver rcvr;
  Scoreboard sb;
  mailbox rcvr_tx2sb;
  mailbox rcvr_rx2sb;
  mailbox drvr_tx2sb ;
  mailbox drvr_rx2sb ;

function new(virtual slave_host_interface.SLAVE_HOST host_intf_new,
             virtual slave_spi_interface.SLAVE_SPI  spi_intf_new,
			 virtual slave_config_interface.SLAVE_CONFIG conf_intf_new);

  this.host_intf	=	host_intf_new ;
  this.spi_intf		=	spi_intf_new  ;
  this.conf_intf	=	conf_intf_new ;

  $display(" %0d : Environemnt : created env object",$time);
  
endfunction : new

function void build();
   $display(" %0d : Environemnt : start of build() method",$time);
   drvr_tx2sb = new();
   drvr_rx2sb = new();
   rcvr_tx2sb = new();
   rcvr_rx2sb = new();
   sb = new(drvr_tx2sb, drvr_rx2sb, rcvr_tx2sb, rcvr_rx2sb);
   drvr = new(spi_intf,drvr_tx2sb, drvr_rx2sb);
   rcvr = new(host_intf, rcvr_tx2sb, rcvr_rx2sb);
   $display(" %0d : Environemnt : end of build() method",$time);
   
endfunction : build

task reset();
  $display(" %0d : Environemnt : start of reset() method",$time);
  // setting inputs to a default state
  host_intf.fifo_din		<=	'{default:0};
  host_intf.fifo_din_valid	<=	0;
  host_intf.fifo_empty		<=	1;
  spi_intf.spi_clk		<=	cpol;
  spi_intf.spi_ss		<=	1;
  spi_intf.spi_mosi		<=	0;
  conf_intf.reg_din			<=	'{default:0};
  conf_intf.reg_din_val		<=	0;
  
  // RESET the DUT
  host_intf.rst      		<= 0;
  repeat (4) @(host_intf.clk);
  host_intf.rst      		<= 1;
  
  $display(" %0d : Environemnt : end of reset() method",$time);
  
endtask : reset
  
task cfg_dut();
  $display(" %0d : Environemnt : start of cfg_dut() method",$time);
  
  @(posedge conf_intf.clk);
  conf_intf.reg_din[0] 		<= cpha;
  conf_intf.reg_din[1] 		<= cpol;
  conf_intf.reg_din_val		<= 1;

  @(posedge conf_intf.clk);
  conf_intf.reg_din_val		<=  0;
  
  @(posedge conf_intf.clk);
  reg_conf_assert: assert (!conf_intf.reg_ack)
  else
  begin
	$error ("Acknowledge register was not detected, Time: %0t", $time);
	error++;
  end
	
  @(posedge conf_intf.clk);
  $display(" %0d : Environemnt : end of cfg_dut() method",$time);
  
endtask :cfg_dut

task start();
  $display(" %0d : Environemnt : start of start() method",$time);
  fork
	drvr.start();
   	rcvr.tx();
   	rcvr.rx();
	sb.rx_get();
	sb.tx_get();
  join_any
  $display(" %0d : Environemnt : end of start() method",$time);
  
endtask : start

task stop();
	bit finish = 0;
	
	$display(" %0d : Environemnt : start of stop() method",$time);
	drvr.finish(finish);
	wait(finish == 1); // Finished driving the data from the master
	rcvr.finish();
	$display(" %0d : Environemnt : end of stop () method",$time);
	
endtask : stop
	
task wait_for_end();
   $display(" %0d : Environemnt : start of wait_for_end() method",$time);
   repeat(10000) @(host_intf.clk);
   $display(" %0d : Environemnt : end of wait_for_end() method",$time);
   
endtask : wait_for_end

task run();
   $display(" %0d : Environemnt : start of run() method",$time);
   build();
   reset();
   cfg_dut();
   fork
   	start();
   	stop();
   join
   wait_for_end();
   report();
   $display(" %0d : Environemnt : end of run() method",$time);
   
endtask : run

task report();
   $display("\n\n*************************************************");
   if( 0 == error)
       $display("********            TEST PASSED         *********");
   else
       $display("********    TEST Failed with %0d errors *********",error);
   
   $display("*************************************************\n\n");
   
endtask : report

endclass

`endif
