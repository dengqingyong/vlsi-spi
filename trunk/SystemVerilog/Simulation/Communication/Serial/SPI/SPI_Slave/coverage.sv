`ifndef GUARD_COVERAGE
`define GUARD_COVERAGE
`include "packet.sv"

class coverage;

byte curr_data;
logic mode;
logic [3:0] delay;

covergroup pkt_coverage;
	data : coverpoint curr_data {
		bins def 	= {0};
		bins other 	= {1,255};
	}

	burst_mode : coverpoint mode {
		bins stop 	= {0};
		bins cont 	= {1};
	}

	delay_time : coverpoint delay {
		bins delay_time[] 	= {[0:15]};
	}
	
	CRS_burst_delay : cross mode, delay;
	
endgroup

function new();
	pkt_coverage = new();
endfunction : new

task sample(packet pkt);
	foreach (pkt.data[i])
	begin	
		this.curr_data = pkt.data[i];
		this.mode = pkt.burst_mode[i];
		this.delay = pkt.delay[i];
		pkt_coverage.sample();
	end // foreach
endtask : sample

endclass

`endif
