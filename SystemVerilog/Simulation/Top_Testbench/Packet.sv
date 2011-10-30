`ifndef GUARD_PACKET
`define GUARD_PACKET

`define max_burst_c 20

class Packet extends uvm_sequence_item;

	parameter reset_polarity_g		=	0;		//RESET is active low
	parameter data_width_g			=	8;		//Data width
	parameter blen_width_g			=	9;		//Burst length width (maximum 2^9=512Kbyte Burst)
	parameter addr_width_g			=	10;		//Address width
	parameter reg_addr_width_g		=	8;		//SPI Registers address width
	parameter reg_din_width_g		=	8		//SPI Registers data width

    randc bit [blen_width_g - 1 : 0] 	length;	//Burst Length
    rand bit [data_width_g - 1:0] 		data[];	//Payload
    
    constraint payload_size_c { data.size inside { [1 : max_burst_c]};}
    
    constraint length_c {  length == data.size; } 
    
    function new(string name = "");
         super.new(name);
    endfunction : new
    
    // function void post_randomize();
    // endfunction : post_randomize
  
    `uvm_object_utils_begin(Packet)
		`uvm_field_int			(length, 	UVM_ALL_ON|UVM_NOPACK)
		`uvm_field_array_int	(data, 		UVM_ALL_ON|UVM_NOPACK)
    `uvm_object_utils_end
    
    function void do_pack(uvm_packer packer);
        super.do_pack(packer);
        //packer.pack_field_int(length,$bits(length));
        foreach(data[i])
          packer.pack_field_int(data[i], data_width_g);
    endfunction : do_pack
    
    function void do_unpack(uvm_packer packer);
        super.do_pack(packer);
        //length = packer.unpack_field_int($bits(length));
        data.delete();
        data = new[length];
        foreach(data[i])
          data[i] = packer.unpack_field_int(data_width_g);
    endfunction : do_unpack

endclass : Packet

`endif
