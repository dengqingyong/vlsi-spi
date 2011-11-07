`ifndef GUARD_COVERAGE
`define GUARD_COVERAGE
`include "packet.sv"
`include "globals.sv"

class coverage;

	packet pkt;

	covergroup pkt_coverage;

		length 	: coverpoint pkt.data.size {
			bins size[] 	= 	{[10:payload_max_len_c]};
		}
		
		slave_num	:	coverpoint pkt.spi_ss {
			bins number[] 	= {[0:3]};
		}

	endgroup

function new();
	pkt_coverage = new();
endfunction : new

task sample(packet pkt);
	this.pkt = pkt;
	pkt_coverage.sample();
endtask:sample

endclass

`endif
