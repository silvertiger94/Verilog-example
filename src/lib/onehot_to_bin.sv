`include "include.svh"

module onehot_to_bin #(
    parameter int ONEHOT_WIDTH = 8,
    parameter int BIN_WIDTH = (ONEHOT_WIDTH == 1) ? 'b1 : $clog2(ONEHOT_WIDTH)
) (
    input wire [ONEHOT_WIDTH-1:0] onehot,
    output logic [BIN_WIDTH-1:0] bin
);

  for (genvar j = 0; j < BIN_WIDTH; j++) begin : gen_jl
    logic [ONEHOT_WIDTH-1:0] tmp_mask;
    for (genvar i = 0; i < ONEHOT_WIDTH; i++) begin : gen_il
      logic [BIN_WIDTH-1:0] tmp_i;
      assign tmp_i = BIN_WIDTH'(i);
      assign tmp_mask[i] = tmp_i[j];
    end
    assign bin[j] = |(tmp_mask & onehot);
  end
endmodule
