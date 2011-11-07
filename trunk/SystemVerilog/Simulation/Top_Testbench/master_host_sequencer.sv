class master_host_sequencer extends uvm_sequencer #(packet);

  `uvm_component_utils(master_host_sequencer)

function new(string name, uvm_component parent);
  super.new(name,parent);
endfunction : new

endclass : master_host_sequencer 
