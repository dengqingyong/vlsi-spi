`ifndef GUARD_RAND_INPUTS
`define GUARD_RAND_INPUTS

class rand_inputs;
	randc logic							fifo_din_valid;	//FIFO - Output data is valid
	randc logic 						fifo_empty;		//FIFO Empty
	randc logic [data_width_c - 1:0]	fifo_din;		//FIFO - Output data
	 
	 //Slave Select Address
	randc logic	[$clog2(bits_of_slaves_c) - 1:0]	spi_slave_addr;	//Slave Address
	 
	 //Configuration Registers
	randc logic [reg_addr_width_c - 1:0]	reg_addr;	//Register's Address
	randc logic [reg_din_width_c - 1:0]		reg_din;	//Register's input data
	randc logic 							reg_din_val;//Register's data is valid
	
	//SPI MISO
	randc logic								spi_miso;	//MISO (SPI)
endclass

`endif

