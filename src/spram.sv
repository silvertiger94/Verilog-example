`include "include.svh"

module spram #(
    parameter int DATA_WIDTH = 32,
    parameter int WORD_DEPTH = 2
) (
    input wire [DATA_WIDTH-1:0] din,
    input wire [WORD_DEPTH-1:0] addr,
    input wire wen,
    input wire en,
    input wire clk,
    input wire resetn,

    output logic [DATA_WIDTH-1:0] dout
);

  // memory register
  logic [DATA_WIDTH-1:0] mem_array  [2**WORD_DEPTH];
  logic [DATA_WIDTH-1:0] mem_array_d[2**WORD_DEPTH];
  logic [DATA_WIDTH-1:0] dout_d;

  /* always_ff 을 사용하지 않은, macro를 이용한 구현 */
  always_comb begin
    foreach (mem_array_d[i]) mem_array_d[i] = mem_array[i];
    dout_d = dout;

    if (en) begin
      if (!resetn) begin
        dout_d = 'd0;
      end else if (wen) begin
        mem_array_d[addr] = din;
      end else dout_d = mem_array[addr];
    end
  end

  `FF_ASYNC(clk, resetn, dout, dout_d, 0)
  generate
    for (genvar i = 0; i < 2 ** WORD_DEPTH; i++) begin : gen_wordline_reg
      `FF_ASYNC(clk, resetn, mem_array[i], mem_array_d[i], 0)
    end
  endgenerate
endmodule
