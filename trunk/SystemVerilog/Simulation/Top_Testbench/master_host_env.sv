class master_host_env extends uvm_env;

	master_host_agent agent0;
	
	// Scoreboard to check the memory operation of the slave.
	master_host_scoreboard scoreboard0;

	`uvm_component_utils(master_host_env)

	function new(string name, uvm_component parent);
	   super.new(name,parent);
	endfunction : new

	virtual function void build_phase(uvm_phase phase);
	  super.build_phase(phase);
	  agent0		=	master_host_agent::type_id::create("agent0",this);
	  scoreboard0	=	master_host_scoreboard::type_id::create("scoreboard0",this);
	endfunction : build_phase

	function void connect_phase(uvm_phase phase);
		// Connect slave0 monitor to scoreboard
		agent0.driver.sb_rx.connect(scoreboard0.sb_rx);
		agent0.driver.sb_ram.connect(scoreboard0.sb_ram);
		agent0.monitor.sb_post.connect(scoreboard0.sb_rx);
	endfunction : connect_phase

	
endclass : master_host_env 
