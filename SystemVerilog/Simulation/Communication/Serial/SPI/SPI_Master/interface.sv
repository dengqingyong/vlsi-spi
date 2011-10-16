
`ifndef GUARD_INTERFACE
`define GUARD_INTERFACE

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
  logic	[bits_of_slaves_c - 1:0]	spi_slave_addr;	//Slave Address
  
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
		input 	clk, fifo_req_data, reg_ack, reg_err, busy, dout, dout_valid,
		output 	rst, fifo_din, fifo_din_valid, fifo_empty, spi_slave_addr, reg_addr,
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

  cloking cb@(posedge clk);
     //#1 step is the minimum resolution.
	 //In future test, it is possible to generate delay between SPI Master and Slave
	 default input #1step output #1step;
     input		spi_clk
	 input    	spi_mosi;
     output		spi_miso
	 input    	spi_ss;
  endcloking
  
  modport MASTER_SPI(cloking cb, input clk);
  
endinterface

//////////////////////////////////////////////////

`endif 
