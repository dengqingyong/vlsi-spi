`ifndef GUARD_TOP
`define GUARD_TOP
/////////////////////////////////////////////////////
// Importing UVM Packages                          //
/////////////////////////////////////////////////////

`include "uvm.sv"
import uvm_pkg::* ;

module top();

`include "Configuration.sv"
`include "Packet.sv"
`include "Sequencer.sv"
`include "Sequence.sv"
`include "Driver.sv"
`include "Scoreboard.sv" 
`include "Environment.sv"
`include "test.sv"

/////////////////////////////////////////////////////
// clk Declaration and Generation                //
/////////////////////////////////////////////////////
    bit clk;
    
    initial
      begin
          #20;
          forever #10 clk = ~clk;
      end
/////////////////////////////////////////////////////
//  Wishbone Master interface instance             //
/////////////////////////////////////////////////////

    wbm_interface wbm_intf(clk);

/////////////////////////////////////////////////////
// Creat Configuration and Strart the run_test//
/////////////////////////////////////////////////////


    Configuration cfg;

initial begin
    cfg = new();
    cfg.wbm_intf = wbm_intf;
   
    run_test();
end

/////////////////////////////////////////////////////
//  DUT instance and signal connection             //
/////////////////////////////////////////////////////

switch DUT  (	
				.clk_i(clk),
				.rst			(wbm_intf.rst),			
				.wbs_cyc_i		(wbm_intf.wbs_cyc_o),	
				.wbs_stb_i		(wbm_intf.wbs_stb_o),	
				.wbs_we_i		(wbm_intf.wbs_we_o),
				.wbs_adr_i		(wbm_intf.wbs_adr_o),	
				.wbs_tga_i		(wbm_intf.wbs_tga_o),	
				.wbs_dat_i		(wbm_intf.wbs_dat_o),	
				.wbs_tgc_i		(wbm_intf.wbs_tgc_o),	
				.wbs_tgd_i		(wbm_intf.wbs_tgd_o),	
				.wbs_dat_o		(wbm_intf.wbs_dat_i),	
				.wbs_stall_o	(wbm_intf.wbs_stall_i),	
				.wbs_ack_o		(wbm_intf.wbs_ack_i),
				.wbs_err_o		(wbm_intf.wbs_err_i)
			);

endmodule : top

`endif