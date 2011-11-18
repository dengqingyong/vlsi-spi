parameter num_counts_g	= 600;	//Number of executed sequences

//basic sequence (calls an item)
class master_host_base_seq extends uvm_sequence #(packet);
	string tID;
	`uvm_object_utils(master_host_base_seq)
	//declare a p_sequencer pointer to sequencer (optional if needed)
	`uvm_declare_p_sequencer(master_host_sequencer)

	function new(string name = "master_host_base_seq");
	   super.new(name);
	   tID=get_type_name();
	   tID=tID.toupper();
	endfunction : new

	virtual task pre_body();
	  if(starting_phase != null) starting_phase.raise_objection(this,get_type_name());
	endtask :  pre_body

	virtual task post_body();
	  if(starting_phase != null) starting_phase.drop_objection(this,get_type_name());
	endtask :  post_body

endclass : master_host_base_seq

//basic sequence (calls an item)
class master_host_seq1 extends master_host_base_seq;
	//"req" built-in uvm_sequence class member for sequence_item

	`uvm_object_utils(master_host_seq1)
	   
	function new(string name = "master_host_seq1");
	   super.new(name);
	endfunction : new

	virtual task body();
		`uvm_info(tID,"General sequence RUNNING",UVM_MEDIUM)
		`uvm_do(req)
	endtask : body
endclass : master_host_seq1 

//Full burst write sequence
class master_host_seq_full_burst extends master_host_base_seq;
	//"req" built-in uvm_sequence class member for sequence_item

	`uvm_object_utils(master_host_seq_full_burst)
	function new(string name = "master_host_seq_full_burst");
	   super.new(name);
	endfunction : new

	virtual task body();
		`uvm_info(tID,"FULL BURST sequence RUNNING",UVM_MEDIUM)
		for (int idx = 0 ; idx < 4 ; idx++)
			`uvm_do_with(req, {length == 8'hFF; wr_rd == 1; init_addr == idx*256;} )
		`uvm_info(tID,"END FULL BURST sequence",UVM_MEDIUM)
	endtask : body
endclass : master_host_seq_full_burst 

//Simple Read
class master_host_read_burst extends master_host_base_seq;
	//"req" built-in uvm_sequence class member for sequence_item

	`uvm_object_utils(master_host_read_burst)
	function new(string name = "master_host_read_burst");
	   super.new(name);
	endfunction : new

	virtual task body();
		`uvm_info(tID,"Read sequence RUNNING",UVM_MEDIUM)
		`uvm_do_with(req, {wr_rd == 0;} )
		`uvm_info(tID,"End Read",UVM_MEDIUM)
	endtask : body
endclass : master_host_read_burst 


// //sequence which calls another sequence (sub_sequence)
// class master_host_seq2 extends master_host_base_seq;
// //"req" built-in uvm_sequence class member for sequence_item
// rand int sd1;
// rand int sd2;
// rand int scnt;
// constraint d1 {sd1 inside {[15:25]};}
// constraint d2 {sd2 inside {[10:20]};}
// constraint s1 {scnt inside {[4:10]};}

// `uvm_object_utils_begin(master_host_seq2)
   // `uvm_field_int(sd1,UVM_ALL_ON + UVM_DEC)
   // `uvm_field_int(sd2,UVM_ALL_ON + UVM_DEC)
   // `uvm_field_int(scnt,UVM_ALL_ON + UVM_DEC)
// `uvm_object_utils_end

// function new(string name = "master_host_seq2");
   // super.new(name);
// endfunction : new

// master_host_seq1 es1;
// virtual task body();
  // `uvm_info(tID,"sequence RUNNING",UVM_MEDIUM)
  // //not the best way to print, just to confirm randomization
  // `uvm_info(tID,$sformatf("sd1=%0d, sd2=%0d", sd1, sd2),UVM_MEDIUM);
  // for (int i=1; i<scnt; i++)
    // begin
      // #sd1  //dummy delay to illustrate a sequence rand variable
      // `uvm_do(es1) //send sub-sequence
      // #sd2;
    // end
  // `uvm_info(tID,"sequence COMPLETE",UVM_MEDIUM)
// endtask : body
// endclass : master_host_seq2 

class master_host_reset_seq  extends master_host_base_seq;
	//"req" built-in uvm_sequence class member for sequence_item
	`uvm_object_utils(master_host_reset_seq)

	function new(string name = "master_host_reset_seq");
	   super.new(name);
	endfunction : new

	virtual task body();
	  `uvm_info(tID,"RUNNING a dummy reset sequence in the reset phase",UVM_MEDIUM)
	  `uvm_info(tID,"  sequence is transmitted in the regular driver",UVM_MEDIUM)
	   #5;
	   //`uvm_do(req) //send dummy reset sequence 
	   #5
	  `uvm_info(tID,"sequence COMPLETE",UVM_MEDIUM)
	endtask : body
endclass : master_host_reset_seq 

//basic sequence (calls an item)
class master_host_ex_seq extends master_host_base_seq;
	//"req" built-in uvm_sequence class member for sequence_item

	`uvm_object_utils(master_host_ex_seq)
	int count = num_counts_g;
	   
	function new(string name = "master_host_ex_seq");
	   super.new(name);
	endfunction : new

	virtual task body();
		//`uvm_info(tID,"General sequence RUNNING",UVM_MEDIUM)
		//Declare sequences
		master_host_seq_full_burst 	full_burst_seq;
		master_host_seq1			general_burst_seq;
		master_host_read_burst		read_burst_seq;
		
		//Initilize full burst
		`uvm_do(full_burst_seq)
		//Execute random bursts:
		for (int idx = 0 ; idx < count; idx++)
		begin
			fork
				`uvm_do(general_burst_seq)
				`uvm_do(read_burst_seq)
			join
		end;
	endtask : body
endclass : master_host_ex_seq 

//additional sequences can be included in this file
