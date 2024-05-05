`include "include.svh"

module spram #(
    parameter int DATA_WIDTH = 32,
    parameter int WORD_DEPTH = 2
) (
    input wire clk,
    input wire resetn,
    input wire [WORD_DEPTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] din,
    input wire wen,

    output logic [DATA_WIDTH-1:0] dout
);

  logic [DATA_WIDTH-1:0] mem_array[2**WORD_DEPTH];


  always_ff @(posedge clk or negedge resetn) begin
    if (!resetn) dout <= 0;
    else if (wen) mem_array[addr] <= din;
    else dout <= mem_array[addr];
  end

  // or like this..
  /*
  logic [DATA_WIDTH-1:0] din_w;
  assign din_w = (wen) ? din : mem_array[addr];

  `FF_ASYNC(clk, resetn, mem_array[addr], din_w, 0)
  `FF_ASYNC(clk, resetn, dout, mem_array[addr], 0)
  */
endmodule
