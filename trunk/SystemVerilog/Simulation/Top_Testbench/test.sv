class test1 extends uvm_test;

    `uvm_component_utils(test1)

     Environment t_env ;

    function new (string name="test1", uvm_component parent=null);
        super.new (name, parent);
        t_env = new("t_env",this);
    endfunction : new 


    virtual function void build();
        super.build();

        set_config_object("t_env.*","Configuration",cfg);
        set_config_string("*.Seqncr", "default_sequence", "Seq_wbm");
        set_config_int("*.Seqncr", "count",1);
    endfunction

    virtual task run ();
        t_env.Seqncr.print();
        #3000ns;
        global_stop_request();
    endtask : run

endclass : test1