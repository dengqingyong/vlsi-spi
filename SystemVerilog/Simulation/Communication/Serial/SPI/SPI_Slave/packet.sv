`ifndef GUARD_PACKET
`define GUARD_PACKET
`include "globals.sv"

//`timescale 1ps/1ps

class packet;

rand logic [data_width_c - 1:0] data[];	//Payload using Dynamic array, size is generated on the fly
rand logic burst_mode[]; //0 - the SS is deasserted and ends the current transaction
						//1 - the SS remains active, and next transaction starts immediately
rand logic [3:0] delay[];//Number of delay cycles between transactions
rand logic [3:0] freq; //spi_clk frequency 

constraint payload_size_c { data.size inside { [1 : payload_max_len_c]};}

constraint freq_c { freq inside {[2:15]}; }

constraint burst_mode_c { burst_mode.size == data.size;}

constraint delay_c { 
	delay.size == data.size;
	foreach (delay[i])
		delay[i] inside {[1:15]};}
	
constraint data_delay_c { solve data before burst_mode; }

constraint solve_burst_delay { solve burst_mode before delay; }
	

///// method to print the packet fields ////
virtual function void display();
  $display("\n---------------------- Packet Information ------------------------- ");
  $display("Packet Length is : %d ",data.size);
  $display("Packet data: \n");
  foreach(data[i]) 
	$write("%3d : %0h ",i ,data[i]); 
  $display("Packet Burst mode: \n");
  foreach(burst_mode[i]) 
	$write("%3d : %0h ",i ,burst_mode[i]); 
  $display("Packet delay time: \n");
  foreach(delay[i]) 
	$write("%3d : %0h ",i ,delay[i]); 
  $write("Packet spi_clk frequency : %0h ",freq); 
  $display("\n----------------------------------------------------------- \n");
endfunction : display

//// method to compare the packet: sent from spi master - received by slave host /////
virtual function bit compare1(packet pkt);
	compare1 = 1;
	if(pkt == null)
	begin
		$display(" ** ERROR ** : pkt : received a null object ");
		compare1 = 0;
	end // if
	else
    begin
        foreach(this.data[i])
			if(pkt.data[i] !== this.data[i])
			begin
				$display(" ** ERROR **: pkt : Data[%0d] field did not match",i);
				compare1 = 0;
			end // if
    end // else
endfunction : compare1

//// method to compare the packet: sent from slave host - received by spi master /////
virtual function bit compare2(packet pkt);
	compare2 = 1;
	if(pkt == null)
	begin
		$display(" ** ERROR ** : pkt : received a null object ");
		compare2 = 0;
	end // if
	else
	begin
		foreach(this.data[i])
		begin
			if (i < pkt.data.size)
			begin	
				if(pkt.data[i] !== this.data[i])
				begin
					$display(" ** ERROR **: pkt : Data[%0d] field did not match",i);
					compare2 = 0;
				end // if
			end // if
			else
			begin
				if(default_data_c !== this.data[i])
				begin
					$display(" ** ERROR **: pkt : Data[%0d] field did not match",i);
					compare2 = 0;
				end // if
			end // else
		end // foreach
	end // else
endfunction : compare2

endclass

`endif