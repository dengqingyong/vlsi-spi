class packet extends uvm_sequence_item; 

randc bit [7:0] length; 		//Burst Length;
rand bit [7:0] data []; 		//Payload
randc logic [7:0] init_addr; 	//Start burst from this address
rand logic wr_rd; 				//'0' - Read ; '1' - Write

`uvm_object_utils_begin(packet)
  `uvm_field_int(length , UVM_ALL_ON)
  `uvm_field_array_int(data, UVM_ALL_ON)
  `uvm_field_int(init_addr , UVM_ALL_ON)
  `uvm_field_int(wr_rd , UVM_ALL_ON)
`uvm_object_utils_end

function new(string name="packet");
   super.new(name);
endfunction : new

endclass : packet 
