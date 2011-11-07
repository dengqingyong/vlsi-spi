`ifndef GUARD_INTERFACE
`define GUARD_INTERFACE
`include "globals.sv"

///////////////////////////////////////////////
// Interface declaration for SPI inputs		///
///////////////////////////////////////////////

interface spi_master_interface(input bit clk);
  //Reset
  logic							rst;			//Reset
  //FIFO	
  logic							fifo_req_data;	//FIFO Request for Data
  logic							fifo_din_valid;	//FIFO - Output data is valid
  logic 						fifo_empty;		//FIFO Empty
  logic [data_width_c - 1:0]	fifo_din;		//FIFO - Output data
  
  //Slave Select Address
  logic	[$clog2(bits_of_slaves_c) :0]	spi_slave_addr;	//Slave Address
  
  //Configuration Registers
  logic [reg_addr_width_c - 1:0]	reg_addr;	//Register's Address
  logic [reg_din_width_c - 1:0]		reg_din;	//Register's input data
  logic 							reg_din_val;//Register's data is valid
  logic								reg_ack;	//Register is acknowledged
  logic								reg_err;	//Register write error
  
  //Outputs from SPI Master
  logic							busy;			//SPI Master is Busy - TX and RX data
  logic	[data_width_c - 1:0]	dout;			//SPI Data Out (From SPI Slave)
  logic 						dout_valid;		//Output data is valid
  
  modport SPI_MASTER (
		input 	clk, fifo_req_data, reg_ack, reg_err, busy, dout, dout_valid,
		output 	rst, fifo_din, fifo_din_valid, fifo_empty, spi_slave_addr, reg_addr,
				reg_din, reg_din_val
				);

endinterface

interface spi_slave_interface(input bit clk);
  //Reset
  logic							rst;			//Reset
  //FIFO	
  logic							fifo_req_data;	//FIFO Request for Data
  logic							fifo_din_valid;	//FIFO - Output data is valid
  logic 						fifo_empty;		//FIFO Empty
  logic [data_width_c - 1:0]	fifo_din;		//FIFO - Output data
  
  //Configuration Registers
  logic [reg_din_width_c - 1:0]		reg_din;	//Register's input data
  logic 							reg_din_val;//Register's data is valid
  logic								reg_ack;	//Register is acknowledged
  
  //Outputs from SPI Slave
  logic							busy;			//SPI SLAVE is Busy - TX and RX data
  logic 						timeout;		//SPI SLAVE reached timeout
  logic	[data_width_c - 1:0]	dout;			//SPI Data Out (From SPI Slave)
  logic 						dout_valid;		//Output data is valid
  logic							interrupt;		//Transaction was interrupted
  
  modport SPI_SLAVE (
		input 	clk, fifo_req_data, busy, dout, dout_valid, interrupt, reg_ack,
		output 	rst, fifo_din, fifo_din_valid, fifo_empty, reg_din, reg_din_val
				);

endinterface

`endif 
