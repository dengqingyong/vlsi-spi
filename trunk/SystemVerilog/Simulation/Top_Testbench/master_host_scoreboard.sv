`uvm_analysis_imp_decl(_rcvd_pkt)
`uvm_analysis_imp_decl(_sent_pkt)

class master_host_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(master_host_scoreboard)
   
    packet exp_que[$];
	bit sbd_error;
   
    uvm_analysis_imp_rcvd_pkt #(packet,master_host_scoreboard) sb_rx;
    uvm_analysis_imp_sent_pkt #(packet,master_host_scoreboard) sb_ram;
   
    function new(string name, uvm_component parent);
        super.new(name, parent);
		sbd_error = 0;
    endfunction : new
   
    virtual function void write_rcvd_pkt(input packet pkt);
        packet exp_pkt;
        pkt.print();

        if(exp_que.size())
        begin
           exp_pkt = exp_que.pop_front();
           exp_pkt.print();
           if( pkt.compare(exp_pkt))
             `uvm_info(get_type_name(), $sformatf("Sent packet and received packet matched"), UVM_LOW)
           else begin
             `uvm_info(get_type_name(), $sformatf("Sent packet and received packet mismatched"), UVM_LOW)
			 sbd_error = 1;
		   end
        end
        else
             `uvm_error(get_type_name(), $sformatf("No more packets to in the expected queue to compare"))
   endfunction : write_rcvd_pkt
   
   virtual function void write_sent_pkt(input packet pkt);
        exp_que.push_back(pkt);
   endfunction : write_sent_pkt
   
   
  //build_phase
  function void build_phase(uvm_phase phase);
    sb_ram = new("sb_ram", this);
    sb_rx = new("sb_rx", this);
  endfunction

  virtual function void report_phase(uvm_phase phase);
      `uvm_info(get_type_name(),
        $sformatf("Reporting scoreboard information...\n%s", this.sprint()), UVM_LOW)
   endfunction : report_phase

  
endclass : master_host_scoreboard
