`ifndef GUARD_INTERNAL_RAM
`define GUARD_INTERNAL_RAM

	class Internal_Ram;
		parameter reset_polarity_g		=	0;		//RESET is active low
		parameter data_width_g			=	8;		//Data width
		parameter blen_width_g			=	9;		//Burst length width (maximum 2^9=512Kbyte Burst)
		parameter addr_width_g			=	10;		//Address width
		parameter reg_addr_width_g		=	8;		//SPI Registers address width
		parameter reg_din_width_g		=	8;		//SPI Registers data width

		rand logic [data_width_g - 1 : 0] ram [addr_width_g - 1 : 0];	//Internal RAM
	endclass : Internal_Ram
	
`endif
