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

  always_ff @(posedge clk or negedge resetn) begin
    if (!resetn)
      dout <= 0;
    else
      dout <= dout_d;
  end
  generate
    for (genvar i = 0; i < 2 ** WORD_DEPTH; i++) begin : gen_wordline_reg
      always_ff @(posedge clk or negedge resetn) begin
        if (!resetn)
          mem_array[i] <= 0;
        else
          mem_array[i] <= mem_array_d[i];
      end
    end
  endgenerate
endmodule
