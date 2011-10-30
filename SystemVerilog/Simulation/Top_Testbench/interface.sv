`ifndef GUARD_INTERFACE
`define GUARD_INTERFACE


///////////////////////////////////////////////
// Interface declaration for Wishbone Master///
///////////////////////////////////////////////

interface wbm_interface(input bit clock);

	parameter reset_polarity_g		=	0;		//RESET is active low
	parameter data_width_g			=	8;		//Data width
	parameter blen_width_g			=	9;		//Burst length width (maximum 2^9=512Kbyte Burst)
	parameter addr_width_g			=	10;		//Address width
	parameter reg_addr_width_g		=	8;		//SPI Registers address width
	parameter reg_din_width_g		=	8		//SPI Registers data width

	//Reset								
	logic rst					;				//Reset (Synchronous at deactivation, asynchronous in activation ==> cannot be Wishbone Reset)
	
	//Wishbone Interface                                                                
	logic wbm_cyc_o				;				//Cycle
	logic wbm_stb_o				;				//Strobe
	logic wbm_we_o				;				//Write Enable
	logic [addr_width_g - 1 : 0] wbm_adr_o;		//Address
	logic [blen_width_g - 1 : 0] wbm_tga_o;		//Burst Length
	logic [data_width_g - 1 : 0] wbm_dat_o;		//Data
	logic wbm_tgc_o				;				//'1' - Write to SPI Master Registers ; '0' - Transmit / recieve using SPI
	logic wbm_tgd_o				;				//'0' - Write / Read data to / from SPI Slave ; '1' - Write / Read registers to / from SPI Slave
	logic [data_width_g - 1 : 0] wbm_dat_i;		//Data
	logic wbm_stall_i			;				//STALL (Hold strobe) 
	logic wbm_ack_i				;				//Acknowledge
	logic wbm_err_i				;				//Error
    
    modport WBM(
					input 	wbm_dat_i, wbm_stall_i,wbm_ack_i, wbm_err_i,
					output	wbm_cyc_o, wbm_stb_o, wbm_we_o, wbm_adr_o, wbm_tga_o, wbm_dat_o, 
							wbm_tgc_o,wbm_tgd_o
				);

endinterface :wbm_interface

//////////////////////////////////////////////////

`endif 
