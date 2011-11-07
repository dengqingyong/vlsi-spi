`ifndef GUARD_PACKET
`define GUARD_PACKET
`include "globals.sv"

class packet;

	rand logic [data_width_c - 1:0] data[];						//Payload using Dynamic array,size is generated on the fly
	rand int spi_ss; //SPI Slave Select

	constraint spi_ss_addr_c {spi_ss < bits_of_slaves_c && spi_ss >= 0;}

	constraint payload_size_c { data.size inside { [1 : payload_max_len_c]};}

	//Use of 0xFF data
	//constraint payload_data_c { foreach (data[i]) data[i] == {data_width_c{1'b1}};}

	//Use of 0x00 data
	//constraint payload_data_c { foreach (data[i]) data[i] == {data_width_c{0'b1}};}


///// method to print the packet fields ////
virtual function void display();
	$display("\n---------------------- Packet Information ------------------------- ");
	$display("Packet Length is : %d ",data.size);
	$display("\nPacket data: ");
	foreach(data[i]) 
		$write("%3d : %0h ",i ,data[i]);
	$display("\nPacket slave number: %d", spi_ss);
	$display("\n----------------------------------------------------------- \n");
	
endfunction : display

//// method to compare the packet: sent from spi master /////
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

//// method to compare the packet: sent from spi slave /////
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
				if (default_data_c !== this.data[i])
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
