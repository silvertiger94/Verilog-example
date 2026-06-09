class sdpram_env extends uvm_env;
  `uvm_component_utils(sdpram_env)

  sdpram_agent      agent;
  sdpram_scoreboard scoreboard;

  function new(string name = "sdpram_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agent      = sdpram_agent::type_id::create("agent", this);
    scoreboard = sdpram_scoreboard::type_id::create("scoreboard", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    agent.monitor.ap.connect(scoreboard.analysis_export);
  endfunction

endclass
