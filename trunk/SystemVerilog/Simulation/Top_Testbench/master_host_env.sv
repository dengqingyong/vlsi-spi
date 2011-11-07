class master_host_env extends uvm_env;

master_host_agent agent0;
`uvm_component_utils(master_host_env)

function new(string name, uvm_component parent);
   super.new(name,parent);
endfunction : new

virtual function void build_phase(uvm_phase phase);
  super.build_phase(phase);
  agent0=master_host_agent::type_id::create("agent0",this);
endfunction : build_phase

endclass : master_host_env 
