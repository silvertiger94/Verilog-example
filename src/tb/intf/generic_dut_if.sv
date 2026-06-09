interface generic_dut_if #(
  parameter int ADDR_W = 8,
  parameter int DATA_W = 32
);
  // Memory — spram (port-A only) / sdpram (port-A write, port-B read)
  logic [ADDR_W-1:0] addr_a;
  logic [DATA_W-1:0] data_in;
  logic              wen;
  logic              en_a;
  logic [ADDR_W-1:0] addr_b;
  logic              en_b;
  logic [DATA_W-1:0] data_out;

  // FIFO — fifo_reg
  logic              push;
  logic [DATA_W-1:0] push_data;
  logic              pop;
  logic [DATA_W-1:0] pop_data;
  logic              full;
  logic              empty;

  // Handshake / stream — skid_buffer
  logic              i_valid;
  logic [DATA_W-1:0] i_data;
  logic              i_ready;
  logic              o_valid;
  logic [DATA_W-1:0] o_data;
  logic              o_ready;

endinterface
