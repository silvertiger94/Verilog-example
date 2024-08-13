`include "include.svh"

module tb_sdpram;
  logic clk;
  logic resetn;
  logic [1:0] addra;
  logic [31:0] dina;
  logic [1:0] addrb;
  logic wea;
  logic ena;
  logic enb;

  logic [31:0] doutb;

  event init;

  // Place on your DUT
  sdpram #(
      .DATA_WIDTH(32),
      .WORD_DEPTH(2)
  ) u_dut (
      .clk(clk),
      .resetn(resetn),
      .addra(addra),
      .dina(dina),
      .wea(wea),
      .ena(ena),
      .addrb(addrb),
      .enb(enb),
      .doutb(doutb)
  );

  /*
  // Test Sequence
  initial begin
    clk <= 1;
    resetn <= 0;
    #10 resetn <= 1;
    ena <= 1;
    enb <= 1;
    #1000 $finish;
  end */

  initial begin
    clk = 1;
    resetn = 0;
    #10;
    ->init;
    #1000 $finish;
  end

  // Test Sequence
  always @(init) begin
    resetn <= 1;
    ena <= 1;
    enb <= 1;
  end

  always #1 clk = ~clk;

  always @(posedge clk) begin
    dina  <= $urandom;
    // 0 - 3 value
    addra <= $urandom % 4;
    addrb <= $urandom % 4;
    wea   <= $urandom;
  end

  // Print some stuff as an example
  initial begin
    if ($test$plusargs("trace") != 0) begin
      $display("[%0t] Tracing to logs/vlt_dump.vcd...\n", $time);
      $dumpfile("logs/vlt_dump.vcd");
      $dumpvars();
    end
    $display("[%0t] Model running...\n", $time);
  end
endmodule
