// FIFO push — drives push, push_data; waits if full.
class fifo_push_seq #(
  parameter int ADDR_W = 8,
  parameter int DATA_W = 32
) extends generic_dut_base_seq #(ADDR_W, DATA_W);
  `uvm_object_param_utils(fifo_push_seq #(ADDR_W, DATA_W))

  logic [DATA_W-1:0] data;

  function new(string name = "fifo_push_seq");
    super.new(name);
  endfunction

  virtual task body();
    wait (!p_sequencer.vif.full);
    wait_for_clock();
    p_sequencer.vif.push      <= 1'b1;
    p_sequencer.vif.push_data <= data;
    wait_for_clock();
    p_sequencer.vif.push <= 1'b0;
  endtask

endclass

// FIFO pop — drives pop; captures pop_data; waits if empty.
class fifo_pop_seq #(
  parameter int ADDR_W = 8,
  parameter int DATA_W = 32
) extends generic_dut_base_seq #(ADDR_W, DATA_W);
  `uvm_object_param_utils(fifo_pop_seq #(ADDR_W, DATA_W))

  logic [DATA_W-1:0] rdata;

  function new(string name = "fifo_pop_seq");
    super.new(name);
  endfunction

  virtual task body();
    wait (!p_sequencer.vif.empty);
    wait_for_clock();
    p_sequencer.vif.pop <= 1'b1;
    wait_for_clock();
    p_sequencer.vif.pop <= 1'b0;
    rdata = p_sequencer.vif.pop_data;
  endtask

endclass
