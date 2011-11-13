interface mh_intf(input logic clk); 

	logic rst					;				//Reset (Synchronous at deactivation, asynchronous in activation ==> cannot be Wishbone Reset)
	logic slave_timeout			;				//Slave Timeout
    logic slave_interrupt		;				//Slave Interrupt
	logic wbm_cyc_o				;				//Cycle
	logic wbm_stb_o				;				//Strobe
	logic wbm_we_o				;				//Write Enable
	logic [9:0] wbm_adr_o		;				//Address
	logic [7:0] wbm_tga_o		;				//Burst Length
	logic [7:0] wbm_dat_o		;				//Data
	logic wbm_tgc_o				;				//'1' - Write to SPI Master Registers ; '0' - Transmit / recieve using SPI
	logic wbm_tgd_o				;				//'0' - Write / Read data to / from SPI Slave ; '1' - Write / Read registers to / from SPI Slave
	logic [7:0] wbm_dat_i		;				//Data
	logic wbm_stall_i			;				//STALL (Hold strobe)
	logic wbm_ack_i				;				//Acknowledge
	logic wbm_err_i				;				//Error
	
	always @(posedge clk)
	begin
	// Address must not be X or Z 
	assertAddrUnknown:assert property ((wbm_cyc_o |-> !$isunknown(wbm_adr_o)))
					  else
						`uvm_error("MasterHostIF", "ERR_ADDR_XZ\n Address went to X or Z");
	end
	
endinterface : mh_intf