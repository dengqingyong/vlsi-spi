`ifndef GUARD_ENV
`define GUARD_ENV

class Environment extends uvm_env;

    `uvm_component_utils(Environment)

    Sequencer Seqncr;
    Driver Drvr;
    Scoreboard Sbd;
 
    function new(string name , uvm_component parent = null);
        super.new(name, parent);
    endfunction: new


    virtual function void build();
        super.build();
        uvm_report_info(get_full_name(),"START of build ",UVM_LOW);

        Drvr   = Driver::type_id::create("Drvr",this);
        Seqncr = Sequencer::type_id::create("Seqncr",this);

        Sbd   = Scoreboard::type_id::create("Sbd",this);
        
        uvm_report_info(get_full_name(),"END of build ",UVM_LOW);
    endfunction
    
    virtual function void connect();
        super.connect();
        uvm_report_info(get_full_name(),"START of connect ",UVM_LOW);

        Drvr.seq_item_port.connect(Seqncr.seq_item_export);

        Drvr.Drvr2Sb_port.connect(Sbd.Drvr2Sb_port);

        Drvr.Rcvr2Sb_port.connect(Sbd.Rcvr2Sb_port);

        uvm_report_info(get_full_name(),"END of connect ",UVM_LOW);
    endfunction


endclass : Environment

`endif 
