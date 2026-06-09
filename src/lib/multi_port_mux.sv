`include "include.svh"

module multi_port_mux #(
    parameter int DATA_WIDTH = 7,
    parameter int NUM_PORT   = 3,
    parameter int SEL_WIDTH  = $clog2(NUM_PORT)
) (
    input  wire  [ SEL_WIDTH-1:0] sel,
    input  wire  [DATA_WIDTH-1:0] data_in [NUM_PORT],
    output logic [DATA_WIDTH-1:0] data_out
);

  // Mux Wiring
  always_comb begin : data_out_selection
    if (sel < NUM_PORT) begin
      data_out = data_in[sel];
    end else begin
      data_out = {DATA_WIDTH{1'b0}};  // 기본값으로 0을 설정
    end
  end

endmodule
