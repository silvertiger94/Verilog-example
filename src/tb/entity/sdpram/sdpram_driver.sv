class sdpram_driver extends uvm_driver #(sdpram_seq_item);
  `uvm_component_utils(sdpram_driver)

  virtual sdpram_if vif;

  function new(string name = "sdpram_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(virtual sdpram_if)::get(this, "", "vif", vif))
      `uvm_fatal("CFG_ERR", "virtual sdpram_if not found in config_db")
  endfunction

  task run_phase(uvm_phase phase);
    sdpram_seq_item req;

    // Initialize driving signals (reset driven by clock_reset_env)
    vif.addra <= '0;
    vif.dina  <= '0;
    vif.wea   <= 0;
    vif.ena   <= 0;
    vif.addrb <= '0;
    vif.enb   <= 0;

    // Wait for reset to be released by clock_reset_env
    @(posedge vif.resetn);

    forever begin
      seq_item_port.get_next_item(req);
      @(posedge vif.clk);
      vif.addra <= req.addra;
      vif.dina  <= req.dina;
      vif.wea   <= req.wea;
      vif.ena   <= req.ena;
      vif.addrb <= req.addrb;
      vif.enb   <= req.enb;
      seq_item_port.item_done();
    end
  endtask

endclass
