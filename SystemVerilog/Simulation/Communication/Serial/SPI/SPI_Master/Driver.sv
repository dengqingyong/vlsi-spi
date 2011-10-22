`ifndef GUARD_DRIVER
`define GUARD_DRIVER
`include "Globals.sv"
`include "Packet.sv"

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

class Driver;
virtual spi_master_in_interface.MASTER_INPUT  	in_intf;
virtual spi_interface.MASTER_SPI  				spi_intf;
mailbox drvr_tx2sb;	//Transmitted data
mailbox drvr_rx2sb;	//Received data
event end_burst;
packet gpkt;

//// constructor method ////
function new(virtual spi_master_in_interface.MASTER_INPUT  in_intf_new, 
			virtual spi_interface.MASTER_SPI  spi_intf_new,
			mailbox drvr_tx2sb, mailbox drvr_rx2sb);
  this.in_intf    = in_intf_new  ;
  this.spi_intf   = spi_intf_new  ;
  if ((drvr_tx2sb == null) || (drvr_rx2sb == null))
  begin
    $display(" **ERROR**: Driver mailbox is null");
    $finish;
  end
  else
  this.drvr_tx2sb = drvr_tx2sb;
  this.drvr_rx2sb = drvr_rx2sb;
  gpkt = new();
endfunction : new  

/// method to send the packet to DUT ////////
task start();
  packet pkt;
  pkt = new gpkt;
  repeat(num_of_pkts)	//Transmit 'num_of_pkts' bursts
  begin
    //Simulate FIFO Empty
	in_intf.fifo_empty		<=	1;
	in_intf.fifo_din_valid	<=	0;
	in_intf.fifo_din		<=	'{default:(0)};
	 
	repeat(19) @(posedge in_intf.clk);	//Wait for 20 clocks, before initializing transmission
	in_intf.fifo_empty		<=	0;		//Negate FIFO Empty
	if (in_intf.busy)
		@(negedge in_intf.busy);

    //// Randomize the packet /////
    if ( pkt.randomize())
     begin
       $display (" %0d : Driver : Transmitting packet:",$time);
       //// display the packet content ///////
       pkt.display();
          
       /////  send the packed bytes //////
       foreach(pkt.data[i])
       begin
	    in_intf.spi_slave_addr	<=	pkt.spi_ss;
		if (in_intf.fifo_req_data == 0)
		begin
			wait (in_intf.fifo_req_data);	//Wait for Request Data from FIFO
			@(posedge in_intf.clk);
		end
		in_intf.fifo_din_valid	<=	1;
		in_intf.fifo_din		<=	pkt.data[i]; 
		@(posedge in_intf.clk);
		in_intf.fifo_din_valid	<=	0;
       end 
  
		//Simulate FIFO Empty - End of burst
		in_intf.fifo_empty		<=	1;
		in_intf.fifo_din_valid	<=	0;
		in_intf.fifo_din		<=	'{default:0};
  
       //// Push the packet in to mailbox for scoreboard /////
       drvr_tx2sb.put(pkt);
	   repeat(2)@(posedge in_intf.clk);
	   @(negedge in_intf.busy);	//To ensure that last dout_valid from SPI Master has been asserted
	   repeat(1)@(posedge in_intf.clk);	//In case BUSY negates with DOUT_VALID at the same clock
	   if (in_intf.dout_valid)
		  @(negedge in_intf.dout_valid)
	   ->end_burst;
       
       $display(" %0d : Driver : Finished Driving the packet with length %0d",$time,pkt.data.size); 
     end
     else
      begin
         $display (" %0d Driver : ** Randomization failed. **",$time);
         ////// Increment the error count in randomization fails ////////
         error++;
      end
  end
endtask : start

/// Method to validate outputs are in their default states at reset//
task rst_val_outs();
	//Define random values for input ports
	
	rand_inputs rands = new();
	repeat (10)	//10 inputs forcing
	begin
		in_intf.rst <= 1'b0; //Reset
		@(posedge in_intf.clk);
		fork
			begin: fj_force
				if (rands.randomize())
				begin
					in_intf.fifo_din_valid	<=	rands.fifo_din_valid;
					in_intf.fifo_empty		<=	rands.fifo_empty;
					in_intf.fifo_din		<=	rands.fifo_din;
					in_intf.spi_slave_addr	<=	rands.spi_slave_addr;
					in_intf.reg_addr		<=	rands.reg_addr;
					in_intf.reg_din			<=	rands.reg_din;
					in_intf.reg_din_val		<=	rands.reg_din_val;
					spi_intf.spi_miso		<=	rands.spi_miso;
				end
				else
					$error ("%t >> Failed to randomize inputs at reset", $time);
			end
			
			begin: fj_end_of_rst
				repeat(10)@(posedge in_intf.clk);
				in_intf.rst <= 1'b1; //Negate Reset after 10 clocks
			end
			
			begin: fj_val_outs
				//Validate outputs does not change, until end of reset
				@(in_intf.fifo_req_data or in_intf.reg_ack or in_intf.reg_err or in_intf.busy or in_intf.dout or in_intf.dout_valid or spi_intf.spi_clk or spi_intf.spi_mosi or spi_intf.spi_ss or posedge in_intf.rst);
				assert (in_intf.rst == 1'b1)	//Reset event: OK
				else begin
					$error ("%t >> While reset is active, one of the outputs had changed!", $time);
					error++;
				end
			end
		join
		in_intf.fifo_din_valid = 0'b0;
		in_intf.fifo_empty = 1'b1;
		in_intf.reg_din_val = 0'b0;
		repeat (10) @(posedge in_intf.clk);
	end
endtask : rst_val_outs

/// method to read the packets from DUT ////////
task rx();
  packet pkt;
  logic [data_width_c - 1:0] bytes[];
  forever
  begin
    @(end_burst or posedge in_intf.dout_valid or negedge in_intf.rst);	//Wait for end of burst or New Data / Reset
	if (in_intf.dout_valid) //New Data
	begin
		bytes = new[bytes.size + 1](bytes);
		bytes[bytes.size - 1] = in_intf.dout;
	end
	else begin					//End of burst
		pkt = new();
		pkt.data = new[bytes.size](bytes);
		$display ("Driver received packet:");
		pkt.display();
		drvr_rx2sb.put(pkt);	//Place in Scoreboard
		bytes.delete();
	end
  end
endtask : rx

endclass

`endif

