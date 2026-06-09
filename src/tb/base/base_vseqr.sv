class base_vseqr extends uvm_sequencer;
  `uvm_component_utils(base_vseqr)

  virtual clock_reset_if clock_reset_vif;
  generic_dut_seqr #() m_generic_dut_seqr;

  function new(string name = "base_vseqr", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual clock_reset_if)::get(this, "", "clk_rst_vif", clock_reset_vif))
      `uvm_fatal("CFG_ERR", "virtual clock_reset_if not found in config_db")
    m_generic_dut_seqr = generic_dut_seqr #()::type_id::create("m_generic_dut_seqr", this);
  endfunction

endclass
