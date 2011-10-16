`ifndef GUARD_COVERAGE
`define GUARD_COVERAGE

class coverage;
packet pkt;

covergroup switch_coverage;

  length : coverpoint pkt.data.size;
  //all_cross:  cross length,da,length_kind,fcs_kind;
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
