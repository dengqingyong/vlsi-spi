`ifndef GUARD_RECEIVER
`define GUARD_RECEIVER

class Receiver;	//SPI Slave

virtual spi_interface.MASTER_SPI spi_intf;
mailbox rcvr_rx2sb;
mailbox rcvr_tx2sb;
bit cpol = 0;
bit cpha = 0;

//// constructor method ////
function new(virtual spi_interface.MASTER_SPI  spi_intf_new, 
			mailbox rcvr_tx2sb, mailbox rcvr_rx2sb);
   this.spi_intf    = spi_intf_new  ;
   if((rcvr_rx2sb == null) or (rcvr_tx2sb == null)
   begin
     $display(" **ERROR**: Receiver mailbox is null");
     $finish;
   end
   else
   this.rcvr_tx2sb = rcvr_tx2sb;
   this.rcvr_rx2sb = rcvr_rx2sb;
endfunction : new  

task start();
logic [data_width_c -1:0] rx_bytes[];
logic [data_width_c -1:0] tx_bytes[];
logic [data_width_c -1:0] tx_data;
logic [data_width_c -1:0] rx_data;
int 					  rx_cnt;
int 					  tx_cnt;

packet rx_pkt;
packet tx_pkt;
  forever
  begin
    tx_data = data_width_c'd0; 
	wait(spi_intf.cb.spi_ss == 0);
	if (cpha = 0)	//Propagate data
		spi_int.cb.spi_miso <= 0;
    while (spi_intf.cb.spi_ss == 0)
    begin
	   rx_cnt 	= 0;
	   tx_cnt	= 0;
	   while ((rx_cnt + tx_cnt < data_width_c*2 - 2) and spi_intf.cb.spi_ss == 0)	//TX and RX one byte
	   begin
			@(posedge spi_intf.cb.spi_clk or negedge spi_intf.cb.spi_clk or posedge spi_intf.cb.spi_ss);		//SPI_CLK Event or Asserting SPI_SS
			if ((cpol == 0) and (cpha == 0) and (spi_intf.cb.spi_clk == 0)) 	//Propagate data
			or ((cpol == 0) and (cpha == 1) and (spi_intf.cb.spi_clk == 1))		
			or ((cpol == 1) and (cpha == 0) and (spi_intf.cb.spi_clk == 1))		
			or ((cpol == 1) and (cpha == 1) and (spi_intf.cb.spi_clk == 0))		
			begin
				spi_int.cb.spi_miso <= tx_data[tx_cnt];
				tx_cnt++;
			end
			
			else if ((cpol == 0) and (cpha == 0) and (spi_intf.cb.spi_clk == 1)) 	//Sample data
			or ((cpol == 0) and (cpha == 1) and (spi_intf.cb.spi_clk == 0))	
			or ((cpol == 1) and (cpha == 0) and (spi_intf.cb.spi_clk == 0))	
			or ((cpol == 1) and (cpha == 1) and (spi_intf.cb.spi_clk == 1))	
			begin
				rx_data[rx_cnt]	<= spi_int.cb.spi_mosi;
				rx_cnt ++;
			end
	   end	//End repeat
	   
	   if (spi_intf.cb.spi_ss == 0)	//Store received data
	   begin
		rx_bytes = new[rx_bytes.size + 1](rx_bytes);
		rx_bytes[rx_bytes.size - 1] = rx_data;
		
		tx_bytes = new[tx_bytes.size + 1](tx_bytes);
		tx_bytes[tx_bytes.size - 1] = tx_data;
		tx_data = tx_data + 1;
	   end
    end
    $display(" %0d : Receiver : Received a packet of length %0d",$time,rx_bytes.size);
    //Place received data to Scoreboard
	rx_pkt = new();
    rx_pkt.data = new rx_bytes;
    rx_pkt.display();
    rcvr_rx2sb.put(rx_pkt); 
    rx_bytes.delete();   
	
    //Place transmitted data to Scoreboard
	tx_pkt = new();
    tx_pkt.data = new tx_bytes;
    rcvr_tx2sb.put(tx_pkt); 
    tx_bytes.delete(); 
	
  end
endtask : start

endclass

`endif
