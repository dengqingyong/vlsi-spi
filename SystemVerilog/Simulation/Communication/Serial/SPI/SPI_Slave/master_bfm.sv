`ifndef GUARD_MASTER_BFM
`define GUARD_MASTER_BFM
`include "globals.sv"

//`timescale 1ps/1ps

class master_bfm; // SPI MASTER BFM

virtual slave_spi_interface.SLAVE_SPI  spi_intf;

//// constructor method ////
function new(virtual slave_spi_interface.SLAVE_SPI spi_intf_new);

	this.spi_intf = spi_intf_new;

endfunction : new

//// master spi transmittion method ///
task start (logic [data_width_c - 1:0] data, logic burst_mode, logic [3:0] delay, logic [3:0] spi_freq, ref logic [data_width_c - 1:0] rec_data);

	$display (" %0d : Master BFM : task start() ",$time);
	@(posedge spi_intf.clk);
	spi_intf.spi_clk	<=	cpol;
	spi_intf.spi_ss		<=	0;
	fork
		repeat(16) #(10 * spi_freq) spi_intf.spi_clk = ~spi_intf.spi_clk;
		if (cpha == 0)
		begin
			for (int i = 0; i < 8; i++)
			begin
				spi_intf.spi_mosi	<=	data[i];
				#(10 * spi_freq); // wait for half spi_clk cycle
				rec_data[i]	<=	spi_intf.spi_miso;
				#(10 * spi_freq); // wait for half spi_clk cycle
			end // for
		end // if
		else  // cpha = 1
		begin
			#(10 * spi_freq); // wait for half spi_clk cycle
			for (int i = 0; i < 8; i++)
			begin
				spi_intf.spi_mosi	<=	data[i];
				#(10 * spi_freq); // wait for half spi_clk cycle
				rec_data[i]	<=	spi_intf.spi_miso;
				#(10 * spi_freq); // wait for half spi_clk cycle
			end // for
		end // else
	join
	if (burst_mode == 0) // finish transaction
	begin 
		@(posedge spi_intf.clk);
		spi_intf.spi_ss	<=	1;
		#(20 * delay);
	end //if
	else  // continue transaction - keep SS active
	begin
		@(posedge spi_intf.clk);
		#(20 * delay);
	end // else
	
endtask : start
	
/// Master SPI closing transmition method ///
task finish();
			
	@(posedge host_intf.clk);
	spi_intf.spi_ss		<=	1;

endtask : finish

endclass

`endif