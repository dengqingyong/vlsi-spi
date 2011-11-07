class master_host_agent extends uvm_agent;

uvm_active_passive_enum is_active;
master_host_sequencer sequencer;
master_host_driver driver;
master_host_monitor monitor;

`uvm_component_utils_begin(master_host_agent)
  `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_ALL_ON)
`uvm_component_utils_end

function new(string name, uvm_component parent);
   super.new(name,parent);
endfunction : new

virtual function void build_phase(uvm_phase phase);
  super.build_phase(phase);
  monitor=master_host_monitor::type_id::create("monitor",this);
  if (is_active == UVM_ACTIVE)
    begin
      driver=master_host_driver::type_id::create("driver",this);
      sequencer=master_host_sequencer::type_id::create("sequencer",this);
    end
endfunction : build_phase

virtual function void connect_phase(uvm_phase phase);
  super.connect_phase(phase);
  if (is_active == UVM_ACTIVE)
    begin
      driver.seq_item_port.connect(sequencer.seq_item_export);
    end
endfunction : connect_phase

endclass : master_host_agent 
