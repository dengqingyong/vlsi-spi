`ifndef GUARD_COVERAGE
`define GUARD_COVERAGE
`include "Packet.sv"

class coverage;
packet pkt;

covergroup switch_coverage;

  length : coverpoint pkt.data.size;
endgroup

function new();
  switch_coverage = new();
endfunction : new

task sample(packet pkt);
 this.pkt = pkt;
 switch_coverage.sample();
endtask:sample

endclass

`endif
