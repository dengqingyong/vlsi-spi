`ifndef GUARD_PACKET
`define GUARD_PACKET

class packet;

rand byte data[];						//Payload using Dynamic array,size is generated on the fly
randc logic [bits_of_slaves_c - 1 : 0] spi_ss; //SPI Slave Select

constraint payload_size_c { data.size inside { [1 : payload_max_len_c]};}


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
      $display(" ** ERROR ** : pkt : received a null object ");
      compare = 0;
   end
   else
      begin
         foreach(this.data[i])
         if(pkt.data[i] !== this.data[i])
         begin
            $display(" ** ERROR **: pkt : Data[%0d] field did not match",i);
            compare = 0;
         end
      end
endfunction : compare

endclass

`endif
