class base_vseq extends uvm_sequence;
  `uvm_object_utils(base_vseq)
  `uvm_declare_p_sequencer(base_vseqr)

  int unsigned reset_cycles   = 4;
  int unsigned half_period_ns = 5;

  function new(string name = "base_vseq", uvm_component parent = null);
    super.new(name);
  endfunction

  // base sequence helper task
  extern virtual task assert_reset(int unsigned cycles = 4);
  extern virtual task wait_for_clock();
  extern virtual task wait_for_reset();

  virtual task body();
    // clock and reset initialization
    p_sequencer.clock_reset_vif.clk    <= 1'b0;
    p_sequencer.clock_reset_vif.resetn <= 1'b0;

    fork
      forever #(half_period_ns) p_sequencer.clock_reset_vif.clk = ~p_sequencer.clock_reset_vif.clk;
    join_none
    `uvm_info(get_type_name(), $sformatf("[%0t ns] Clock started (%0d MHz)", $time,
                                         1000 / (2 * half_period_ns)), UVM_LOW)

    repeat (reset_cycles) @(posedge p_sequencer.clock_reset_vif.clk);
    @(negedge p_sequencer.clock_reset_vif.clk);
    p_sequencer.clock_reset_vif.resetn <= 1'b1;
    `uvm_info(get_type_name(), $sformatf("[%0t ns] Reset released after %0d cycles", $time,
                                         reset_cycles), UVM_LOW)

    // test main sequence — sdpram write then read
    begin
      sdpram_write_seq #() wr_seq;
      sdpram_read_seq #()  rd_seq;

      for (int i = 0; i < 4; i++) begin
        wr_seq      = sdpram_write_seq#()::type_id::create("wr_seq");
        wr_seq.addr = 8'(i);
        wr_seq.data = 32'hA000_0000 | 32'(i);
        wr_seq.start(p_sequencer.m_generic_dut_seqr);
        `uvm_info(get_type_name(), $sformatf(
                  "[SDPRAM] Write addr=0x%02h data=0x%08h", i, wr_seq.data), UVM_LOW)
      end

      for (int i = 0; i < 4; i++) begin
        rd_seq      = sdpram_read_seq#()::type_id::create("rd_seq");
        rd_seq.addr = 8'(i);
        rd_seq.start(p_sequencer.m_generic_dut_seqr);
        `uvm_info(get_type_name(), $sformatf(
                  "[SDPRAM] Read  addr=0x%02h data=0x%08h", i, rd_seq.rdata), UVM_LOW)
      end
      #10ns;
    end

  endtask
endclass

///////////////////////////////////////

task base_vseq::assert_reset(int unsigned cycles = 4);
  p_sequencer.clock_reset_vif.resetn <= 1'b0;
  repeat (cycles) @(posedge p_sequencer.clock_reset_vif.clk);
  @(negedge p_sequencer.clock_reset_vif.clk);
  p_sequencer.clock_reset_vif.resetn <= 1'b1;
  `uvm_info(get_type_name(), $sformatf("[%0t ns] Reset re-asserted for %0d cycles", $time, cycles),
            UVM_LOW)
endtask

task base_vseq::wait_for_reset();
  wait (p_sequencer.clock_reset_vif.resetn === 1'b1);
endtask

task base_vseq::wait_for_clock();
  @(posedge p_sequencer.clock_reset_vif.clk);
endtask
