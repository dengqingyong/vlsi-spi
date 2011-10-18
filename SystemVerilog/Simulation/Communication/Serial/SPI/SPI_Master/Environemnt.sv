`ifndef GUARD_ENV
`define GUARD_ENV
`include "Globals.sv"
`include "Packet.sv"
`include "Driver.sv"
`include "Receiver.sv"
`include "Scoreboard.sv"

class Environment ;


  //Declare Interfaces
  virtual spi_master_in_interface.MASTER_INPUT	in_intf;	//Inputs to SPI Master
  virtual spi_interface.MASTER_SPI				spi_intf;	//SPI Interface
  
  Driver drvr;
  Receiver rcvr[bits_of_slaves_c];
  Scoreboard sb;
  mailbox rcvr_tx2sb;
  mailbox rcvr_rx2sb;
  mailbox drvr_tx2sb ;
  mailbox drvr_rx2sb ;
  logic [reg_din_width_c - 1:0] clk_div_reg = 2;
  

function new(virtual spi_master_in_interface.MASTER_INPUT    in_intf_new       ,
             virtual spi_interface.MASTER_SPI  spi_intf_new   );

  this.in_intf	= in_intf_new    ;
  this.spi_intf	= spi_intf_new  ;

  $display(" %0d : Environemnt : created env object",$time);
endfunction : new

function void build();
   $display(" %0d : Environemnt : start of build() method",$time);
   drvr_tx2sb = new();
   drvr_rx2sb = new();
   rcvr_tx2sb = new();
   rcvr_rx2sb = new();
   sb = new(drvr_tx2sb, drvr_rx2sb, rcvr_tx2sb, rcvr_rx2sb);
   drvr = new(in_intf,drvr_tx2sb, drvr_rx2sb);
   foreach(rcvr[i])
     rcvr[i]= new(spi_intf, rcvr_tx2sb, rcvr_rx2sb, i);
   $display ("Receiver #0 sernum is (%d), #1 sernum is (%d)", rcvr[0].receiver_sernum, rcvr[1].receiver_sernum);
   $display(" %0d : Environemnt : end of build() method",$time);
endfunction : build

task reset();
  $display(" %0d : Environemnt : start of reset() method",$time);
  in_intf.rst      			<= 0;
  in_intf.fifo_din          <= '{default:0};
  in_intf.fifo_din_valid    <= 0;
  in_intf.fifo_empty        <= 1;
  in_intf.spi_slave_addr    <= '{default:0};
  in_intf.reg_addr          <= '{default:0};
  in_intf.reg_din           <= '{default:0};
  in_intf.reg_din_val       <= 0;
  spi_intf.spi_miso			<= 1'bz;
  
  repeat (4) @(in_intf.clk);
  in_intf.rst      <= 1;
  
  $display(" %0d : Environemnt : end of reset() method",$time);
endtask : reset
  
task cfg_dut(logic [reg_din_width_c - 1:0] clk_div_reg, logic [reg_din_width_c - 1:0] cphapol_reg);
  $display(" %0d : Environemnt : start of cfg_dut() method",$time);
  
  @(posedge in_intf.clk);
  in_intf.reg_addr 		<= '{default:0};	//Clock Divide register
  in_intf.reg_din 		<= clk_div_reg;
  in_intf.reg_din_val	<= 1;
  @(posedge in_intf.clk);
  in_intf.reg_addr 		<= 1;	//CPHA, CPOL Register
  in_intf.reg_din 		<= cphapol_reg;
  in_intf.reg_din_val	<= 1;

  reg_err_assert: assert (!in_intf.reg_err)
  else
  begin
	$error ("reg_err detected, Time: %0t", $time);
	error++;
  end

  @(posedge in_intf.clk);
  in_intf.reg_din_val	<= 0;
	
  @(posedge in_intf.clk);
  $display(" %0d : Environemnt : end of cfg_dut() method",$time);
endtask :cfg_dut

task start();
  $display(" %0d : Environemnt : start of start() method",$time);
  fork
    drvr.start();
	drvr.rx();
    foreach(rcvr[i])
		rcvr[i].start();
    sb.rx_get();
    sb.tx_get();
  join_any
  $display(" %0d : Environemnt : end of start() method",$time);
endtask : start

task wait_for_end();
   $display(" %0d : Environemnt : start of wait_for_end() method",$time);
   repeat(10000) @(in_intf.clk);
   $display(" %0d : Environemnt : end of wait_for_end() method",$time);
endtask : wait_for_end

task run();
   logic [reg_din_width_c - 1:0] temp_regs = '{default:0};
   $display(" %0d : Environemnt : start of run() method",$time);
   build();
   temp_regs[0] = rcvr[0].cpha;
   temp_regs[1] = rcvr[0].cpol;
   reset();
   cfg_dut(clk_div_reg, temp_regs);
   start();
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
endtask:report

endclass

`endif
