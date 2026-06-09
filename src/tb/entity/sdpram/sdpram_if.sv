interface sdpram_if (input logic clk);
  logic        resetn;
  logic [1:0]  addra;
  logic [31:0] dina;
  logic        wea;
  logic        ena;
  logic [1:0]  addrb;
  logic        enb;
  logic [31:0] doutb;
endinterface
