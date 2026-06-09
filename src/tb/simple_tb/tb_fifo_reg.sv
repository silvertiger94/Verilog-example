`include "include.svh"

module tb_fifo_reg;
  logic clk;
  logic resetn;
  logic [31:0] push_data;
  logic push;
  logic pop;
  logic [31:0] pop_data;


  event init;

  // Place on your DUT
  fifo_reg #(
      .DATA_WIDTH(32),
      .FIFO_DEPTH(4)
  ) u_dut (
      .clk(clk),
      .resetn(resetn),
      .push(push),
      .push_data(push_data),
      .pop(pop),

      // Outputs
      .pop_data(),
      .full(),
      .empty()
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
  end

  always #1 clk = ~clk;

  always @(posedge clk) begin
    push_data <= $urandom;
    push <= $urandom;
    pop <= $urandom;
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
