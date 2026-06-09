class generic_dut_seqr #(
    parameter int ADDR_W = 8,
    parameter int DATA_W = 32
) extends uvm_sequencer;
  `uvm_component_param_utils(generic_dut_seqr#(ADDR_W, DATA_W))

  virtual clock_reset_if         clock_reset_vif;
  virtual generic_dut_if #(ADDR_W, DATA_W) vif;

  function new(string name = "generic_dut_seqr", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual clock_reset_if)::get(this, "", "clk_rst_vif", clock_reset_vif))
      `uvm_fatal("CFG_ERR", "virtual clock_reset_if not found in config_db")
    if (!uvm_config_db#(virtual generic_dut_if #(ADDR_W, DATA_W))::get(this, "", "dut_vif", vif))
      `uvm_fatal("CFG_ERR", "virtual generic_dut_if not found in config_db")
  endfunction

endclass
