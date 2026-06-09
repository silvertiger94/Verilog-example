class sdpram_agent extends uvm_agent;
  `uvm_component_utils(sdpram_agent)

  sdpram_driver                    driver;
  sdpram_monitor                   monitor;
  uvm_sequencer #(sdpram_seq_item) sequencer;

  function new(string name = "sdpram_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    driver    = sdpram_driver::type_id::create("driver", this);
    monitor   = sdpram_monitor::type_id::create("monitor", this);
    sequencer = uvm_sequencer #(sdpram_seq_item)::type_id::create("sequencer", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    driver.seq_item_port.connect(sequencer.seq_item_export);
  endfunction

endclass
