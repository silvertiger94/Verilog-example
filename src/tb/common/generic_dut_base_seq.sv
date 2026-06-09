// Base sequence for all generic-interface DUT sequences.
// Subclasses override body() and drive only the signals their DUT needs;
// unused signals stay at their last-driven value (typically 0 after reset).
class generic_dut_base_seq #(
    parameter int ADDR_W = 8,
    parameter int DATA_W = 32
) extends uvm_sequence;
  `uvm_object_param_utils(generic_dut_base_seq#(ADDR_W, DATA_W))
  `uvm_declare_p_sequencer(generic_dut_seqr#(ADDR_W, DATA_W))

  function new(string name = "generic_dut_base_seq");
    super.new(name);
  endfunction

  virtual task wait_for_clock();
    @(posedge p_sequencer.clock_reset_vif.clk);
  endtask

  virtual task wait_for_reset();
    wait (p_sequencer.clock_reset_vif.resetn === 1'b1);
  endtask

  virtual task assert_reset(int unsigned cycles = 4);
    p_sequencer.clock_reset_vif.resetn <= 1'b0;
    repeat (cycles) @(posedge p_sequencer.clock_reset_vif.clk);
    @(negedge p_sequencer.clock_reset_vif.clk);
    p_sequencer.clock_reset_vif.resetn <= 1'b1;
  endtask

  virtual task body();
  endtask

endclass
