// Single-port RAM (spram) write — drives addr_a, data_in, wen, en_a.
class spram_write_seq #(
  parameter int ADDR_W = 8,
  parameter int DATA_W = 32
) extends generic_dut_base_seq #(ADDR_W, DATA_W);
  `uvm_object_param_utils(spram_write_seq #(ADDR_W, DATA_W))

  logic [ADDR_W-1:0] addr;
  logic [DATA_W-1:0] data;

  function new(string name = "spram_write_seq");
    super.new(name);
  endfunction

  virtual task body();
    wait_for_clock();
    p_sequencer.vif.addr_a  <= addr;
    p_sequencer.vif.data_in <= data;
    p_sequencer.vif.wen     <= 1'b1;
    p_sequencer.vif.en_a    <= 1'b1;
    wait_for_clock();
    p_sequencer.vif.wen  <= 1'b0;
    p_sequencer.vif.en_a <= 1'b0;
  endtask

endclass

// Single-port RAM (spram) read — drives addr_a, en_a; captures data_out.
class spram_read_seq #(
  parameter int ADDR_W = 8,
  parameter int DATA_W = 32
) extends generic_dut_base_seq #(ADDR_W, DATA_W);
  `uvm_object_param_utils(spram_read_seq #(ADDR_W, DATA_W))

  logic [ADDR_W-1:0] addr;
  logic [DATA_W-1:0] rdata;

  function new(string name = "spram_read_seq");
    super.new(name);
  endfunction

  virtual task body();
    wait_for_clock();
    p_sequencer.vif.addr_a <= addr;
    p_sequencer.vif.wen    <= 1'b0;
    p_sequencer.vif.en_a   <= 1'b1;
    wait_for_clock();
    p_sequencer.vif.en_a <= 1'b0;
    rdata = p_sequencer.vif.data_out;
  endtask

endclass

// Simple dual-port RAM (sdpram) write — drives port-A.
class sdpram_write_seq #(
  parameter int ADDR_W = 8,
  parameter int DATA_W = 32
) extends generic_dut_base_seq #(ADDR_W, DATA_W);
  `uvm_object_param_utils(sdpram_write_seq #(ADDR_W, DATA_W))

  logic [ADDR_W-1:0] addr;
  logic [DATA_W-1:0] data;

  function new(string name = "sdpram_write_seq");
    super.new(name);
  endfunction

  virtual task body();
    wait_for_clock();
    p_sequencer.vif.addr_a  <= addr;
    p_sequencer.vif.data_in <= data;
    p_sequencer.vif.wen     <= 1'b1;
    p_sequencer.vif.en_a    <= 1'b1;
    wait_for_clock();
    p_sequencer.vif.wen  <= 1'b0;
    p_sequencer.vif.en_a <= 1'b0;
  endtask

endclass

// Simple dual-port RAM (sdpram) read — drives port-B; captures data_out.
class sdpram_read_seq #(
  parameter int ADDR_W = 8,
  parameter int DATA_W = 32
) extends generic_dut_base_seq #(ADDR_W, DATA_W);
  `uvm_object_param_utils(sdpram_read_seq #(ADDR_W, DATA_W))

  logic [ADDR_W-1:0] addr;
  logic [DATA_W-1:0] rdata;

  function new(string name = "sdpram_read_seq");
    super.new(name);
  endfunction

  virtual task body();
    wait_for_clock();
    p_sequencer.vif.addr_b <= addr;
    p_sequencer.vif.en_b   <= 1'b1;
    wait_for_clock();
    p_sequencer.vif.en_b <= 1'b0;
    rdata = p_sequencer.vif.data_out;
  endtask

endclass
