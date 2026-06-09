module tb_multi_port_mux;
  // Parameters
  localparam DATA_WIDTH = 8;
  localparam NUM_PORT = 4;
  localparam SEL_WIDTH = $clog2(NUM_PORT);

  // Test Signals
  reg  [ SEL_WIDTH-1:0] sel;
  reg  [DATA_WIDTH-1:0] data_in  [NUM_PORT];
  wire [DATA_WIDTH-1:0] data_out;

  // Instantiate the Unit Under Test (UUT)
  multi_port_mux #(
      .DATA_WIDTH(DATA_WIDTH),
      .NUM_PORT  (NUM_PORT)
  ) uut (
      .sel(sel),
      .data_in(data_in),
      .data_out(data_out)
  );

  // Test Procedure
  initial begin
    // Initialize Inputs
    sel = 0;
    data_in[0] = 8'hFF;
    data_in[1] = 8'hAA;
    data_in[2] = 8'h55;
    data_in[3] = 8'h00;

    // Apply Test Cases
    #10;
    sel = 0;  // Test Case 1: Select input 0
    #10;
    sel = 1;  // Test Case 2: Select input 1
    #10;
    sel = 2;  // Test Case 3: Select input 2
    #10;
    sel = 3;  // Test Case 4: Select input 3
    #10;
    sel = 4;  // Test Case 5: Invalid select, expect 0

    #10;
    $finish;  // End simulation
  end

  //Monitor
  always @(data_out) begin
    $display("[%0t] data_out = %h", $time, data_out);
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
