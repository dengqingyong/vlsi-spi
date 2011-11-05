`ifndef GUARD_SCOREBOARD
`define GUARD_SCOREBOARD
`include "globals.sv"
`include "packet.sv"
`include "coverage.sv"

//`timescale 1ps/1ps

class Scoreboard;

mailbox drvr_tx2sb;
mailbox drvr_rx2sb;
mailbox rcvr_tx2sb;
mailbox rcvr_rx2sb;
coverage cov = new();

function new(mailbox drvr_tx2sb, mailbox drvr_rx2sb, mailbox rcvr_tx2sb, mailbox rcvr_rx2sb);
  this.drvr_tx2sb = drvr_tx2sb;
  this.drvr_rx2sb = drvr_rx2sb;
  this.rcvr_tx2sb = rcvr_tx2sb;
  this.rcvr_rx2sb = rcvr_rx2sb;
endfunction:new

/// packets received at the slave side ///
task rx_get();
	packet pkt_rcv,pkt_exp;
	
	forever
	begin
		rcvr_rx2sb.get(pkt_rcv);
		$display(" %0d : (1) Scoreboard RX : Scoreboard received a packet from receiver %d, Length: %d ",$time,pkt_rcv.spi_ss, pkt_rcv.data.size);
		drvr_tx2sb.get(pkt_exp);
		$display(" %0d : (2) Scoreboard RX : Scoreboard received a packet from Driver, Length: %d ",$time, pkt_exp.data.size);
		if(pkt_rcv.compare1(pkt_exp)) 
		begin
			$display(" %0d : Scoreboard : Receiver Packet Matched ",$time);
			cov.sample(pkt_exp);
		end // if
		else
			error++;
		
endtask : rx_get

/// packets received at the master side ///
task tx_get();

	packet pkt_rcv,pkt_exp;

	drvr_rx2sb.get(pkt_rcv);
    $display(" %0d : (a) Scoreboard TX: Scoreboard received a packet from Driver, Length: %d ",$time, pkt_rcv.data.size);
    rcvr_tx2sb.get(pkt_exp);
	$display(" %0d : (b) Scoreboard TX: Scoreboard received a packet from Receiver %d, Length: %d",$time,pkt_exp.spi_ss, pkt_exp.data.size);
    if(pkt_rcv.compare2(pkt_exp)) 
    begin
		$display(" %0d : Scoreboard : Driver Packet Matched ",$time);
    end // if
    else
      error++;
	  
endtask : tx_get


endclass

`endif
