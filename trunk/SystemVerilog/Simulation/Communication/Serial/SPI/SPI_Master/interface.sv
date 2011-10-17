
`ifndef GUARD_INTERFACE
`define GUARD_INTERFACE
`include "Globals.sv"

///////////////////////////////////////////////
// Interface declaration for SPI inputs		///
///////////////////////////////////////////////

interface spi_master_in_interface(input bit clk);
  //Reset
  logic							rst;			//Reset
  //FIFO	
  logic							fifo_req_data;	//FIFO Request for Data
  logic							fifo_din_valid;	//FIFO - Output data is valid
  logic 						fifo_empty;		//FIFO Empty
  logic [data_width_c - 1:0]	fifo_din;		//FIFO - Output data
  
  //Slave Select Address
  logic	[$clog2(bits_of_slaves_c) - 1:0]	spi_slave_addr;	//Slave Address
  
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
  
  modport MASTER_INPUT (
		input 	fifo_req_data, reg_ack, reg_err, busy, dout, dout_valid,
		output 	clk, rst, fifo_din, fifo_din_valid, fifo_empty, spi_slave_addr, reg_addr,
				reg_din, reg_din_val
				);

endinterface

//////////////////////////////////////////////
// Interface for the SPI Protocol Interface.//
//////////////////////////////////////////////
interface spi_interface(input bit clk);
  logic           						spi_clk;	//SPI Clock
  logic           						spi_mosi; 	//Output data from Master
  logic           						spi_miso; 	//Input data from Slave
  logic     [bits_of_slaves_c - 1:0] 	spi_ss;		
  
  modport MASTER_SPI(
				input 	clk, spi_clk, spi_mosi, spi_ss,
				output	spi_miso
				);
  
endinterface

//////////////////////////////////////////////////

`endif 
