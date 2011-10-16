`ifndef GUARD_SCOREBOARD
`define GUARD_SCOREBOARD

class Scoreboard;

mailbox drvr_tx2sb;
mailbox drvr_rx2sb;
mailbox rcvr_tx2sb;
mailbox rcvr_rx2sb;
coverage cov = new();

function new(mailbox drvr_tx2sb,mailbox drvr_rx2sb, mailbox rcvr_tx2sb, mailbox drvr_rx2sb);
  this.drvr_tx2sb = drvr_tx2sb;
  this.drvr_rx2sb = drvr_rx2sb;
  this.rcvr_tx2sb = rcvr_tx2sb;
  this.rcvr_rx2sb = rcvr_rx2sb;
endfunction:new


task rx_get();
  packet pkt_rcv,pkt_exp;
  forever
  begin
    rcvr_rx2sb.get(pkt_rcv);
    $display(" %0d : Scoreboard : Scoreboard received a packet from receiver ",$time);
    drvr_tx2sb.get(pkt_exp);
    if(pkt_rcv.compare(pkt_exp)) 
    begin
       $display(" %0d : Scoreboard : Received Packet Matched ",$time);
    cov.sample(pkt_exp);
    end
    else
      error++;
  end
endtask : rx_get

task tx_get();
  packet pkt_rcv,pkt_exp;
  forever
  begin
    drvr_rx2sb.get(pkt_rcv);
    $display(" %0d : Scoreboard : Scoreboard received a packet from Driver ",$time);
    rcvr_tx2sb.get(pkt_exp);
    if(pkt_rcv.compare(pkt_exp)) 
    begin
       $display(" %0d : Scoreboard :Driver Packet Matched ",$time);
    end
    else
      error++;
  end
endtask : tx_get


endclass

`endif

