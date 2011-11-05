`ifndef GUARD_GLOBALS
`define GUARD_GLOBALS

parameter data_width_c		= 8;	//Data width
parameter bits_of_slaves_c	= 4;	//Bits of SPI_SS
parameter reg_addr_width_c	= 8;	//Address width
parameter reg_din_width_c	= 8;	//Input register width
parameter payload_max_len_c	= 20;	//Maximum burst length
parameter default_data_c	= 0; //Default data to be transmitted by the slave when FIFO is empty

int error = 0;
int num_of_pkts = 20;

`endif
