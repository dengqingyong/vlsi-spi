class base_test extends uvm_test;
//optional - declare tb class here or in actual test
master_host_demo_tb tb0;
bit test_pass;
`uvm_component_utils(base_test)

function new(string name, uvm_component parent);
   super.new(name,parent);
endfunction : new

virtual function void build_phase(uvm_phase phase);
  super.build_phase(phase);
  uvm_config_db#(int)::set(this,"*","recording_detail",UVM_FULL);
  tb0=master_host_demo_tb::type_id::create("tb0",this);
endfunction : build_phase

// -- uncomment code to illustrate how to enable logging UVM_INFO messages to a file;
// virtual function void end_of_elaboration_phase(uvm_phase phase);
//   UVM_FILE fh;
//   super.end_of_elaboration_phase(phase);
//   fh=$fopen("log.dat");
//   uvm_top.set_report_severity_file_hier(UVM_INFO,fh);
//   uvm_top.set_report_severity_action_hier(UVM_INFO, UVM_LOG);
// endfunction : end_of_elaboration_phase

	virtual function void start_of_simulation_phase(uvm_phase phase);
	  super.start_of_simulation_phase(phase);
	  uvm_top.print_topology();
	endfunction : start_of_simulation_phase

	task run_phase(uvm_phase phase);
	  //run_phase of test not needed for this test
	  `uvm_info(get_type_name(),"Run Phase RUNNING",UVM_LOW)
	  //set a drain-time for the environment if desired
	  phase.phase_done.set_drain_time(this, 50);
	endtask : run_phase

	function void extract_phase(uvm_phase phase);
		if(tb0.master_host0.scoreboard0.sbd_error == 1'b0)
			test_pass = 1'b1;
		else
			test_pass = 1'b0;
	endfunction // void
  
  function void report_phase(uvm_phase phase);
    if(test_pass) begin
      `uvm_info(get_type_name(), "** UVM TEST PASSED **", UVM_NONE)
    end
    else begin
      `uvm_error(get_type_name(), "** UVM TEST FAIL **")
    end
  endfunction

endclass : base_test 

class test1 extends base_test;
`uvm_component_utils(test1)

function new(string name, uvm_component parent);
   super.new(name,parent);
endfunction : new

virtual function void build_phase(uvm_phase phase);
  `uvm_info(get_type_name(),"Build Phase of TEST1",UVM_LOW)
  //configure sequences for "reset_phase" and "main_phase" - will run sequentially in appropriate phase
  //uvm_config_db#(uvm_object_wrapper)::set(this, "tb0.master_host0.agent0.sequencer.reset_phase","default_sequence",master_host_reset_seq::type_id::get());
  uvm_config_db#(uvm_object_wrapper)::set(this, "tb0.master_host0.agent0.sequencer.main_phase","default_sequence",master_host_seq_full_burst::type_id::get());
  uvm_config_db#(int)::set(this,"tb0.master_host0.agent0","is_active",UVM_ACTIVE);
  uvm_config_db#(int)::set(this, "tb0.master_host0.agent0.sequencer", "count", 10);
  //NEED to set configurations before calling super.build_phase() which creates the verification hierarchy "tb0"
  super.build_phase(phase);
endfunction : build_phase
endclass : test1 


// class test2 extends base_test;
// `uvm_component_utils(test2)

// function new(string name, uvm_component parent);
   // super.new(name,parent);
// endfunction : new

// virtual function void build_phase(uvm_phase phase);
  // //configure sequences for "reset_phase" and "main_phase - will run sequentially in appropriate phase"
  // uvm_config_db#(uvm_object_wrapper)::set(this, "tb0.master_host0.agent0.sequencer.reset_phase","default_sequence",master_host_reset_seq::type_id::get());
  // uvm_config_db#(uvm_object_wrapper)::set(this, "tb0.master_host0.agent0.sequencer.main_phase","default_sequence",master_host_seq_full_burst::type_id::get());
  // uvm_config_db#(int)::set(this,"tb0.master_host0.agent0","is_active",UVM_ACTIVE);
  // //NEED to set configurations before calling super.build_phase() which creates the verification hierarchy "tb0"
  // super.build_phase(phase);
// endfunction : build_phase
// endclass : test2 
