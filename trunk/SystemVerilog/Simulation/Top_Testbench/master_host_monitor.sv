class master_host_monitor extends uvm_monitor;

string tID;
virtual interface mh_intf vif;
packet trans;
event e_trans_collected; //event to signal transaction collected
//TLM port for scoreboard communication (implement scoreboard write method if needed)
uvm_analysis_imp #(packet, master_host_monitor) sb_post;

`uvm_component_utils_begin(master_host_monitor)
  `uvm_field_object(trans, UVM_ALL_ON)
`uvm_component_utils_end

virtual function void build_phase(uvm_phase phase);
  super.build_phase(phase);
  if(!uvm_config_db#(virtual mh_intf)::get(this,"","vif",vif))
    `uvm_fatal("NOVIF", {"virtual interface must be set for: ", get_full_name(),".vif"});
endfunction : build_phase

task run_phase(uvm_phase phase);
  `uvm_info(tID,"RUNNING:",UVM_MEDIUM)
endtask : run_phase

//shell code for covergroup
covergroup cov_trans @ e_trans_collected;
  length: coverpoint trans.length
   { 
	bins MIN[]     	= {0};
    bins MAX[]     	= {255};
	bins others[]	= {[1:254]};
   }
   
   init_addr: coverpoint trans.init_addr;

   div_factor: coverpoint trans.clk_reg
   {
	bins in_range[] = {[2:$]};
	bins others[]	= default;
   }

   cpol_cpha: coverpoint trans.conf_reg
   {
	bins in_range[] = {[0:3]};
	bins others[]	= default;
   }

//   lenXaddr: cross length, init_addr;
endgroup


//new() function needs to be listed last so other items defined
function new(string name, uvm_component parent);
  super.new(name,parent);
  tID=get_type_name();
  tID=tID.toupper();
  cov_trans = new();
  cov_trans.set_inst_name({get_full_name(), ".cov_trans"});
  trans = new();
  sb_post = new("sb_post", this);
endfunction : new

virtual function void write(input packet pkt);
	  trans = pkt;
      ->e_trans_collected; //signal transaction collection complete
endfunction : write

endclass : master_host_monitor 
