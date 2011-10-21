`ifndef GUARD_MASTER_BFM
`define GUARD_MASTER_BFM
`include "globals.sv"

class master_bfm; // SPI MASTER BFM

virtual slave_spi_interface.SLAVE_SPI  spi_intf;

//// constructor method ////
function new(virtual slave_spi_interface.SLAVE_SPI spi_intf_new);

	this.spi_intf = spi_intf_new;

endfunction : new

//// master spi transmittion method ///
function bit [7:0] start (bit [7:0] data, bit burst_mode, bit [3:0] delay, bit [3:0] spi_freq);
	bit [7:0] rec_data;

	@(posedge spi_intf.clk);
	spi_intf.cb.spi_clk	<=	cpol;
	spi_intf.cb.spi_ss	<=	0;
	fork
		repeat(16) #{10 * spi_freq} spi_intf.cb.spi_clk = ~spi_intf.cb.spi_clk;
		if (cpha == 0)
		begin
			for (int i = 0; i < 8; i++)
			begin
				spi_intf.cb.spi_mosi	<=	data[i];
				#{10 * spi_freq}; // wait for half spi_clk cycle
				rec_data[i]	<=	spi_intf.cb.spi_miso;
				#{10 * spi_freq}; // wait for half spi_clk cycle
			end // for
		end // if
		else  // cpha = 1
		begin
			#{10 * spi_freq} // wait for half spi_clk cycle
			for (int i = 0; i < 8; i++)
			begin
				spi_intf.cb.spi_mosi	<=	data[i];
				#{10 * spi_freq}; // wait for half spi_clk cycle
				rec_data[i]	<=	spi_intf.cb.spi_miso;
				#{10 * spi_freq}; // wait for half spi_clk cycle
			end // for
		end // else
	join
	if (burst_mode == 0) // finish transaction
	begin 
		@(posedge spi_intf.clk);
		spi_intf.cb.spi_ss	<=	1;
		#{20 * delay};
	end //if
	else  // continue transaction - keep SS active
	begin
		@(posedge spi_intf.clk);
		#{20 * delay};
	end // else
	
	return rec_data;
	
endfunction : start
	
endclass

`endif