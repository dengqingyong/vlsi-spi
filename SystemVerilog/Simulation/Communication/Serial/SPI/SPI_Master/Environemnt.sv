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
   drvr = new(in_intf, spi_intf, drvr_tx2sb, drvr_rx2sb);
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
  foreach (rcvr[i])	//Config receivers
	rcvr[i].cfg_cpolpha(cphapol_reg[1], cphapol_reg[0]);
  $display(" %0d : Environemnt : end of cfg_dut() method",$time);
endtask :cfg_dut

task rst_val_outs();
	$display(" %0d : Environemnt : start of rst_val_outs() method",$time);
	build();
	drvr.rst_val_outs();
	wait_for_end();
	report();
	$display(" %0d : Environemnt : end of rst_val_outs() method",$time);
endtask : rst_val_outs

task start();
  $display(" %0d : Environemnt : start of start() method",$time);
  fork
    drvr.start();
	drvr.rx();
//    foreach(rcvr[i])
//		rcvr[i].start();
	rcvr[0].start();
	rcvr[1].start();
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
   temp_regs[0]=1'b1;
   temp_regs[1]=1'b1;
   $display(" %0d : Environemnt : start of run() method",$time);
   build();
   reset();
   cfg_dut(clk_div_reg, temp_regs);
   start();
   wait_for_end();
   report();
   $display(" %0d : Environemnt : end of run() method",$time);
endtask : run

/// Method to exetute transmission in CPOL, CPHA (00, 01, 10, 11)
task run_4_clk_cfg();
   logic [reg_din_width_c - 1:0] temp_regs = '{default:0};
	build();
	reset();
	//Start receivers & scoreboard
	fork
		drvr.rx();
		rcvr[0].start();
		rcvr[1].start();
		sb.rx_get();
		sb.tx_get();
	join_none

   //Config all 4 CPOL, CPHA states
   repeat(4)
   begin
	cfg_dut(clk_div_reg, temp_regs);
	drvr.start();	//Execute transmission
	repeat(50)@(posedge in_intf.clk);
	temp_regs++;
   end
   wait_for_end();
   report();
endtask : run_4_clk_cfg

/// Method to exetute transmission in all clocks frequencies
task run_clk_freq();
   logic [reg_din_width_c - 1:0] temp_regs = '{default:0};
   logic [reg_din_width_c - 1:0] clk_regs = 2;	//2 is minimum value
   logic [1:0] 					 cpolpha = '{default:0};
   
	build();
	reset();
	//Start receivers & scoreboard
	fork
		drvr.rx();
		rcvr[0].start();
		rcvr[1].start();
		sb.rx_get();
		sb.tx_get();
	join_none

   //Config all 4 CPOL, CPHA states, and all Clock Frequencies
   while (clk_regs > 0)
   begin
	repeat (4) //For all CPOL, CPHA
	begin
		$display ("Clk Reg: %h, CPOLPHA Reg : %h", clk_regs, temp_regs);
		cfg_dut(clk_regs, temp_regs);
		temp_regs[1:0] = cpolpha; //Change CPOL, CPHA
		drvr.start();	//Execute transmission
		repeat(50)@(posedge in_intf.clk);
		clk_regs++;					//Change clock frequency
		if (cpolpha < 2'b3)
			cpolpha++;
		else
			cpolpha = 2'b0;
		temp_regs[1:0] = cpolpha [1:0];	//Change CPOL, CPHA
	end
   end
   wait_for_end();
   report();
endtask : run_clk_freq

/// Method to write to registers during active tranasction (Should cause error)
task wr_forb_regs();
   logic [reg_din_width_c - 1:0] temp_regs = '{default:0};
   logic [reg_din_width_c - 1:0] clk_regs = 2;	//2 is minimum value
   int err_before;	//Number of errors before firbedden config
   
	build();
	reset();
	cfg_dut(clk_regs, temp_regs);
	//Start Driver, receivers & scoreboard
	fork
		drvr.rx();
		rcvr[0].start();
		rcvr[1].start();
		sb.rx_get();
		sb.tx_get();
		drvr.start();	//Execute transmission
	join_none

	if (!in_intf.busy)
		@(posedge in_intf.busy);
	err_before = error;
	cfg_dut(clk_regs, temp_regs);	//Try to write registers when SPI is BUSY
	assert (err_before == error - 1)
		error--;	//Error was incremeneted by cfg_dut
	else
		$error ("%t >> Expecting REG_ERR, but such did not detected", $time);
   end
   wait_for_end();
   report();
endtask : wr_forb_regs

/// Method to write to Clock Divide register value less than 2 (1, 0)
task wr_err_clk_div();
	logic [reg_din_width_c - 1:0] temp_regs = '{default:0};
	logic [reg_din_width_c - 1:0] clk_regs;	//2 is minimum value
	int err_before;	//Number of errors before firbedden config
   
	build();
	reset();
	clk_regs = 0;
	cfg_dut(clk_regs, temp_regs);
	clk_regs = 1;
	cfg_dut(clk_regs, temp_regs);
	assert (err_before == error - 2)
		error=-2;	//Error was incremeneted by cfg_dut
	else
		$error ("%t >> Expecting REG_ERR, but such did not detected", $time);
	wait_for_end();
	report();
endtask : wr_err_clk_div


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
