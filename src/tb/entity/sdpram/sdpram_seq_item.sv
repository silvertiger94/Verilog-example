class sdpram_seq_item extends uvm_sequence_item;
  `uvm_object_utils_begin(sdpram_seq_item)
    `uvm_field_int(addra, UVM_ALL_ON)
    `uvm_field_int(dina,  UVM_ALL_ON)
    `uvm_field_int(wea,   UVM_ALL_ON)
    `uvm_field_int(ena,   UVM_ALL_ON)
    `uvm_field_int(addrb, UVM_ALL_ON)
    `uvm_field_int(enb,   UVM_ALL_ON)
    `uvm_field_int(doutb, UVM_ALL_ON)
  `uvm_object_utils_end

  rand logic [1:0]  addra;
  rand logic [31:0] dina;
  rand logic        wea;
  rand logic        ena;
  rand logic [1:0]  addrb;
  rand logic        enb;
       logic [31:0] doutb;

  function new(string name = "sdpram_seq_item");
    super.new(name);
  endfunction
endclass
