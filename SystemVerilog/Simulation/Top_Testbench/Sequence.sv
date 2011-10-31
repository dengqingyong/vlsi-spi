`ifndef GUARD_SEQUENCE
`define GUARD_SEQUENCE

class Seq_wbm extends uvm_sequence #(Packet);

     function new(string name = "Seq_wbm");
         super.new(name);
     endfunction : new
 
     Packet item;
 
     `uvm_sequence_utils(Seq_wbm, Sequencer)    

     virtual task body();
        forever begin
         `uvm_do_with(item, { init_addr + data.size < 2**addr_width_g; } ); 
        end
     endtask : body
  
endclass : Seq_wbm

class Seq_max_wr_burst extends uvm_sequence #(Packet);

     function new(string name = "Seq_max_wr_burst");
         super.new(name);
     endfunction : new
 
     Packet item;
 
     `uvm_sequence_utils(Seq_max_wr_burst, Sequencer)    

     virtual task body();
        forever begin
         `uvm_do_with(item, {length == '{default:1}; wr_rd == 1;} ); 
        end
     endtask : body
  
endclass : Seq_max_wr_burst

`endif