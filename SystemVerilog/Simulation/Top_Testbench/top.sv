module top();

import uvm_pkg::*;
`include "uvm_macros.svh"

`include "master_host_inc.svh"
`include "master_host_demo_tb.sv"
`include "testlib.sv"

logic clk;

mh_intf if0(clk); //instantiate ovc interface

initial
  begin
    uvm_config_db#(virtual mh_intf)::set(null,"uvm_test_top.tb0.master_host0.agent0.*", "vif",if0);
    run_test("test1");
  end

always #10 clk = ~clk;

initial
  begin
    clk=0;
  end

/////////////////////////////////////////////////////
//  DUT instance and signal connection             //
/////////////////////////////////////////////////////

project_top DUT  (	
				.clk(clk),
				.rst			(if0.rst),			
				.slave_timeout	(if0.slave_timeout),
				.slave_interrupt(if0.slave_interrupt),
				.wbs_cyc_i		(if0.wbm_cyc_o),	
				.wbs_stb_i		(if0.wbm_stb_o),	
				.wbs_we_i		(if0.wbm_we_o),
				.wbs_adr_i		(if0.wbm_adr_o),	
				.wbs_tga_i		(if0.wbm_tga_o),	
				.wbs_dat_i		(if0.wbm_dat_o),	
				.wbs_tgc_i		(if0.wbm_tgc_o),	
				.wbs_tgd_i		(if0.wbm_tgd_o),	
				.wbs_dat_o		(if0.wbm_dat_i),	
				.wbs_stall_o	(if0.wbm_stall_i),	
				.wbs_ack_o		(if0.wbm_ack_i),
				.wbs_err_o		(if0.wbm_err_i)
			);

endmodule
