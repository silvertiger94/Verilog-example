`include "include.svh"

module tb_spram;
  logic clk;
  logic resetn;
  logic [1:0] addr;
  logic [31:0] din;
  logic wen;
  logic en;

  logic [31:0] dout;

  event init;

  // Place on your DUT
  spram #(
      .DATA_WIDTH(32),
      .WORD_DEPTH(2)
  ) u_dut (
      din,
      addr,
      wen,
      en,
      clk,
      resetn,

      dout
  );

  initial begin
    en = 1;
    clk = 1;
    resetn = 0;
    #10;
    ->init;
    #1000 $finish;
  end

  // Test Sequence
  // Initial Begin
  always @(init) begin
    resetn <= 1;
  end

  always #1 clk = ~clk;

  always begin
    // To Synchronize posegde clk
    #2;
    din  <= $urandom;
    // 0 - 3 value
    addr <= $urandom % 4;
    wen  <= $urandom;
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
