`ifndef GUARD_DRIVER
`define GUARD_DRIVER
`include "globals.sv"
`include "packet.sv"
`include "master_bfm.sv"

class Driver; //SPI MASTER

virtual slave_spi_interface.SLAVE_SPI  spi_intf;
mailbox drvr_tx2sb;	//Transmitted data
mailbox drvr_rx2sb;	//Received data
event end_burst;
bit end_trans // 0 - Transmittion is ACTIVE
			  // 1 - Transmittion is FINISHED
packet gpkt;
master_bfm spi_master;

//// constructor method ////
function new(virtual slave_spi_interface.SLAVE_SPI spi_intf_new, mailbox drvr_tx2sb, mailbox drvr_rx2sb);
  this.spi_intf  = spi_intf_new  ;
  if((drvr_tx2sb == null) or (drvr_rx2sb == null))
  begin
    $display(" **ERROR**: Driver mailbox is null");
    $finish;
  end
  else
  this.drvr_tx2sb = drvr_tx2sb;
  this.drvr_rx2sb = drvr_rx2sb;
  gpkt = new();
  spi_master = new(spi_intf_new);
  end_trans = 0;
endfunction : new  

/// method to send the packet to DUT ////////
task start();
  packet pkt;
  packet rec_pkt;
  bit [7:0] dout;
  bit [7:0] rec_data [];
  
  pkt = new gpkt;
  
  //// Randomize the packet /////
  if ( pkt.randomize())
    begin
		$display (" %0d : Driver : Randomization Successesfull.",$time);
		//// display the packet content ///////
		pkt.display();
	
		foreach (pkt.data[i])	//Transmit all of the data words
		begin
			dout = spi_master.start(pkt.data[i], pkt.burst_mode[i], pkt.delay[i], pkt.freq);
			rec_data = new[rec_data.size + 1](rec_data);
			rec_data[rec_data.size - 1] = dout;
		end // foreach	
		
       //// Push the packet transmitted into mailbox for scoreboard /////
       drvr_tx2sb.put(pkt);
	   $display(" %0d : Driver : Finished Driving the packet with length %0d",$time,pkt.data.size); 
	   pkt.display();
	   
	   //// Push the packet received into the mailbox for scoreboard ////
		rec_pkt = new();
		rec_pkt.data = new[rec_data.size](rec_data);
		drvr_rx2sb.put(rec_pkt);	//Place in Scoreboard
		$display(" %0d : Driver : Finished receiving the packet with length %0d",$time,rec_pkt.data.size); 
		rec_pkt.display();
		rec_data.delete();
	   
	   repeat(5) @(posedge spi_intf.clk);	//To ensure that last dout_valid from SPI Slave has been asserted
	   ->end_burst;
       
     end // randomize successfull
   else
     begin
        $display (" %0d Driver : ** Randomization failed. **",$time);
        ////// Increment the error count in randomization fails ////////
        error++;
    end
	
endtask : start

/// Method to de-activate the driver and the receiver ///
function integer finish();
begin
	@(end_burst)
	end_trans = 1;
	return 1;
endfunction : finish

endclass

`endif