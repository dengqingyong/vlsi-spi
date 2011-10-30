// class Seq_wbm extends uvm_sequence #(Packet);

     // function new(string name = "Seq_wbm");
         // super.new(name);
     // endfunction : new
 
     // Packet item;
 
     // `uvm_sequence_utils(Seq_wbm, Sequencer)    

     // virtual task body();
        // // forever begin
         // // `uvm_do_with(item, {da == p_sequencer.cfg.device_add[0];} ); 
         // // `uvm_do_with(item, {da == p_sequencer.cfg.device_add[1];} ); 
        // // end
     // endtask : body
  
// endclass : Seq_wbm

class Seq_constant_length extends uvm_sequence #(Packet);

     function new(string name = "Seq_constant_length");
         super.new(name);
     endfunction : new
 
     Packet item;
 
     `uvm_sequence_utils(Seq_constant_length, Sequencer)    

     virtual task body();
        forever begin
         `uvm_do_with(item, {length == 10;} ); 
        end
     endtask : body
  
endclass : Seq_constant_length

