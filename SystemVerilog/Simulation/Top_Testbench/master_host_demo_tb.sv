class master_host_demo_tb extends uvm_env;

master_host_env master_host0;
`uvm_component_utils(master_host_demo_tb)

function new(string name, uvm_component parent);
   super.new(name,parent);
endfunction : new

virtual function void build_phase(uvm_phase phase);
  super.build_phase(phase);
  master_host0=master_host_env::type_id::create("master_host0",this);
endfunction : build_phase

endclass : master_host_demo_tb 
