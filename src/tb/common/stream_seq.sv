// Stream send — drives i_valid, i_data; waits until i_ready is asserted.
class stream_send_seq #(
  parameter int ADDR_W = 8,
  parameter int DATA_W = 32
) extends generic_dut_base_seq #(ADDR_W, DATA_W);
  `uvm_object_param_utils(stream_send_seq #(ADDR_W, DATA_W))

  logic [DATA_W-1:0] data;

  function new(string name = "stream_send_seq");
    super.new(name);
  endfunction

  virtual task body();
    wait_for_clock();
    p_sequencer.vif.i_valid <= 1'b1;
    p_sequencer.vif.i_data  <= data;
    // Hold valid until the handshake completes.
    do clk_tick();
    while (!p_sequencer.vif.i_ready);
    p_sequencer.vif.i_valid <= 1'b0;
  endtask

endclass

// Stream receive — asserts o_ready; captures o_data when o_valid is seen.
class stream_recv_seq #(
  parameter int ADDR_W = 8,
  parameter int DATA_W = 32
) extends generic_dut_base_seq #(ADDR_W, DATA_W);
  `uvm_object_param_utils(stream_recv_seq #(ADDR_W, DATA_W))

  logic [DATA_W-1:0] rdata;

  function new(string name = "stream_recv_seq");
    super.new(name);
  endfunction

  virtual task body();
    p_sequencer.vif.o_ready <= 1'b1;
    do clk_tick();
    while (!p_sequencer.vif.o_valid);
    rdata = p_sequencer.vif.o_data;
    wait_for_clock();
    p_sequencer.vif.o_ready <= 1'b0;
  endtask

endclass
