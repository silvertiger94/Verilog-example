class sdpram_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(sdpram_scoreboard)

  uvm_analysis_imp #(sdpram_seq_item, sdpram_scoreboard) analysis_export;

  // Reference memory model (4 entries, 32-bit wide)
  logic [31:0] ref_mem [4];
  // Track which addresses have been written at least once
  bit          mem_written [4];

  int pass_cnt;
  int fail_cnt;

  function new(string name = "sdpram_scoreboard", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    analysis_export = new("analysis_export", this);
    foreach (ref_mem[i])     ref_mem[i]     = '0;
    foreach (mem_written[i]) mem_written[i] = 0;
  endfunction

  // Called once per monitor transaction.
  // Timing: inputs reflect what DUT processed this cycle;
  // doutb is the registered output from this cycle
  // (reads mem BEFORE the write that also happens this cycle).
  function void write(sdpram_seq_item trans);
    logic [31:0] expected;

    // Check read output only for addresses that have been written
    if (trans.enb && mem_written[trans.addrb]) begin
      expected = ref_mem[trans.addrb];
      if (trans.doutb === expected) begin
        pass_cnt++;
        `uvm_info("SB", $sformatf("PASS addrb=%0h exp=%0h got=%0h",
                  trans.addrb, expected, trans.doutb), UVM_HIGH)
      end else begin
        fail_cnt++;
        `uvm_error("SB", $sformatf("FAIL addrb=%0h exp=%0h got=%0h",
                   trans.addrb, expected, trans.doutb))
      end
    end

    // Update reference model AFTER checking (doutb reads pre-write mem)
    if (trans.ena && trans.wea) begin
      ref_mem[trans.addra]    = trans.dina;
      mem_written[trans.addra] = 1;
    end
  endfunction

  function void report_phase(uvm_phase phase);
    `uvm_info("SB", $sformatf("Results: PASS=%0d  FAIL=%0d", pass_cnt, fail_cnt), UVM_NONE)
  endfunction

endclass
