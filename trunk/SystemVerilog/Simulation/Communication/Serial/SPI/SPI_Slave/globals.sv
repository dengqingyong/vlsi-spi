`ifndef GUARD_GLOBALS
`define GUARD_GLOBALS

//`timescale 1ps/1ps

parameter data_width_c		=	8;	//Data width
parameter reg_addr_width_c	=	8;	//Address width
parameter reg_din_width_c	=	8;	//Input register width
parameter payload_max_len_c	=	20;	//Maximum burst length
parameter cpol				=	0; //CPOL value - bit 1
parameter cpha				=	0; //CPHA value - bit 0
parameter default_data_c	=	0; //Default data to be transmitted by the slave when FIFO is empty

int error = 0;
int num_of_pkts = 10;

`endif
