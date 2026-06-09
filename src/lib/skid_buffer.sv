`include "include.svh"

module skid_buffer #(
    parameter int DATA_WIDTH = 0

) (
    input wire clk,
    input wire resetn,

    input wire i_valid,
    input wire [DATA_WIDTH-1:0] i_data,
    output logic i_ready,

    output logic o_valid,
    output logic [DATA_WIDTH-1:0] o_data,
    input wire o_ready
);
  logic r_valid;
  logic r_valid_w;
  logic [DATA_WIDTH-1:0] r_data;


  always_comb begin
    if ((i_valid && i_ready) && (o_valid && !o_ready)) r_valid_w = 1;
  end
  always_ff @(posedge clk) begin
    r_valid <= (!resetn) ? 0 : r_valid_w;
  end

  always_comb begin
    if (r_valid) o_data = r_data;
    else o_data = i_data;
  end

  always_comb begin
    o_valid = (i_valid || r_valid);
  end

  assign i_ready = o_ready | (~o_valid);




endmodule
