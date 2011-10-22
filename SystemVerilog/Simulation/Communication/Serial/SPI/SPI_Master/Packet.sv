`ifndef GUARD_PACKET
`define GUARD_PACKET
`include "Globals.sv"
class packet;

rand logic [data_width_c - 1:0] data[];						//Payload using Dynamic array,size is generated on the fly
randc logic [bits_of_slaves_c - 1 : 0] spi_ss; //SPI Slave Select

constraint payload_size_c { data.size inside { [1 : payload_max_len_c]};}

//Use of 0xFF data
//constraint payload_data_c { foreach (data[i]) data[i] == {data_width_c{1'b1}};}

//Use of 0x00 data
//constraint payload_data_c { foreach (data[i]) data[i] == {data_width_c{0'b1}};}


///// method to print the packet fields ////
virtual function void display();
  $display("\n---------------------- Packet Information ------------------------- ");
  $display("Packet Length is : %d ",data.size);
  foreach(data[i]) 
	$write("%3d : %0h ",i ,data[i]); 
  $display("\n----------------------------------------------------------- \n");
endfunction : display


//// method to compare the packets /////
virtual function bit compare(packet pkt);
compare = 1;
if(pkt == null)
   begin
      $error(" ** ERROR ** : pkt : received a null object ");
      compare = 0;
   end
   else
      begin
         foreach(this.data[i])
         if(pkt.data[i] !== this.data[i])
         begin
            $error(" ** ERROR **: pkt : Data[%0d] field did not match (%h) != (%h)",i, pkt.data[i], this.data[i]);
            compare = 0;
         end
      end
endfunction : compare

endclass

`endif
