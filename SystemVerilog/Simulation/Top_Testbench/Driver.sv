`ifndef GUARD_DRIVER
`define GUARD_DRIVER

class Driver extends uvm_driver #(Packet);

	parameter reset_polarity_g		=	0;		//RESET is active low
	parameter data_width_g			=	8;		//Data width
	parameter blen_width_g			=	9;		//Burst length width (maximum 2^9=512Kbyte Burst)
	parameter addr_width_g			=	10;		//Address width
	parameter reg_addr_width_g		=	8;		//SPI Registers address width
	parameter reg_din_width_g		=	8		//SPI Registers data width

    Configuration cfg;
	
	rand logic [data_width_g - 1 : 0] int_ram [addr_width_g - 1 : 0];	//Internal RAM
   
    virtual wbm_interface.WBM   wbm_intf;
    
    uvm_analysis_port #(Packet) Drvr2Sb_port;	//Driven packets
	uvm_analysis_port #(Packet) Rcvr2Sb_port;	//Reieved Packets
	
    `uvm_component_utils(Driver) 
   
    function new( string name = "" , uvm_component parent = null) ;
        super.new( name , parent );
		assert (int_ram.randomize())
		else
			uvm_report_error(get_full_name(),"Cannot randomize Internal RAM ",UVM_LOW, `__FILE__, `__LINE__);
    endfunction : new
   
    virtual function void build();
        super.build();
        Drvr2Sb_port = new("Drvr2Sb", this);
        Rcvr2Sb_port = new("Rcvr2Sb", this);
    endfunction :  build
   
    virtual function void end_of_elaboration();
        uvm_object tmp;
        super.end_of_elaboration();
        assert(get_config_object("Configuration",tmp));
        $cast(cfg,tmp);
        this.wbm_intf = cfg.wbm_intf;
    endfunction : end_of_elaboration

    virtual task run();
        Packet pkt;
		logic [addr_width_g - 1 : 0] init_addr = 0;
		//TODO: Change init address
        @(posedge wbm_intf.clk);
        reset_dut();
        cfg_dut();
        forever begin
            seq_item_port.get_next_item(pkt);
            Drvr2Sb_port.write(pkt);
            @(posedge wbm_intf.clk);
            drive(pkt, init_addr);
            @(posedge wbm_intf.clk);
            seq_item_port.item_done();
        end
    endtask : run
   
    virtual task reset_dut();
        uvm_report_info(get_full_name(),"Start of reset_dut() method ",UVM_LOW);

		//Ports to inactive state
		wbm_intf.wbm_cyc_o	<= 0;
		wbm_intf.wbm_stb_o	<= 0;
		wbm_intf.wbm_we_o	<= 0;
		wbm_intf.wbm_adr_o	<= '{default:0};
		wbm_intf.wbm_tga_o	<= '{default:0};
		wbm_intf.wbm_dat_o	<= '{default:0};
		wbm_intf.wbm_tgc_o	<= 0;
		wbm_intf.wbm_tgd_o	<= 0;

        wbm_intf.reset       <= reset_polarity_g;
        repeat (4) @(posedge wbm_intf.clk);
        wbm_intf.reset       <= !reset_polarity_g;
   
        uvm_report_info(get_full_name(),"End of reset_dut() method ",UVM_LOW);
    endtask : reset_dut
   
    virtual task cfg_dut(
							logic [reg_din_width_g - 1:0] clk_div_reg,	//Clock divide factor
							logic [reg_din_width_g - 1:0] cphapol_reg,	//CPOL, CPHA value
							string who_config = "both"					//Who to config: "master", "slave", "both"
						);
        uvm_report_info(get_full_name(),"Start of cfg_dut method ",UVM_LOW);
        @(posedge wbm_intf.clk);
		//Config SPI Master
		if (who_config == "both" || who_config == "master")
		begin
			wbm_intf.wbm_tgc_o	<=	1;	//Write to SPI Master Registers
			wbm_intf.wbm_tga_o	<=	0;
			wbm_intf.wbm_tgd_o	<=	0;
			wbm_intf.wbm_we_o	<=	1;	//Write
			//Config Clock Divide Reg
			wbm_intf.wbm_cyc_o	<=	1;
			wbm_intf.wbm_stb_o	<=	1;
			wbm_intf.wbm_adr_o	<=	'{default:0};	//Write Clock Divide Factor Registers
			wbm_intf.wbm_dat_o	<=	clk_div_reg;
			@(negedge wbm_intf.wbm_stall_i);		//Wait until SPI Master is Ready
			@(posedge wbm_intf.clk);
			wbm_intf.wbm_stb_o	<=	0;
			@(negedge wbm_intf.wbm_ack_i);			//Wait until SPI Master acknowledge
			wbm_intf.wbm_cyc_o	<=	0;
			@(posedge wbm_intf.clk);
			//TODO: Add assertion for WBM_ERR, and WBM_ACK for 1 cycle only

			//Config CPOL, CPHA Reg.
			wbm_intf.wbm_cyc_o	<=	1;
			wbm_intf.wbm_stb_o	<=	1;
			wbm_intf.wbm_adr_o	<=	1;			//Write CPOL, CPHA
			wbm_intf.wbm_dat_o	<=	cphapol_reg;
			@(negedge wbm_intf.wbm_stall_i);	//Wait until SPI Master is Ready
			@(posedge wbm_intf.clk);
			wbm_intf.wbm_stb_o	<=	0;
			@(negedge wbm_intf.wbm_ack_i);		//Wait until SPI Master acknowledge
			wbm_intf.wbm_cyc_o	<=	0;
			@(posedge wbm_intf.clk);
			//TODO: Add assertion for WBM_ERR, and WBM_ACK for 1 cycle only
		end

		//Config SPI Slave
		if (who_config == "both" || who_config == "slave")
		begin
			wbm_intf.wbm_tgc_o	<=	1;	//Write to SPI Slave Registers
			wbm_intf.wbm_tga_o	<=	0;
			wbm_intf.wbm_tgd_o	<=	1;
			wbm_intf.wbm_we_o	<=	1;	//Write
			//Config Clock Divide Reg
			wbm_intf.wbm_cyc_o	<=	1;
			wbm_intf.wbm_stb_o	<=	1;
			wbm_intf.wbm_adr_o	<=	'{default:0};	//Write Clock Divide Factor Registers
			wbm_intf.wbm_dat_o	<=	clk_div_reg;
			@(negedge wbm_intf.wbm_stall_i);		//Wait until SPI Slave is Ready
			@(posedge wbm_intf.clk);
			wbm_intf.wbm_stb_o	<=	0;
			@(negedge wbm_intf.wbm_ack_i);			//Wait until SPI Slave acknowledge
			wbm_intf.wbm_cyc_o	<=	0;
			@(posedge wbm_intf.clk);
			//TODO: Add assertion for WBM_ERR, and WBM_ACK for 1 cycle only

			//Config CPOL, CPHA Reg.
			wbm_intf.wbm_cyc_o	<=	1;
			wbm_intf.wbm_stb_o	<=	1;
			wbm_intf.wbm_adr_o	<=	1;			//Write CPOL, CPHA
			wbm_intf.wbm_dat_o	<=	cphapol_reg;
			@(negedge wbm_intf.wbm_stall_i);	//Wait until SPI Slave is Ready
			@(posedge wbm_intf.clk);
			wbm_intf.wbm_stb_o	<=	0;
			@(negedge wbm_intf.wbm_ack_i);		//Wait until SPI Master acknowledge
			wbm_intf.wbm_cyc_o	<=	0;
			wbm_intf.wbm_tgd_o	<=	0;
			@(posedge wbm_intf.clk);
			//TODO: Add assertion for WBM_ERR, and WBM_ACK for 1 cycle only
		end
		assert (who_config == "both" || who_config == "master" || who_config == "slave") 
		else
			uvm_report_error(get_full_name(),"cfg_dut: Config master / slave / both only!!!", UVM_NONE, `__FILE__, `__LINE__);
		
        uvm_report_info(get_full_name(),"End of cfg_dut method ",UVM_LOW);
    endtask : cfg_dut
   
    virtual task drive	(
						Packet 							pkt,		//Driven packet
						logic [addr_width_g - 1 : 0] 	init_addr	//Initial address
						);
        logic [data_width_g - 1 : 0]  	bytes[];
        int 							pkt_len;
		logic [addr_width_g - 1 : 0] 	addr = init_addr;
        pkt_len = pkt.pack_bytes(bytes);
        uvm_report_info(get_full_name(),"Driving packet ...",UVM_LOW);
		wbm_intf.wbm_tgc_o	<=	0;	//Write SPI Data
		wbm_intf.wbm_tga_o	<=	pkt_len - 1;
		wbm_intf.wbm_tgd_o	<=	0;
		wbm_intf.wbm_we_o	<=	1;	//Write
		//Init Transaction
		wbm_intf.wbm_cyc_o	<=	1;
		wbm_intf.wbm_stb_o	<=	1;
        foreach(bytes[i])
		begin
			wbm_intf.wbm_adr_o	<=	addr;
			wbm_intf.wbm_dat_o	<=	bytes[i];
			if (wbm_intf.wbm_stall_i) 				//STALL is activated
				@(negedge wbm_intf.wbm_stall_i);	//Wait until SPI Master is Ready
			@(posedge wbm_intf.clk);
			addr++;
		end
		wbm_intf.wbm_stb_o	<=	0;
		@(negedge wbm_intf.wbm_ack_i);				//Wait until SPI Master acknowledge
		wbm_intf.wbm_cyc_o	<=	0;
		@(posedge wbm_intf.clk);
		//TODO: Add assertion for WBM_ERR, and WBM_ACK timing
   endtask : drive

    virtual task recieve	(
							logic [addr_width_g - 1 : 0] 	init_addr	//Initial address
							logic [blen_width_g - 1 : 0] 	burst_len	//Burst length - 1
							);
        Packet pkt;
		logic [data_width_g - 1 : 0]  	bytes[];
		logic [addr_width_g - 1 : 0] 	addr = init_addr;
        uvm_report_info(get_full_name(),"Receiving packet ...",UVM_LOW);
		wbm_intf.wbm_tgc_o	<=	0;	//Read SPI Data
		wbm_intf.wbm_tga_o	<=	burst_len;
		wbm_intf.wbm_tgd_o	<=	0;
		wbm_intf.wbm_we_o	<=	0;	//Read
		//Init Transaction
		wbm_intf.wbm_cyc_o	<=	1;
		wbm_intf.wbm_stb_o	<=	1;
        for (int idx = 0 ; idx <= burst_len ; i++)
		begin
			wbm_intf.wbm_adr_o	<=	addr;
			if (wbm_intf.wbm_stall_i) 				//STALL is activated
				@(negedge wbm_intf.wbm_stall_i);	//Wait until SPI Master is Ready
			@(posedge wbm_intf.clk);
			bytes[idx]	<=	wbm_intf.wbm_dat_i;
			addr++;
		end
		wbm_intf.wbm_stb_o	<=	0;
		@(negedge wbm_intf.wbm_ack_i);				//Wait until SPI Master acknowledge
		wbm_intf.wbm_cyc_o	<=	0;
		@(posedge wbm_intf.clk);
		//TODO: Add assertion for WBM_ERR, and WBM_ACK timing
		pkt = new();
		void'(pkt.unpack_bytes(bytes));
		Rcvr2Sb_port.write(pkt);
   endtask : recieve

endclass : Driver

`endif

