`ifndef GUARD_GLOBALS
`define GUARD_GLOBALS

parameter data_width_c		= 8;	//Data width
parameter bits_of_slaves_c	= 2;	//Bits of SPI_SS
parameter reg_addr_width_c	= 8;	//Address width
parameter reg_din_width_c	= 8;	//Input register width
parameter payload_max_len_c	= 20;	//Maximum burst length

int error = 0;
int num_of_pkts = 1;

`endif
