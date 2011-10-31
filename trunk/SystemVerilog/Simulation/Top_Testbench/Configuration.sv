`ifndef GUARD_CONFIGURATION
`define GUARD_CONFIGURATION


class Configuration extends uvm_object;

    virtual wbm_interface.WBM   wbm_intf;

    virtual function uvm_object create(string name="");
        Configuration t = new();

        t.wbm_intf 		=   this.wbm_intf;

        return t;
    endfunction : create

endclass : Configuration

`endif
