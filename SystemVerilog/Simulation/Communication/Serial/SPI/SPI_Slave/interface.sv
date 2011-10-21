
`ifndef GUARD_INTERFACE
`define GUARD_INTERFACE
`include "globals.sv"

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
  logic							busy;			//SPI Master is Busy - TX and RX data
  logic	[data_width_c - 1:0]	dout;			//SPI Data Out (From SPI Slave)
  logic 						dout_valid;		//Output data is valid
  logic							interrupt;		//Transaction was interrupted
  
  modport SLAVE_HOST (
		input 	clk, fifo_req_data, busy, dout, dout_valid, interrupt,
		output 	rst, fifo_din, fifo_din_valid, fifo_empty
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

  cloking cb@(posedge clk);
     //#1 step is the minimum resolution.
	 //In future test, it is possible to generate delay between SPI Master and Slave
	 default input #1 output #1;
     output		spi_clk;
	 output    	spi_mosi;
     input		spi_miso
	 output    	spi_ss;
  endcloking
  
  modport SLAVE_SPI(cloking cb, input clk);
  
endinterface

//////////////////////////////////////////////////////
// Interface for the slave configuration Interface. //
//////////////////////////////////////////////////////

intrerface slave_config_interface (input bit clk);
  logic [reg_din_width_c - 1:0]		reg_din;	//Register's input data
  logic 							reg_din_val;//Register's data is valid
  logic								reg_ack;	//Register is acknowledged
  logic								reg_err;	//Register write error
  
  modport SLAVE_CONFIG (
		input clk, reg_ack, reg_err,
		output reg_din, reg_din_val
		);
		
end interface

///////////////////////////////////////////////////

`endif