`ifndef GUARD_RECEIVER
`define GUARD_RECEIVER
`include "Globals.sv"
`include "Packet.sv"
class Receiver;	//SPI Slave

virtual spi_interface.MASTER_SPI spi_intf;
mailbox rcvr_rx2sb;
mailbox rcvr_tx2sb;
bit cpol = 0;
bit cpha = 0;
int receiver_sernum;	//Serial Number

//// constructor method ////
function new(virtual spi_interface.MASTER_SPI  spi_intf_new, 
			mailbox rcvr_tx2sb, mailbox rcvr_rx2sb,
			int receiver_sernum_new);
   this.spi_intf    = spi_intf_new  ;
   if((rcvr_rx2sb == null) || (rcvr_tx2sb == null))
   begin
     $display(" **ERROR**: Receiver mailbox is null");
     $finish;
   end
   else begin
	this.rcvr_tx2sb 		= rcvr_tx2sb;
	this.rcvr_rx2sb 		= rcvr_rx2sb;
	this.receiver_sernum	= receiver_sernum_new;
   end
endfunction : new  

task cfg_cpolpha(bit cpol_new, bit cpha_new);
	this.cpol = cpol_new;
	this.cpha = cpha_new;
endtask : cfg_cpolpha

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
    rx_cnt 	= 0;
    tx_cnt	= 0;
    tx_data = 1; 
	spi_intf.spi_miso <= 1'bz;
	@(negedge spi_intf.spi_ss[receiver_sernum]);
	if (cpha == 0)	//Propagate data
	begin
		spi_intf.spi_miso <= tx_data[0];
		tx_cnt	= 1;
	end
    while (spi_intf.spi_ss[receiver_sernum] == 0)
    begin
	   while ((rx_cnt + tx_cnt < data_width_c*2) && spi_intf.spi_ss[receiver_sernum] == 0)	//TX and RX one byte
	   begin
			@(posedge spi_intf.spi_clk or negedge spi_intf.spi_clk or posedge spi_intf.spi_ss[receiver_sernum]);		//SPI_CLK Event or Asserting spi_ss[receiver_sernum]
			if (((cpol == 0) && (cpha == 0) && (spi_intf.spi_clk == 0)) 	//Propagate data
			|| ((cpol == 0) && (cpha == 1) && (spi_intf.spi_clk == 1))		
			|| ((cpol == 1) && (cpha == 0) && (spi_intf.spi_clk == 1))		
			|| ((cpol == 1) && (cpha == 1) && (spi_intf.spi_clk == 0)))
			begin
				spi_intf.spi_miso <= tx_data[tx_cnt];
				tx_cnt++;
			end
			
			else if (((cpol == 0) && (cpha == 0) && (spi_intf.spi_clk == 1)) 	//Sample data
			|| ((cpol == 0) && (cpha == 1) && (spi_intf.spi_clk == 0))	
			|| ((cpol == 1) && (cpha == 0) && (spi_intf.spi_clk == 0))	
			|| ((cpol == 1) && (cpha == 1) && (spi_intf.spi_clk == 1)))	
			begin
				rx_data[rx_cnt]	= spi_intf.spi_mosi;
				rx_cnt ++;
			end
	   end	//End while
	   rx_cnt 	= 0;
	   tx_cnt	= 0;
	   
	   
	   if (spi_intf.spi_ss[receiver_sernum] == 0)	//Store received data
	   begin
		rx_bytes = new[rx_bytes.size + 1](rx_bytes);
		rx_bytes[rx_bytes.size - 1] = rx_data;
		
		tx_bytes = new[tx_bytes.size + 1](tx_bytes);
		tx_bytes[tx_bytes.size - 1] = tx_data;
		tx_data = tx_data + 1;
	   end
    end
    $display(" %0d : Receiver : Received a packet of length %0d:",$time,rx_bytes.size);
    //Place received data to Scoreboard
	rx_pkt = new();
    rx_pkt.data = new [rx_bytes.size](rx_bytes);
    rx_pkt.display();
    rcvr_rx2sb.put(rx_pkt); 
    rx_bytes.delete();   
	
    //Place transmitted data to Scoreboard
	tx_pkt = new();
    tx_pkt.data = new[tx_bytes.size](tx_bytes);
    $display ("Receiver transmitted packet:");
	tx_pkt.display();
    rcvr_tx2sb.put(tx_pkt); 
    tx_bytes.delete(); 
	
  end
endtask : start

endclass

`endif
