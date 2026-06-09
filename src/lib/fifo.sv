`include "include.svh"

module fifo_reg #(
    parameter int FIFO_DEPTH = 4,
    parameter int DATA_WIDTH = 32
) (
    // Inputs
    input wire clk,
    input wire resetn,
    input wire push,
    input wire [DATA_WIDTH-1:0] push_data,
    input wire pop,

    // Outputs
    output logic [DATA_WIDTH-1:0] pop_data,
    output logic full,
    output logic empty
);
  // Internal signals
  logic [DATA_WIDTH-1:0] fifo[FIFO_DEPTH];
  logic [DATA_WIDTH-1:0] fifo_indata;
  logic [FIFO_DEPTH:0] wptr;
  logic [FIFO_DEPTH:0] rptr;
  logic [FIFO_DEPTH:0] wptr_nxt;
  logic [FIFO_DEPTH:0] rptr_nxt;

  logic push_int;
  logic pop_int;

  assign full = ((wptr[FIFO_DEPTH] != rptr[FIFO_DEPTH] ) && (wptr[FIFO_DEPTH-1:0] == rptr[FIFO_DEPTH-1:0])) ? 'd1 : 'd0;
  assign empty = (wptr == rptr) ? 'd1 : 'd0;

  assign push_int = push & ~full;
  assign pop_int = pop & ~empty;

  always_comb begin
    // write
    if (push_int) begin
      wptr_nxt = wptr + 1;
      fifo_indata = push_data;
    end else begin
      wptr_nxt = wptr;
      fifo_indata = fifo[wptr];
    end

    // read
    if (pop_int) rptr_nxt = rptr + 1;
    else rptr_nxt = rptr;
  end

  // register
  always_ff @(posedge clk) begin
    wptr <= (!resetn) ? 0 : wptr_nxt;
  end
  always_ff @(posedge clk) begin
    rptr <= (!resetn) ? 0 : rptr_nxt;
  end
  always_ff @(posedge clk) begin
    fifo[wptr] <= (!resetn) ? 0 : fifo_indata;
  end
  always_ff @(posedge clk) begin
    pop_data <= (!resetn) ? 0 : fifo[rptr];
  end

endmodule

module fifo_sram #(
    parameter int FIFO_DEPTH = 4,
    parameter int DATA_WIDTH = 32
) (
    // Inputs
    input wire clk,
    input wire rst_n,
    input wire push,
    input wire [DATA_WIDTH-1:0] push_data,
    input wire pop,

    // Outputs
    output logic [DATA_WIDTH-1:0] pop_data,
    output logic full,
    output logic empty
);
  // Internal signals
  logic [DATA_WIDTH-1:0] fifo[FIFO_DEPTH];

endmodule
