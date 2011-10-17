`ifndef GUARD_DRIVER
`define GUARD_DRIVER
`include "Globals.sv"
`include "Packet.sv"

class Driver;
virtual spi_master_in_interface.MASTER_INPUT  in_intf;
mailbox drvr_tx2sb;	//Transmitted data
mailbox drvr_rx2sb;	//Received data
event end_burst;
packet gpkt;

//// constructor method ////
function new(virtual spi_master_in_interface.MASTER_INPUT  in_intf_new, 
			mailbox drvr_tx2sb, mailbox drvr_rx2sb);
  this.in_intf    = in_intf_new  ;
  if ((drvr_tx2sb == null) || (drvr_rx2sb == null))
  begin
    $display(" **ERROR**: Driver mailbox is null");
    $finish;
  end
  else
  this.drvr_tx2sb = drvr_tx2sb;
  this.drvr_rx2sb = drvr_rx2sb;
  gpkt = new();
endfunction : new  

/// method to send the packet to DUT ////////
task start();
  packet pkt;
  pkt = new gpkt;
  repeat(num_of_pkts)	//Transmit 'num_of_pkts' bursts
  begin
    //Simulate FIFO Empty
	in_intf.fifo_empty		<=	1;
	in_intf.fifo_din_valid	<=	0;
	in_intf.fifo_din		<=	'{default:(0)};
	 
	repeat(19) @(posedge in_intf.clk);	//Wait for 20 clocks, before initializing transmission
	in_intf.fifo_empty		<=	0;		//Negate FIFO Empty

    //// Randomize the packet /////
    if ( pkt.randomize())
     begin
       $display (" %0d : Driver : Randomization Successesfull.",$time);
       //// display the packet content ///////
       pkt.display();
          
       /////  send the packed bytes //////
       foreach(pkt.data[i])
       begin
	    in_intf.spi_slave_addr	<=	pkt.spi_ss;
		if (in_intf.fifo_req_data == 0)
		begin
			wait (in_intf.fifo_req_data);	//Wait for Request Data from FIFO
			@(posedge in_intf.clk);
		end
		in_intf.fifo_din_valid	<=	1;
		in_intf.fifo_din		<=	pkt.data[i];
		@(posedge in_intf.clk);
		in_intf.fifo_din_valid	<=	0;
       end 
  
		//Simulate FIFO Empty - End of burst
		in_intf.fifo_empty		<=	1;
		in_intf.fifo_din_valid	<=	0;
		in_intf.fifo_din		<=	'{default:0};
  
       //// Push the packet in to mailbox for scoreboard /////
       drvr_tx2sb.put(pkt);
	   repeat(5) @(posedge in_intf.clk);	//To ensure that last dout_valid from SPI Master has been asserted
	   ->end_burst;
       
       $display(" %0d : Driver : Finished Driving the packet with length %0d",$time,pkt.data.size); 
     end
     else
      begin
         $display (" %0d Driver : ** Randomization failed. **",$time);
         ////// Increment the error count in randomization fails ////////
         error++;
      end
  end
endtask : start

/// method to read the packets from DUT ////////
task rx();
  packet pkt;
  logic [data_width_c - 1:0] bytes[];
  repeat(num_of_pkts)	//Receive 'num_of_pkts' bursts
  begin
    @(end_burst or posedge in_intf.dout_valid);	//Wait for end of burst or New Data
	if (in_intf.dout_valid) //New Data
	begin
		bytes = new[bytes.size + 1](bytes);
		bytes[bytes.size - 1] = in_intf.dout;
	end
	else begin					//End of burst
		pkt = new();
		pkt.data = new[bytes.size + 1](bytes);
		drvr_rx2sb.put(pkt);	//Place in Scoreboard
		bytes.delete();
	end
  end
endtask : rx

endclass

`endif

