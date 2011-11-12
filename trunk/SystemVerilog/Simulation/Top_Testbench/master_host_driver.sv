class master_host_driver extends uvm_driver #(packet);
parameter addr_width_g = 10;
Internal_Ram int_ram;
string tID;
virtual interface mh_intf vif;
//TLM port for scoreboard communication 
uvm_analysis_port #(packet) sb_rx;
uvm_analysis_port #(packet) sb_ram;

`uvm_component_utils_begin(master_host_driver)
  `uvm_field_object(req, UVM_ALL_ON)
`uvm_component_utils_end

function new(string name, uvm_component parent);
  super.new(name,parent);
  tID=get_type_name();
  tID=tID.toupper();
  sb_rx = new ("sb_rx", this);
  sb_ram = new ("sb_ram", this);
endfunction : new

virtual function void build_phase(uvm_phase phase);
  super.build_phase(phase);
  if(!uvm_config_db#(virtual mh_intf)::get(this,"","vif",vif))
    `uvm_fatal("NOVIF", {"virtual interface must be set for: ", get_full_name(),".vif"});
endfunction : build_phase

task run_phase(uvm_phase phase);
  `uvm_info(tID,"RUNNING:",UVM_MEDIUM)
  get_and_drive();
endtask : run_phase

uvm_phase curr_phase;
function void phase_started(uvm_phase phase);
  //get phase to see if any phase specific actions are needed
  curr_phase = phase;
endfunction : phase_started

task get_and_drive();
	int idx;
	int_ram = new();
	//Prepare random RAM data
	assert (int_ram.randomize())
	else
		`uvm_error(tID, "Cannot randomize Internal RAM")
	//Prepare system
	@(posedge vif.clk);
	reset_dut();
	cfg_dut();
  forever
    begin
		seq_item_port.get_next_item(req);
		@(posedge vif.clk);
		if (req.wr_rd)	//Write Burst
		begin
			for (idx = 0 ; (idx <= req.length) && (idx + req.init_addr < 2**addr_width_g); idx++)
				int_ram.ram [idx + req.init_addr] = req.data [idx];	//Write transmitted data to RAM
			drive(req);
		end
		else begin		//Read Burst
			for (idx = 0 ; (idx <= req.length) && (idx + req.init_addr < 2**addr_width_g); idx++)
				req.data [idx] = int_ram.ram [idx + req.init_addr];	//Prepare golden packet, from RAM
			sb_ram.write(req);
			receive (req.init_addr, req.length);
		end
		@(posedge vif.clk);
		seq_item_port.item_done();
    end
endtask : get_and_drive

//virtual function void report_phase(uvm_phase phase);
//fill in any reporting code if needed
//endfunction : report_phase

    virtual task reset_dut();
        `uvm_info(tID,$sformatf("Start of reset_dut method"),UVM_LOW)

		//Ports to inactive state
		vif.wbm_cyc_o	<= 0;
		vif.wbm_stb_o	<= 0;
		vif.wbm_we_o	<= 0;
		vif.wbm_adr_o	<= '{default:0};
		vif.wbm_tga_o	<= '{default:0};
		vif.wbm_dat_o	<= '{default:0};
		vif.wbm_tgc_o	<= 0;
		vif.wbm_tgd_o	<= 0;

        vif.rst       <= 0;
        repeat (4) @(posedge vif.clk);
        vif.rst       <= 1;
   
        `uvm_info(tID,$sformatf("End of reset_dut method"),UVM_LOW)
    endtask : reset_dut
   
    virtual task cfg_dut(
							logic [7:0] clk_div_reg = 2,	//Clock divide factor
							logic [7:0] cphapol_reg = 0,	//CPOL, CPHA value
							string who_config = "master"					//Who to config: "master", "slave", "both"
						);
        `uvm_info(tID,$sformatf("Start of cfg_dut method"),UVM_LOW)
        @(posedge vif.clk);
		//Config SPI Master
		if (who_config == "both" || who_config == "master")
		begin
			vif.wbm_tgc_o	<=	1;	//Write to SPI Master Registers
			vif.wbm_tga_o	<=	0;
			vif.wbm_tgd_o	<=	0;
			vif.wbm_we_o	<=	1;	//Write
			//Config Clock Divide Reg
			vif.wbm_cyc_o	<=	1;
			vif.wbm_stb_o	<=	1;
			vif.wbm_adr_o	<=	'{default:0};	//Write Clock Divide Factor Registers
			vif.wbm_dat_o	<=	clk_div_reg;
			@(negedge vif.wbm_stall_i);		//Wait until SPI Master is Ready
			@(posedge vif.clk);
			vif.wbm_stb_o	<=	0;
			@(negedge vif.wbm_ack_i);			//Wait until SPI Master acknowledge
			vif.wbm_cyc_o	<=	0;
			@(posedge vif.clk);
			//TODO: Add assertion for WBM_ERR, and WBM_ACK for 1 cycle only

			//Config CPOL, CPHA Reg.
			vif.wbm_cyc_o	<=	1;
			vif.wbm_stb_o	<=	1;
			vif.wbm_adr_o	<=	1;			//Write CPOL, CPHA
			vif.wbm_dat_o	<=	cphapol_reg;
			@(negedge vif.wbm_stall_i);	//Wait until SPI Master is Ready
			@(posedge vif.clk);
			vif.wbm_stb_o	<=	0;
			@(negedge vif.wbm_ack_i);		//Wait until SPI Master acknowledge
			vif.wbm_cyc_o	<=	0;
			@(posedge vif.clk);
			//TODO: Add assertion for WBM_ERR, and WBM_ACK for 1 cycle only
		end

		//Config SPI Slave
		if (who_config == "both" || who_config == "slave")
		begin
			vif.wbm_tgc_o	<=	1;	//Write to SPI Slave Registers
			vif.wbm_tga_o	<=	0;
			vif.wbm_tgd_o	<=	1;
			vif.wbm_we_o	<=	1;	//Write
			//Config Clock Divide Reg
			vif.wbm_cyc_o	<=	1;
			vif.wbm_stb_o	<=	1;
			vif.wbm_adr_o	<=	'{default:0};	//Write Clock Divide Factor Registers
			vif.wbm_dat_o	<=	clk_div_reg;
			@(negedge vif.wbm_stall_i);		//Wait until SPI Slave is Ready
			@(posedge vif.clk);
			vif.wbm_stb_o	<=	0;
			@(negedge vif.wbm_ack_i);			//Wait until SPI Slave acknowledge
			vif.wbm_cyc_o	<=	0;
			@(posedge vif.clk);
			//TODO: Add assertion for WBM_ERR, and WBM_ACK for 1 cycle only

			//Config CPOL, CPHA Reg.
			vif.wbm_cyc_o	<=	1;
			vif.wbm_stb_o	<=	1;
			vif.wbm_adr_o	<=	1;			//Write CPOL, CPHA
			vif.wbm_dat_o	<=	cphapol_reg;
			@(negedge vif.wbm_stall_i);	//Wait until SPI Slave is Ready
			@(posedge vif.clk);
			vif.wbm_stb_o	<=	0;
			@(negedge vif.wbm_ack_i);		//Wait until SPI Master acknowledge
			vif.wbm_cyc_o	<=	0;
			vif.wbm_tgd_o	<=	0;
			@(posedge vif.clk);
			//TODO: Add assertion for WBM_ERR, and WBM_ACK for 1 cycle only
		end
		assert (who_config == "both" || who_config == "master" || who_config == "slave") 
		else
			`uvm_info(tID,$sformatf("cfg_dut: Config master / slave / both only!!!"),UVM_NONE)
		
        `uvm_info(tID,$sformatf("End of cfg_dut method"),UVM_LOW)
    endtask : cfg_dut
   
    virtual task drive	(
						input packet pkt		//Driven packet
						);
        int 							pkt_len;
		int 							idx;
		logic [addr_width_g - 1 : 0] 	addr = pkt.init_addr;
        pkt_len = pkt.length;
		//`uvm_info(tID,$sformatf("Driving [subphase is %0s] item sent is: \n%0s",pkt.get_name(),pkt.sprint()),UVM_LOW)
        `uvm_info(tID,$sformatf("Driving Packet, width of %0h(hex) from address %0h(hex)", pkt_len, addr),UVM_LOW)
		vif.wbm_tgc_o	<=	0;	//Write SPI Data
		vif.wbm_tga_o	<=	pkt_len;
		vif.wbm_tgd_o	<=	0;
		vif.wbm_we_o	<=	1;	//Write
		//Init Transaction
		vif.wbm_cyc_o	<=	1;
		vif.wbm_stb_o	<=	1;
        for (idx = 0 ; idx <= pkt_len ; idx++)
		begin
			vif.wbm_adr_o	<=	addr;
			vif.wbm_dat_o	<=	pkt.data[idx];
			if (vif.wbm_stall_i) 				//STALL is activated
				@(negedge vif.wbm_stall_i);	//Wait until SPI Master is Ready
			@(posedge vif.clk);
			addr++;
		end
		vif.wbm_stb_o	<=	0;
		@(negedge vif.wbm_ack_i);				//Wait until SPI Master acknowledge
		vif.wbm_cyc_o	<=	0;
		@(posedge vif.clk);
		//TODO: Add assertion for WBM_ERR, and WBM_ACK timing
   endtask : drive

    virtual task receive	(
							logic [addr_width_g - 1 : 0] 	init_addr,	//Initial address
							logic [7:0] 	burst_len	//Burst length - 1
							);
        packet pkt;
		logic [7 : 0]  	bytes[] = new [burst_len + 1];
		logic [addr_width_g - 1 : 0] 	addr = init_addr;
        `uvm_info(tID,$sformatf("Receiving Packet"),UVM_LOW)
		vif.wbm_tgc_o	<=	0;	//Read SPI Data
		vif.wbm_tga_o	<=	burst_len;
		vif.wbm_tgd_o	<=	0;
		vif.wbm_we_o	<=	0;	//Read
		//Init Transaction
		vif.wbm_cyc_o	<=	1;
		vif.wbm_stb_o	<=	1;
        for (int idx = 0 ; idx <= burst_len ; idx++)
		begin
			vif.wbm_adr_o	<=	addr;
			if (vif.wbm_stall_i) 				//STALL is activated
			begin
				@(negedge vif.wbm_stall_i);	//Wait until SPI Master is Ready
				@(posedge vif.clk);
			end
			@(posedge vif.clk);
			bytes[idx]	=	vif.wbm_dat_i;
			addr++;
		end
		vif.wbm_stb_o	<=	0;
		@(negedge vif.wbm_ack_i);				//Wait until SPI Master acknowledge
		vif.wbm_cyc_o	<=	0;
		@(posedge vif.clk);
		//TODO: Add assertion for WBM_ERR, and WBM_ACK timing
		pkt = new();
        pkt.data.delete();
        pkt.data = new[burst_len + 1];
		pkt.length = burst_len;
		pkt.init_addr = init_addr;
		pkt.wr_rd = 1'b0;
        foreach(bytes[i])
		  pkt.data[i] = bytes[i];
		sb_rx.write(pkt);
   endtask : receive

endclass : master_host_driver 
