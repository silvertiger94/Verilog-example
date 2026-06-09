class base_test extends uvm_test;
  `uvm_component_utils(base_test)

  base_env m_base_env;

  function new(string name = "base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    m_base_env = base_env::type_id::create("m_base_env", this);
  endfunction

  function void end_of_elaboration_phase(uvm_phase phase);
    uvm_root::get().print_topology();
  endfunction

  task run_phase(uvm_phase phase);
    base_vseq m_base_vseq;
    phase.raise_objection(this);
    m_base_vseq = base_vseq::type_id::create("m_base_vseq");
    m_base_vseq.start(m_base_env.m_base_vseqr);
    phase.drop_objection(this);
  endtask

  function void report_phase(uvm_phase phase);
    uvm_report_server svr = uvm_report_server::get_server();
    if (svr.get_severity_count(UVM_FATAL) + svr.get_severity_count(UVM_ERROR) == 0)
      `uvm_info(get_type_name(), "*** TEST PASSED ***", UVM_NONE)
    else `uvm_error(get_type_name(), "*** TEST FAILED ***")
  endfunction

endclass
