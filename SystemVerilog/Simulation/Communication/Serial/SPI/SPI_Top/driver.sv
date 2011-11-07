`ifndef GUARD_DRIVER
`define GUARD_DRIVER
`include "globals.sv"
`include "packet.sv"
// `include "rand_inputs.sv"

class dr_packet extends packet;

	constraint long { data.size > 9 ; }
	
endclass

class Driver;

	virtual spi_master_interface.SPI_MASTER  master_intf;
	mailbox drvr_tx2sb;	//Transmitted data
	mailbox drvr_rx2sb;	//Received data
	event end_burst;
	dr_packet gpkt;
	int receiver_num;

//// constructor method ////
function new (virtual spi_master_interface.SPI_MASTER  master_intf_new, mailbox drvr_tx2sb, mailbox drvr_rx2sb);

	this.master_intf    = master_intf_new  ;
	
	if ((drvr_tx2sb == null) || (drvr_rx2sb == null))
	begin
		$display(" **ERROR**: Driver mailbox is null");
		$finish;
	end // if
	else
	begin
		this.drvr_tx2sb = drvr_tx2sb;
		this.drvr_rx2sb = drvr_rx2sb;
	end //else
	gpkt = new();
	
endfunction : new  

/// method to send the packet to DUT ////////
task tx();
	dr_packet pkt;
	pkt = new gpkt;
  
	repeat(num_of_pkts)	//Transmit 'num_of_pkts' bursts
	begin
		//Simulate FIFO Empty
		master_intf.fifo_empty		<=	1;
		master_intf.fifo_din_valid	<=	0;
		master_intf.fifo_din		<=	'{default:(0)};
	 
		repeat(19) @(posedge master_intf.clk);	//Wait for 20 clocks, before initializing transmission
		master_intf.fifo_empty		<=	0;		//Negate FIFO Empty

		//// Randomize the packet /////
		if ( pkt.randomize())
		begin
			receiver_num = pkt.spi_ss;
			$display (" %0d : Driver : Transmitting packet:",$time);
			//// display the packet content ///////
			pkt.display();
			master_intf.spi_slave_addr	<=	pkt.spi_ss;
			/////  send the packed bytes //////
			foreach(pkt.data[i])
			begin
				if (master_intf.fifo_req_data == 0)
				begin
					wait (master_intf.fifo_req_data);	//Wait for Request Data from FIFO
					@(posedge master_intf.clk);
				end // if
				master_intf.fifo_din_valid	<=	1;
				master_intf.fifo_din		<=	pkt.data[i]; 
				@(posedge master_intf.clk);
				master_intf.fifo_din_valid	<=	0;
			end // foreach
  
			//Simulate FIFO Empty - End of burst
			master_intf.fifo_empty		<=	1;
			master_intf.fifo_din_valid	<=	0;
			master_intf.fifo_din		<=	'{default:0};
  
			//// Push the packet in to mailbox for scoreboard /////
			drvr_tx2sb.put(pkt);
			repeat(2) @(posedge master_intf.clk);
			@(negedge master_intf.busy);	//To ensure that last dout_valid from SPI Master has been asserted
			repeat(1) @(posedge master_intf.clk);	//In case BUSY negates with DOUT_VALID at the same clock
			if (master_intf.dout_valid)
				@(negedge master_intf.dout_valid);
				
			->end_burst;
			$display(" %0d : Driver : Finished Driving the packet with length %0d",$time,pkt.data.size); 
		end // if ( pkt.randomize())
		else
		begin
			$display (" %0d Driver : ** Randomization failed. **",$time);
			////// Increment the error count in randomization fails ////////
			error++;
		end // else
	end // repeat(num_of_pkts)
	
endtask : tx


/// method to read the packets from DUT ////////
task rx();
	packet pkt;
	logic [data_width_c - 1:0] bytes[];
  
	forever
	begin
		@(end_burst or posedge master_intf.dout_valid or negedge master_intf.rst);	//Wait for end of burst or New Data / Reset
		if (master_intf.dout_valid) //New Data
		begin
			bytes = new[bytes.size + 1](bytes);
			bytes[bytes.size - 1] = master_intf.dout;
		end // if
		else
		begin					//End of burst
			pkt = new();
			pkt.data = new[bytes.size];
			foreach(bytes[i])
			begin
				pkt.data[i] = bytes[i];
			end // foreach
			$display ("Driver received packet:");
			pkt.display();
			drvr_rx2sb.put(pkt);	//Place in Scoreboard
			bytes.delete();
		end // else
	end // forever
	
endtask : rx

/// Method to de-activate the driver and the receiver ///
task finish(ref bit drvr_finish, ref int rec_num);
	@(end_burst);
	drvr_finish = 1;
	rec_num	= receiver_num;
	$display (" %0d Driver : Activated test finish process",$time);
endtask : finish

endclass

`endif

