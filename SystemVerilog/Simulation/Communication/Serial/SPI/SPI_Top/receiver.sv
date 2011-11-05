`ifndef GUARD_RECEIVER
`define GUARD_RECEIVER
`include "globals.sv"
`include "packet.sv"

//`timescale 1ps/1ps

class re_packet extends packet;

	constraint short { data.size < 10 ; }
	
endclass

class Receiver;	//Slave Host

	virtual spi_slave_interface.SPI_SLAVE slave_intf;
	mailbox rcvr_rx2sb;
	mailbox rcvr_tx2sb;
	bit end_trans; // 0 - Transmittion is ACTIVE
				// 1 - Transmittion is FINISHED
	re_packet gpkt;
	int receiver_sernum;	//Serial Number

//// constructor method ////
function new (virtual spi_slave_interface.SPI_SLAVE  slave_intf_new, mailbox rcvr_tx2sb, mailbox rcvr_rx2sb,
				int receiver_sernum_new);
			
	this.slave_intf = slave_intf_new  ;
	if ((rcvr_rx2sb == null) || (rcvr_tx2sb == null))
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
	this.receiver_sernum	= receiver_sernum_new;
   
endfunction : new  

/// Method to transmit the data from the slave host
task tx();

	re_packet pkt;
	int i;
	int length;
	pkt = new gpkt;	
	
	forever
	begin
		i = 0;
		//// Randomize a packet /////
		if ( pkt.randomize())
		begin
			$display (" %0d : Receiver %d: Randomization Successesfull.",$time, receiver_sernum);
			pkt.spi_ss	=	receiver_sernum;
			//// display the packet content ///////
			pkt.display();
			//// calculate the number of words ////
			length = pkt.data.size;
		
			while (end_trans == 0)
			begin
				if (i < length) //pkt has data to return
				begin
					slave_intf.fifo_empty	<=	0;
					wait(slave_intf.fifo_req_data == 1 || end_trans == 1);
					if (slave_intf.fifo_req_data == 1)
					begin
						@(posedge slave_intf.clk);
						slave_intf.fifo_din_valid	<=	1;
						slave_intf.fifo_din			<=	pkt.data[i];
						@(posedge slave_intf.clk);
						slave_intf.fifo_din_valid	<=	0;
					end // if
				end // if
				else // FIFO has no data
				begin
					slave_intf.fifo_empty	<=	1;
					wait(end_trans == 1);
				end // else
				i	=	i + 1;
			end // while
		
			//// Push the packet in to mailbox for scoreboard /////
			rcvr_tx2sb.put(pkt);
			$display(" %0d : Receiver %d: Finished Driving the packet with length %0d",$time,receiver_sernum,pkt.data.size);

			//// Allow new transmition to start
			end_trans = 0;
			
		end // randomize successfull
		else
		begin
			$display (" %0d Receiver : ** Randomization failed. **",$time);
			////// Increment the error count in randomization fails ////////
			error++;
		end // else
	end // forever
	
endtask : tx

/// Method to receive the data sent to the slave host
task rx();

	packet pkt;
	logic [data_width_c - 1:0] bytes[];

	forever
	begin
		while (end_trans == 0)
		begin
			wait(slave_intf.dout_valid == 1 || end_trans == 1);	//Wait for New Data
			if (slave_intf.dout_valid == 1)
			begin
				bytes = new[bytes.size + 1](bytes);
				bytes[bytes.size - 1] = slave_intf.dout;
			end // if
			wait(slave_intf.clk && slave_intf.dout_valid == 0);
		end // while
	
		/// Generate the packet and send it to the scoreboard  ///
		pkt = new();
		pkt.data = new[bytes.size];
		foreach(bytes[i])
		begin
			pkt.data[i] = bytes[i];
		end // foreach
		pkt.spi_ss	=	receiver_sernum;
		rcvr_rx2sb.put(pkt);	//Place in Scoreboard
		$display(" %0d : Receiver %d: Finished receiving the packet with length %0d",$time,receiver_sernum,pkt.data.size); 
		pkt.display();
		bytes.delete();
	end // forever
	
endtask : rx

/// Method to de-activate the receiver and send the packets to the scoreboard ////
task finish();
	end_trans = 1;
endtask : finish

endclass

`endif
