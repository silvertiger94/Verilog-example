`include "include.svh"

module synchronizer (
    input wire clk,
    input wire resetn,

    input  wire  d,
    output logic q
);
  logic d_int;

  always_ff @(posedge clk or negedge resetn) begin
    if (!resetn)
      d_int <= 0;
    else
      d_int <= d;
  end
  always_ff @(posedge clk or negedge resetn) begin
    if (!resetn)
      q <= 0;
    else
      q <= d_int;
  end


endmodule
