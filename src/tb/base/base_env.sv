class base_env extends uvm_env;
  `uvm_component_utils(base_env)

  base_vseqr m_base_vseqr;

  function new(string name = "base_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    m_base_vseqr = base_vseqr::type_id::create("m_base_vseqr", this);
  endfunction

  function void connect_phase(uvm_phase phase);
  endfunction

  task run_phase(uvm_phase phase);

  endtask

endclass
