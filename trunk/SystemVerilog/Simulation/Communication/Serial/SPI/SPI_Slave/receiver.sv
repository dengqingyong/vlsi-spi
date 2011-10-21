`ifndef GUARD_RECEIVER
`define GUARD_RECEIVER
`include "globals.sv"
`include "packet.sv"

class Receiver;	//Slave Host

virtual slave_host_interface.SLAVE_HOST host_intf;
mailbox rcvr_rx2sb;
mailbox rcvr_tx2sb;
bit end_trans // 0 - Transmittion is ACTIVE
			  // 1 - Transmittion is FINISHED
packet gpkt;

//// constructor method ////
function new(virtual slave_host_interface.SLAVE_HOST  host_intf_new, 
			mailbox rcvr_tx2sb, mailbox rcvr_rx2sb);
			
   this.host_intf = host_intf_new  ;
   if((rcvr_rx2sb == null) || (rcvr_tx2sb == null)
   begin
     $display(" **ERROR**: Receiver mailbox is null");
     $finish;
   end // if 
   else
   begin
	this.rcvr_tx2sb = rcvr_tx2sb;
	this.rcvr_rx2sb = rcvr_rx2sb;
   end // else
   gpkt = new();
   this.end_trans = 0;
   
endfunction : new  

/// Method to transmit the data from the slave host
task tx();

	packet pkt;
	int i;
	int length;

	i = 0;
	pkt = new gpkt;	
	
	 //// Randomize the packet /////
	if ( pkt.randomize())
    begin
		$display (" %0d : Receiver : Randomization Successesfull.",$time);
		//// display the packet content ///////
		pkt.display();
		//// calculate the number of words ////
		length = pkt.data.size;
		
		while (end_trans == 0)
		begin
			if (i < length) then //pkt has data to return
			begin
				host_intf.fifo_empty	<=	0;
				wait(host_intf.fifo_req_data == 1 or end_trans == 1);
				if (host_intf.fifo_req_data == 1)
				begin
					@(posedge host_intf.clk);
					host_intf.fifo_din_valid	<=	1;
					host_intf.fifo_din			<=	pkt.data[i];
					@(posedge host_intf.clk);
					host_intf.fifo_din_valid	<=	0;
					host_intf.fifo_din			<=	0;
				end // if
			end // if
			else // FIFO has no data
			begin
				host_intf.fifo_empty	<=	1;
				wait(end_trans == 1);
			end // else
			i	<=	i + 1;
		end // while
		
		//// Push the packet in to mailbox for scoreboard /////
		rcvr_tx2sb.put(pkt);
		$display(" %0d : Receiver : Finished Driving the packet with length %0d",$time,pkt.data.size); 
	end // randomize successfull
	else
    begin
        $display (" %0d Receiver : ** Randomization failed. **",$time);
        ////// Increment the error count in randomization fails ////////
        error++;
    end // else
	
endtask : tx

/// Method to receive the data sent to the slave host
task rx();

	packet pkt;
	logic bytes[];

	while (end_trans == 0)
	begin
		wait(host_intf.dout_valid == 1 or end_trans == 1);	//Wait for New Data
		if (host_intf.dout_valid == 1)
		begin
			bytes = new[bytes.size + 1](bytes);
			bytes[bytes.size - 1] = host_intf.dout;
		end // if
		wait(posedge host_intf.clk and host_intf.dout_valid == 0);
	end // while
	
	/// Generate the packet and send it to the scoreboard  ///
	pkt = new();
	pkt.data = new[bytes.size](bytes);
	rcvr_rx2sb.put(pkt);	//Place in Scoreboard
	$display(" %0d : Receiver : Finished receiving the packet with length %0d",$time,pkt.data.size); 
	pkt.display();
	bytes.delete();
	
endtask : rx

/// Method to de-activate the receiver and send the packets to the scoreboard ////
task finish();
begin
	end_trans = 1;
endtask : finish
