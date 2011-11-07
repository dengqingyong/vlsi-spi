`ifndef GUARD_ENV
`define GUARD_ENV
`include "globals.sv"
`include "packet.sv"
`include "driver.sv"
`include "receiver.sv"
`include "scoreboard.sv"

class Environment ;


	//Declare Interfaces
	virtual spi_master_interface.SPI_MASTER	master_intf;	//Inputs to SPI Master
	virtual spi_slave_interface.SPI_SLAVE	slave_intf[4];	//Inputs to SPI Slave * 4
  
	Driver drvr;
	Receiver rcvr[bits_of_slaves_c];
	Scoreboard sb;
	mailbox rcvr_tx2sb;
	mailbox rcvr_rx2sb;
	mailbox drvr_tx2sb ;
	mailbox drvr_rx2sb ;
	logic [reg_din_width_c - 1:0] clk_div_reg = 2;
  

function new (virtual spi_master_interface.SPI_MASTER master_intf_new,
             virtual spi_slave_interface.SPI_SLAVE  slave_intf_new[4] );

	this.master_intf	= master_intf_new ;
	this.slave_intf		= slave_intf_new  ;

	$display(" %0d : Environemnt : created env object",$time);
  
endfunction : new


function void build();
	$display(" %0d : Environemnt : start of build() method",$time);
	drvr_tx2sb = new();
	drvr_rx2sb = new();
	rcvr_tx2sb = new();
	rcvr_rx2sb = new();
	sb = new(drvr_tx2sb, drvr_rx2sb, rcvr_tx2sb, rcvr_rx2sb);
	drvr = new(master_intf, drvr_tx2sb, drvr_rx2sb);
	rcvr[0]= new(slave_intf[0], rcvr_tx2sb, rcvr_rx2sb, 0);
	rcvr[1]= new(slave_intf[1], rcvr_tx2sb, rcvr_rx2sb, 1);
	rcvr[2]= new(slave_intf[2], rcvr_tx2sb, rcvr_rx2sb, 2);
	rcvr[3]= new(slave_intf[3], rcvr_tx2sb, rcvr_rx2sb, 3);
	$display(" %0d : Environemnt : end of build() method",$time);
	
endfunction : build


task reset();
	$display(" %0d : Environemnt : start of reset() method",$time);
	master_intf.rst      			<= 0;
	master_intf.fifo_din          <= '{default:0};
	master_intf.fifo_din_valid    <= 0;
	master_intf.fifo_empty        <= 1;
	master_intf.spi_slave_addr    <= '{default:0};
	master_intf.reg_addr          <= '{default:0};
	master_intf.reg_din           <= '{default:0};
	master_intf.reg_din_val       <= 0;
  
	foreach (rcvr[i])
	begin
		slave_intf[i].rst      			<= 0;
		slave_intf[i].fifo_din       	<= '{default:0};
		slave_intf[i].fifo_din_valid    <= 0;
		slave_intf[i].fifo_empty        <= 1;
		slave_intf[i].reg_din           <= '{default:0};
		slave_intf[i].reg_din_val       <= 0;
	end // foreach
	
	repeat (4) @(master_intf.clk);
	
	master_intf.rst      <= 1;
	slave_intf[0].rst    <= 1;
	slave_intf[1].rst    <= 1;
	slave_intf[2].rst    <= 1;
	slave_intf[3].rst    <= 1;
	
  $display(" %0d : Environemnt : end of reset() method",$time);
  
endtask : reset
  
  
task cfg_dut(logic [reg_din_width_c - 1:0] clk_div_reg, logic [reg_din_width_c - 1:0] cphapol_reg);

	$display(" %0d : Environemnt : start of cfg_dut() method",$time);
  
	@(posedge master_intf.clk);
	master_intf.reg_addr 		<= '{default:0};	//Clock Divide register
	master_intf.reg_din 		<= clk_div_reg;
	master_intf.reg_din_val		<= 1;
	@(posedge master_intf.clk);
	master_intf.reg_addr 		<= 1;	//CPHA, CPOL Register
	master_intf.reg_din 		<= cphapol_reg;
	master_intf.reg_din_val		<= 1;

	reg_err_assert: assert (!master_intf.reg_err)
	else
	begin
		$error ("reg_err detected, Time: %0t", $time);
		error++;
	end // else

	@(posedge master_intf.clk);
	master_intf.reg_din_val		<= 0;
	
	// Config Receivers
	foreach (rcvr[i])
	begin
		@(posedge master_intf.clk);
		slave_intf[i].reg_din 		<= cphapol_reg;
		slave_intf[i].reg_din_val	<= 1;
		@(posedge master_intf.clk);
		rec_ack_assert: assert (slave_intf[i].reg_ack)
		else
		begin
			$error ("reg_ack wasn't detected, Time: %0t", $time);
			error++;
		end // else
		slave_intf[i].reg_din_val	<= 0;
	end // foreach
	
	$display(" %0d : Environemnt : end of cfg_dut() method",$time);
	
endtask :cfg_dut


task start();
	$display(" %0d : Environemnt : start of start() method",$time);
	fork
		drvr.tx();
		drvr.rx();
		rcvr[0].tx();
		rcvr[0].rx();
		rcvr[1].tx();
		rcvr[1].rx();
		rcvr[2].tx();
		rcvr[2].rx();
		rcvr[3].tx();
		rcvr[3].rx();
		sb.rx_get();
		sb.tx_get();
	join_any
	$display(" %0d : Environemnt : end of start() method",$time);
	
endtask : start


task stop();
	bit finish;
	int rec_num;
	
	forever
	begin
		$display(" %0d : Environemnt : start of stop() method",$time);
		drvr.finish(finish, rec_num);
		wait(finish == 1); // Finished driving the data from the master
		rcvr[rec_num].finish();
		$display(" %0d : Environemnt : stop () method activated on slave %d",$time, rec_num);
		finish = 0;
	end // forever
	
endtask : stop


task wait_for_end();
	$display(" %0d : Environemnt : start of wait_for_end() method",$time);
	repeat(10000) @(master_intf.clk);
	$display(" %0d : Environemnt : end of wait_for_end() method",$time);
endtask : wait_for_end

task run();
	logic [reg_din_width_c - 1:0] temp_regs = '{default:0};
	temp_regs[0]=1'b0; //cpha
	temp_regs[1]=1'b0; //cpol
	$display(" %0d : Environemnt : start of run() method",$time);
	build();
	reset();
	cfg_dut(clk_div_reg, temp_regs);
	fork
		start();
		stop();
	join_any
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
		rcvr[0].tx();
		rcvr[0].rx();
		rcvr[1].tx();
		rcvr[1].rx();
		rcvr[2].tx();
		rcvr[2].rx();
		rcvr[3].tx();
		rcvr[3].rx();
		sb.rx_get();
		sb.tx_get();
		stop();
	join_none

	//Config all 4 CPOL, CPHA states
	repeat(4)
	begin
		cfg_dut(clk_div_reg, temp_regs);
		drvr.tx();	//Execute transmission
		repeat(50) @(posedge master_intf.clk);
		temp_regs++;
	end //repeat
	wait_for_end();
	report();
	
endtask : run_4_clk_cfg///


/// Method to exetute transmission in all clocks frequencies
task run_clk_freq();
   logic [reg_din_width_c - 1:0] temp_regs = '{default:0};
   logic [reg_din_width_c - 1:0] clk_regs = 2;	//2 is minimum value
   logic [reg_din_width_c - 1:0] max_clk_regs_v = '{default:1};	//Maximum value
   logic [1:0] 					 cpolpha = '{default:0};
   
	build();
	reset();
	//Start receivers & scoreboard
	fork
		drvr.rx();
		rcvr[0].tx();
		rcvr[0].rx();
		rcvr[1].tx();
		rcvr[1].rx();
		rcvr[2].tx();
		rcvr[2].rx();
		rcvr[3].tx();
		rcvr[3].rx();
		sb.rx_get();
		sb.tx_get();
		stop();
	join_none

	//Config all 4 CPOL, CPHA states, and all Clock Frequencies
	while (clk_regs > 0 && clk_regs <= max_clk_regs_v)
	begin
		repeat (4) //For all CPOL, CPHA
		begin
			$display ("Clk Reg: %h, CPOLPHA Reg : %h", clk_regs, temp_regs);
			cfg_dut(clk_regs, temp_regs);
			//temp_regs[1:0] = cpolpha; //Change CPOL, CPHA
			drvr.tx();	//Execute transmission
			repeat(50) @(posedge master_intf.clk);
			clk_regs++;					//Change clock frequency
			if (cpolpha < 2)
				cpolpha++;
			else
				cpolpha = 2'b0;
			temp_regs[1:0] = cpolpha [1:0];	//Change CPOL, CPHA
		end // repeat
	end // while
	wait_for_end();
	report();
	
endtask : run_clk_freq


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
