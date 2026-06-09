class sdpram_base_seq extends uvm_sequence #(sdpram_seq_item);
  `uvm_object_utils(sdpram_base_seq)

  int unsigned num_trans = 100;

  function new(string name = "sdpram_base_seq");
    super.new(name);
  endfunction

  task body();
    sdpram_seq_item item;
    repeat (num_trans) begin
      item = sdpram_seq_item::type_id::create("item");
      start_item(item);
      if (!item.randomize())
        `uvm_fatal("RAND_FAIL", "Randomization failed")
      finish_item(item);
    end
  endtask

endclass
