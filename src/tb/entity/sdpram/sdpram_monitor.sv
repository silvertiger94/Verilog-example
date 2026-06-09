class sdpram_monitor extends uvm_monitor;
  `uvm_component_utils(sdpram_monitor)

  virtual sdpram_if              vif;
  uvm_analysis_port #(sdpram_seq_item) ap;

  function new(string name = "sdpram_monitor", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap = new("ap", this);
    if (!uvm_config_db #(virtual sdpram_if)::get(this, "", "vif", vif))
      `uvm_fatal("CFG_ERR", "virtual sdpram_if not found in config_db")
  endfunction

  task run_phase(uvm_phase phase);
    sdpram_seq_item trans;

    @(posedge vif.resetn);       // wait for reset de-assertion
    @(posedge vif.clk);          // skip the cycle immediately after reset

    forever begin
      trans = sdpram_seq_item::type_id::create("trans");

      @(posedge vif.clk);
      // Sample inputs in active region (before NBA) — these are the values
      // the DUT samples this cycle (driven by driver at the previous posedge).
      trans.addra = vif.addra;
      trans.dina  = vif.dina;
      trans.wea   = vif.wea;
      trans.ena   = vif.ena;
      trans.addrb = vif.addrb;
      trans.enb   = vif.enb;

      #1;
      // Sample output after NBA settling — doutb registered at this clock edge.
      trans.doutb = vif.doutb;

      ap.write(trans);
    end
  endtask

endclass
