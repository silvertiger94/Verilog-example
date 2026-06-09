`include "include.svh"

module priority_arbiter #(
    parameter int NUM_PORT = 4
) (
    input wire clk,
    input wire resetn,

    input  wire  request[NUM_PORT],
    output logic grant  [NUM_PORT]
);

  logic grant_w[NUM_PORT];

  // grant priority with LSB of request
  always_comb begin : grant_priority
    // initialize grant_w
    for (int i = 0; i < NUM_PORT; i++) begin
      grant_w[i] = 1'b0;
    end
    // Assign grant_w
    for (int i = 0; i < NUM_PORT; i++) begin
      if (request[i]) begin
        grant_w[i] = 1'b1;
        break;
      end
    end
  end

  genvar i;
  generate
    for (i = 0; i < NUM_PORT; i++) begin : gen_output_reg
      always_ff @(posedge clk or negedge resetn) begin
        if (!resetn)
          grant[i] <= 0;
        else
          grant[i] <= grant_w[i];
      end
    end
  endgenerate

endmodule
