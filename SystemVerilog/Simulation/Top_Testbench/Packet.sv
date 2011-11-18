class packet extends uvm_sequence_item; 

rand bit [7:0] length; 			//Burst Length;
rand bit [7:0] data []; 		//Payload
rand logic [9:0] init_addr; 	//Start burst from this address
rand int wr_rd; 				//'0' - Read ; '1' - Write, '2' - Config
logic [7:0] conf_reg; 			//Configuration Register
logic [7:0] clk_reg; 			//Clock Register

`uvm_object_utils_begin(packet)
  `uvm_field_int(length , UVM_ALL_ON|UVM_NOCOMPARE)
  `uvm_field_array_int(data, UVM_ALL_ON|UVM_NOCOMPARE)
  `uvm_field_int(init_addr , UVM_ALL_ON|UVM_NOCOMPARE)
  `uvm_field_int(wr_rd , UVM_ALL_ON|UVM_NOCOMPARE)
  `uvm_field_int(conf_reg , UVM_ALL_ON|UVM_NOCOMPARE)
  `uvm_field_int(clk_reg , UVM_ALL_ON|UVM_NOCOMPARE)
`uvm_object_utils_end

constraint data_size_c {data.size == length + 1;}

constraint burst_len_c {data.size() + init_addr inside {[1:1024]};}

constraint wr_rd_c {wr_rd inside {0, 1, 2};}

constraint order1 { solve length before data; }
constraint order2 { solve data before init_addr; }
constraint order3 { solve length before init_addr; }

function new(string name="packet");
   super.new(name);
endfunction : new

virtual function bit do_compare (uvm_object rhs, uvm_comparer comparer);
	bit comp = 1'b1;
	packet rhs_;
	$cast (rhs_, rhs);
	if (rhs_.length != length ) begin
		comp = 1'b0;
		`uvm_error(get_type_name(),
		  $sformatf("Data mismatch.  Length are not equal. Expected : %0h.  Actual : %0h", 
		  length, rhs_.length))
	end	else begin
		foreach (data[i])
		begin
			comp = comp & (rhs_.data[i] == data[i]);
            if (!(rhs_.data[i] == data[i]))
			`uvm_error(get_type_name(),
              $sformatf("Data mismatch.  Index: %0d ; Expected (RAM) : %0h.  Actual (RX) : %0h", 
              i, rhs_.data[i], data[i]))
		end
	end
	do_compare = comp;
endfunction	:	do_compare

	virtual function uvm_object clone ();
		uvm_object pkt_;
		packet pkt 		= new();
		pkt.length 		= this.length;
		pkt.init_addr	= this.init_addr;
		pkt.wr_rd		= this.wr_rd;
		pkt.conf_reg	= this.conf_reg;
		pkt.clk_reg		= this.clk_reg;
		pkt.data		= new[this.length+1];
		foreach (this.data[i])
			pkt.data[i] = this.data[i];
		assert ($cast (pkt_, pkt));
		clone = pkt_;
	endfunction : clone
	
endclass : packet 
