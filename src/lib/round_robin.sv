module round_robin #(
    parameter int NUM_PORT = 4
) (
    input wire clk,
    input wire resetn,

    input  wire request[NUM_PORT],
    output wire grant  [NUM_PORT]
);

  logic [NUM_PORT-1:0] grant_last;
  logic grant_w[NUM_PORT];

  // grant priority with round-robin
  always_comb begin
    grant_last = 'd0;
    for (int i = 0; i < NUM_PORT; i++) begin
      if (request[i] == grant_last) begin
        grant_last++;
        grant_w[i] = 1'b1;
      end
    end
  end
endmodule
