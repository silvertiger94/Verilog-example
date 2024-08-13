`include "include.svh"

module sdpram #(
    parameter int DATA_WIDTH = 32,
    parameter int WORD_DEPTH = 2
) (
    input wire clk,
    input wire resetn,
    input wire [WORD_DEPTH-1:0] addra,
    input wire [DATA_WIDTH-1:0] dina,
    input wire wea,
    input wire ena,

    input wire [WORD_DEPTH-1:0] addrb,
    input wire enb,

    output logic [DATA_WIDTH-1:0] doutb
);

  logic [DATA_WIDTH-1:0] mem_array [2**WORD_DEPTH];
  logic [DATA_WIDTH-1:0] read_data;

  always_ff @(posedge clk) begin : mem_array_write
    if (ena) begin
      if (wea) mem_array[addra] <= dina;
    end
  end

  assign read_data = (enb) ? mem_array[addrb] : 0;
  `FF_ASYNC(clk, resetn, doutb, read_data, 0)
endmodule
