`ifndef GUARD_DRIVER
`define GUARD_DRIVER
`include "globals.sv"
`include "packet.sv"
`include "master_bfm.sv"

//`timescale 1ps/1ps

class Driver; //SPI MASTER

virtual slave_spi_interface.SLAVE_SPI  spi_intf;
mailbox drvr_tx2sb;	//Transmitted data
mailbox drvr_rx2sb;	//Received data
event end_burst;
bit end_trans; // 0 - Transmittion is ACTIVE
			  // 1 - Transmittion is FINISHED
packet gpkt;
master_bfm spi_master;

//// constructor method ////
function new(virtual slave_spi_interface.SLAVE_SPI spi_intf_new, mailbox drvr_tx2sb, mailbox drvr_rx2sb);
  this.spi_intf  = spi_intf_new  ;
  if((drvr_tx2sb == null) || (drvr_rx2sb == null))
  begin
    $display(" **ERROR**: Driver mailbox is null");
    $finish;
  end
  else
  begin
    this.drvr_tx2sb = drvr_tx2sb;
    this.drvr_rx2sb = drvr_rx2sb;
  end // else
  gpkt = new();
  spi_master = new(spi_intf_new);
  end_trans = 0;
endfunction : new  

/// method to send the packet to DUT ////////
task start();
  packet pkt;
  packet rec_pkt;
  logic [data_width_c - 1:0] dout;
  logic [data_width_c - 1:0] rec_data[];
  
  pkt = new gpkt;
  
  //// Randomize the packet /////
  if ( pkt.randomize())
    begin
		$display (" %0d : Driver : Randomization Successesfull.",$time);
		//// display the packet content ///////
		pkt.display();
	
		repeat (4) @(posedge spi_intf.clk);
		foreach (pkt.data[i])	//Transmit all of the data words
		begin
			spi_master.start(pkt.data[i], pkt.burst_mode[i], pkt.delay[i], pkt.freq, dout);
			rec_data = new[rec_data.size + 1](rec_data);
			rec_data[rec_data.size - 1] = dout;
		end // foreach	
		spi_master.finish();
		
       //// Push the packet transmitted into mailbox for scoreboard /////
       drvr_tx2sb.put(pkt);
	   $display(" %0d : Driver : Finished Driving the packet with length %0d",$time,pkt.data.size); 
	   pkt.display();
	   
	   //// Push the packet received into the mailbox for scoreboard ////
		rec_pkt = new();
		rec_pkt.data = new[rec_data.size];
		foreach(rec_data[i])
		begin
			rec_pkt.data[i] = rec_data[i];
		end // foreach
		drvr_rx2sb.put(rec_pkt);	//Place in Scoreboard
		$display(" %0d : Driver : Finished receiving the packet with length %0d",$time,rec_pkt.data.size); 
		rec_pkt.display();
		rec_data.delete();
	   
	   repeat (5) @(posedge spi_intf.clk);	//To ensure that last dout_valid from SPI Slave has been asserted
	   ->end_burst;
	   $display (" %0d Driver : Activated event end_burst",$time);
       
     end // randomize successfull
   else
     begin
        $display (" %0d Driver : ** Randomization failed. **",$time);
        ////// Increment the error count in randomization fails ////////
        error++;
    end
	
endtask : start

/// Method to de-activate the driver and the receiver ///
task finish(ref bit drvr_finish);
	@(end_burst);
	end_trans = 1;
	drvr_finish = 1;
	$display (" %0d Driver : Activated test finish process",$time);
endtask : finish

endclass

`endif
