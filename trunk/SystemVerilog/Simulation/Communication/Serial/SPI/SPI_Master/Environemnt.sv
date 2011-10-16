`ifndef GUARD_ENV
`define GUARD_ENV

class Environment ;


  //Declare Interfaces
  virtual spi_master_in_interface.MASTER_INPUT	in_intf;	//Inputs to SPI Master
  virtual spi_interface.MASTER_SPI				spi_intf;	//SPI Interface
  
  Driver drvr;
  Receiver rcvr[4];
  Scoreboard sb;
  mailbox rcvr_tx2sb;
  mailbox rcvr_rx2sb;
  mailbox drvr_tx2sb ;
  mailbox drvr_rx2sb ;

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
   drvr = new(input_intf,drvr_tx2sb, drvr_rx2sb);
   foreach(rcvr[i])
     rcvr[i]= new(in_intf, rcvr_tx2sb, rcvr_rx2sb);
   $display(" %0d : Environemnt : end of build() method",$time);
endfunction : build

task reset();
  $display(" %0d : Environemnt : start of reset() method",$time);
  in_intf.reset      <= 0;
  repeat (4) @ input_intf.clk;
  in_intf.reset      <= 1;
  
  $display(" %0d : Environemnt : end of reset() method",$time);
endtask : reset
  
task cfg_dut(logic [reg_din_width_c - 1:0] clk_div_reg, logic [reg_din_width_c - 1:0] cphapol_reg);
  $display(" %0d : Environemnt : start of cfg_dut() method",$time);
  
  @(posedge in_intf.clk);
  in_intf.reg_addr 		<= reg_addr_width_c'd0;	//Clock Divide register
  in_intf.reg_din 		<= clk_div_reg;
  in_intf.reg_din_val	<= 1;
  @(posedge in_intf.clk);
  in_intf.reg_addr 		<= reg_addr_width_c'd1;	//CPHA, CPOL Register
  in_intf.reg_din 		<= cphaphol_reg;
  in_intf.reg_din_val	<= 1;

  clk_reg_ack_assert: assert (!in_intf.reg_ack or in_intf.reg_err)
  begin
	$error ("Acknowledge register was not detected, Time: %0t", $time);
	error++;
  end
  @(posedge in_intf.clk);
  in_intf.reg_din_val	<= 0;
  cphapol_reg_ack_assert: assert (!in_intf.reg_ack or in_intf.reg_err)
  begin
	$error ("Acknowledge register was not detected, Time: %0t", $time);
	error++;
  end
	
  @(posedge in_intf.clk);
  $display(" %0d : Environemnt : end of cfg_dut() method",$time);
endtask :cfg_dut

task start();
  $display(" %0d : Environemnt : start of start() method",$time);
  fork
    drvr.start();
	drvr.rx();
    rcvr[0].start();
    rcvr[1].start();
    rcvr[2].start();
    rcvr[3].start();
    sb.start();
  join_any
  $display(" %0d : Environemnt : end of start() method",$time);
endtask : start

task wait_for_end();
   $display(" %0d : Environemnt : start of wait_for_end() method",$time);
   repeat(10000) @(input_intf.clock);
   $display(" %0d : Environemnt : end of wait_for_end() method",$time);
endtask : wait_for_end

task run();
   $display(" %0d : Environemnt : start of run() method",$time);
   build();
   reset();
   cfg_dut();
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
