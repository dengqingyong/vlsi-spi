`ifndef GUARD_GLOBALS
`define GUARD_GLOBALS

`define data_width_c		8;	//Data width
`define reg_addr_width_c	8;	//Address width
`define reg_din_width_c		8;	//Input register width
`define payload_max_len_c	20;	//Maximum burst length
`define cpol				0; //CPOL value - bit 1
`define cpha				0; //CPHA value - bit 0
`define default_data_c		0; //Default data to be transmitted by the slave when FIFO is empty

int error = 0;
int num_of_pkts = 10;

`endif