`ifndef GUARD_INTERFACE
`define GUARD_INTERFACE
`include "globals.sv"

//`timescale 1ps/1ps

////////////////////////////////////////////////////
// Interface declaration for slave_spi core and  ///
// slave host interface.						 ///
////////////////////////////////////////////////////

interface slave_host_interface(input bit clk);
  //Reset
  logic							rst;			//Reset
  //FIFO	
  logic							fifo_req_data;	//FIFO Request for Data
  logic							fifo_din_valid;	//FIFO - Output data is valid
  logic 						fifo_empty;		//FIFO Empty
  logic [data_width_c - 1:0]	fifo_din;		//FIFO - Output data
  
  //Outputs from SPI Slave
  logic							busy;			//SPI SLAVE is Busy - TX and RX data
  logic 						timeout;		//SPI SLAVE reached timeout
  logic	[data_width_c - 1:0]	dout;			//SPI Data Out (From SPI Slave)
  logic 						dout_valid;		//Output data is valid
  logic							interrupt;		//Transaction was interrupted
  
  modport SLAVE_HOST (
		input 	clk, fifo_req_data, busy, dout, dout_valid, interrupt,
		output 	rst, fifo_din, fifo_din_valid, fifo_empty
				);

  modport DUT (
		input clk, rst, fifo_din, fifo_din_valid, fifo_empty,
		output fifo_req_data, busy, timeout, dout, dout_valid, interrupt 
				);
				
endinterface

///////////////////////////////////////////////
// Interface for the SPI protocol interface. //
///////////////////////////////////////////////
interface slave_spi_interface(input bit clk);
  logic           						spi_clk;	//SPI Clock
  logic           						spi_mosi; 	//Input data from Master
  logic           						spi_miso; 	//Output data from Slave
  logic     						 	spi_ss;		///input from Master			
  
  modport SLAVE_SPI (
				input clk, spi_miso,
				output spi_clk, spi_mosi, spi_ss
				);

  modport DUT (
				input clk, spi_clk, spi_mosi, spi_ss,
				output spi_miso
				);
  
endinterface

//////////////////////////////////////////////////////
// Interface for the slave configuration Interface. //
//////////////////////////////////////////////////////

interface slave_config_interface (input bit clk);
  logic [reg_din_width_c - 1:0]		reg_din;	//Register's input data
  logic 							reg_din_val;//Register's data is valid
  logic								reg_ack;	//Register is acknowledged
  
  modport SLAVE_CONFIG (
		input clk, reg_ack,
		output reg_din, reg_din_val
		);
		
  modport DUT (
		input clk, reg_din, reg_din_val,
		output reg_ack
		);
		
endinterface

///////////////////////////////////////////////////

`endif
