`ifndef GUARD_GLOBALS
`define GUARD_GLOBALS

`define data_width_c		8;	//Data width
`define bits_of_slaves_c	2;	//Bits of SPI_SS
`define reg_addr_width_c	8;	//Address width
`define reg_din_width_c		8;	//Input register width
`define payload_max_len_c	20;	//Maximum burst length

int error = 0;
int num_of_pkts = 10;

`endif
