module tb_onehot_to_bin;
  // Parameters
  localparam DATA_WIDTH = 8;
  localparam SEL_WIDTH = $clog2(DATA_WIDTH);

  // Test Signals
  reg [ SEL_WIDTH-1:0] bin;
  reg [DATA_WIDTH-1:0] onehot;

  // Instantiate the Unit Under Test (UUT)
  onehot_to_bin #(
      .ONEHOT_WIDTH(DATA_WIDTH),
      .BIN_WIDTH(SEL_WIDTH)
  ) uut (
      .onehot(onehot),
      .bin(bin)
  );

  // Test Procedure
  initial begin
    // Initialize Inputs
    onehot = 0;

    // Apply Test Cases
    #10;
    onehot = 'b0;  // Test Case 1: Select input 0
    #10;
    onehot = 'b1;  // Test Case 2: Select input 1
    #10;
    onehot = 'b10;  // Test Case 3: Select input 2
    #10;
    onehot = 'b100;  // Test Case 4: Select input 3
    #10;
    onehot = 'b1000;  // Test Case 5: Invalid select, expect 0

    #10;
    $finish;  // End simulation
  end

  //Monitor
  always @(bin) begin
    $display("[%0t] data_out = %h", $time, bin);
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
