`include "include.svh"

// Self-checking testbench for tcam.sv
// Timing: INSERT/DELETE = 2*WORD_DEPTH*NUM_KEYRAM = 128 cycles
//         LOOKUP        = 2 cycles after command acceptance
module tb_tcam;

  localparam int DATA_WIDTH    = 4;
  localparam int WORD_DEPTH    = 2 ** DATA_WIDTH;  // 16
  localparam int NUM_KEYRAM    = 4;
  localparam int MAX_ENTRY     = 8;
  localparam int GEN_PRIO_RESP = 1;
  localparam int KEY_WIDTH     = NUM_KEYRAM * DATA_WIDTH;  // 16

  localparam logic [1:0] CMD_INSERT = 2'b00;
  localparam logic [1:0] CMD_DELETE = 2'b01;
  localparam logic [1:0] CMD_LOOKUP = 2'b10;

  // ----------------------------------------------------------------
  // DUT ports
  // ----------------------------------------------------------------
  logic                 clk;
  logic                 resetn;
  logic                 cmd_valid;
  logic                 cmd_ready;
  logic [1:0]           cmd;
  logic [KEY_WIDTH-1:0] key;
  logic [KEY_WIDTH-1:0] mask;
  logic [MAX_ENTRY-1:0] entry_in;
  logic [KEY_WIDTH-1:0] lkp_data;
  logic [MAX_ENTRY-1:0] entry_out;
  logic                 entry_out_valid;

  int pass_cnt, fail_cnt;

  // ----------------------------------------------------------------
  // Reference model – mirrors each key RAM bitmask
  // ----------------------------------------------------------------
  logic [MAX_ENTRY-1:0] ref_ram [NUM_KEYRAM][WORD_DEPTH];

  // ----------------------------------------------------------------
  // DUT instance
  // ----------------------------------------------------------------
  tcam #(
    .DATA_WIDTH   (DATA_WIDTH),
    .WORD_DEPTH   (WORD_DEPTH),
    .NUM_KEYRAM   (NUM_KEYRAM),
    .MAX_ENTRY    (MAX_ENTRY),
    .GEN_PRIO_RESP(GEN_PRIO_RESP)
  ) u_dut (
    .clk            (clk),
    .resetn         (resetn),
    .cmd_valid      (cmd_valid),
    .cmd_ready      (cmd_ready),
    .cmd            (cmd),
    .key            (key),
    .mask           (mask),
    .entry_in       (entry_in),
    .data           (lkp_data),
    .entry_out      (entry_out),
    .entry_out_valid(entry_out_valid)
  );

  // ----------------------------------------------------------------
  // Clock  (period = 2)
  // ----------------------------------------------------------------
  initial clk = 1;
  always #1 clk = ~clk;

  // ----------------------------------------------------------------
  // Tasks
  // ----------------------------------------------------------------

  // Spin until cmd_ready is observed at a posedge
  task automatic wait_ready();
    while (!cmd_ready) @(posedge clk);
  endtask

  // INSERT: drive command, update reference model, wait for DUT to finish
  task automatic do_insert(
    input logic [KEY_WIDTH-1:0] k,
    input logic [KEY_WIDTH-1:0] m,
    input logic [MAX_ENTRY-1:0] e
  );
    logic [DATA_WIDTH-1:0] k_sl, m_sl;

    wait_ready();
    cmd_valid <= 1'b1;
    cmd       <= CMD_INSERT;
    key       <= k;
    mask      <= m;
    entry_in  <= e;
    @(posedge clk);   // command accepted
    cmd_valid <= 1'b0;

    // Mirror INSERT into reference model:
    // for each RAM slice i, set entry bit in every address that satisfies key/mask
    for (int ri = 0; ri < NUM_KEYRAM; ri++) begin
      k_sl = k[ri*DATA_WIDTH +: DATA_WIDTH];
      m_sl = m[ri*DATA_WIDTH +: DATA_WIDTH];
      for (int a = 0; a < WORD_DEPTH; a++) begin
        if ((DATA_WIDTH'(a) & m_sl) == (k_sl & m_sl))
          ref_ram[ri][a] |= e;
      end
    end

    wait_ready();
  endtask

  // DELETE: clear entry from every address in every RAM slice
  task automatic do_delete(input logic [MAX_ENTRY-1:0] e);
    wait_ready();
    cmd_valid <= 1'b1;
    cmd       <= CMD_DELETE;
    entry_in  <= e;
    @(posedge clk);   // command accepted
    cmd_valid <= 1'b0;

    for (int ri = 0; ri < NUM_KEYRAM; ri++)
      for (int a = 0; a < WORD_DEPTH; a++)
        ref_ram[ri][a] &= ~e;

    wait_ready();
  endtask

  // LOOKUP: issue lookup, compute expected output from ref model, compare
  task automatic do_lookup(
    input logic [KEY_WIDTH-1:0] d,
    input string                label
  );
    logic [MAX_ENTRY-1:0] hit_vec, exp_out;

    // Expected: AND of ref_ram[i][data_slice_i] across all slices
    hit_vec = {MAX_ENTRY{1'b1}};
    for (int ri = 0; ri < NUM_KEYRAM; ri++)
      hit_vec &= ref_ram[ri][d[ri*DATA_WIDTH +: DATA_WIDTH]];

    // Priority encoder: lowest matching index wins (GEN_PRIO_RESP=1)
    exp_out = '0;
    if (GEN_PRIO_RESP) begin
      for (int i = MAX_ENTRY-1; i >= 0; i--)
        if (hit_vec[i]) exp_out = MAX_ENTRY'(1 << i);
    end else begin
      exp_out = hit_vec;
    end

    wait_ready();
    cmd_valid <= 1'b1;
    cmd       <= CMD_LOOKUP;
    lkp_data  <= d;
    @(posedge clk);   // S_IDLE  → S_LOOKUP_WAIT  (RAM read issued)
    cmd_valid <= 1'b0;
    @(posedge clk);   // S_LOOKUP_WAIT → S_IDLE   (output registered)

    if (entry_out === exp_out && entry_out_valid === 1'b1) begin
      $display("[PASS] %-42s  data=%04h  got=%08b  exp=%08b",
               label, d, entry_out, exp_out);
      pass_cnt++;
    end else begin
      $display("[FAIL] %-42s  data=%04h  got=%08b  exp=%08b  valid=%b",
               label, d, entry_out, exp_out, entry_out_valid);
      fail_cnt++;
    end
  endtask

  // ----------------------------------------------------------------
  // Main test sequence
  // ----------------------------------------------------------------
  initial begin
    cmd_valid = 1'b0;
    cmd       = '0;
    key       = '0;
    mask      = '0;
    entry_in  = '0;
    lkp_data  = '0;
    pass_cnt  = 0;
    fail_cnt  = 0;

    for (int i = 0; i < NUM_KEYRAM; i++)
      for (int a = 0; a < WORD_DEPTH; a++)
        ref_ram[i][a] = '0;

    // Reset
    resetn = 1'b0;
    repeat (4) @(posedge clk);
    resetn = 1'b1;

    // S_INIT clears all key RAMs (WORD_DEPTH cycles); wait for S_IDLE
    wait_ready();

    // ----------------------------------------------------------------
    // T1 – Exact match  (mask = 16'hFFFF → all bits are care bits)
    //   entry 0: key = 16'h1234
    //   Slices: [3:0]=4, [7:4]=3, [11:8]=2, [15:12]=1
    // ----------------------------------------------------------------
    $display("\n-- T1: exact match --");
    do_insert(16'h1234, 16'hFFFF, 8'b0000_0001);
    do_lookup(16'h1234, "T1a  exact hit");
    do_lookup(16'h1235, "T1b  miss (addr+1)");
    do_lookup(16'h0000, "T1c  miss (all-zero)");

    // ----------------------------------------------------------------
    // T2 – Wildcard  (mask bit = 0 → don't-care)
    //   entry 1: key = 16'hAB00, mask = 16'hFF00
    //   Slice 0 (bits[ 3: 0]): mask=4'h0 → don't-care (all addrs match)
    //   Slice 1 (bits[ 7: 4]): mask=4'h0 → don't-care (all addrs match)
    //   Slice 2 (bits[11: 8]): mask=4'hF → care, must be 4'hB
    //   Slice 3 (bits[15:12]): mask=4'hF → care, must be 4'hA
    //   Pattern: data[15:8] == 8'hAB, data[7:0] arbitrary
    // ----------------------------------------------------------------
    $display("\n-- T2: wildcard --");
    do_insert(16'hAB00, 16'hFF00, 8'b0000_0010);
    do_lookup(16'hABFF, "T2a  wildcard hit (low byte=FF)");
    do_lookup(16'hAB00, "T2b  wildcard hit (low byte=00)");
    do_lookup(16'hAB12, "T2c  wildcard hit (low byte=12)");
    do_lookup(16'hACFF, "T2d  miss (bits[15:8]=AC, need AB)");
    do_lookup(16'h0BFF, "T2e  miss (bits[15:12]=0, need A)");

    // ----------------------------------------------------------------
    // T3 – Priority  (two entries overlap; lower index wins)
    //   entry 4: key = 16'h0000, mask = 16'h0000 → match-all wildcard
    //   data = 16'hABXX → hits both entry 1 and entry 4
    //                   → GEN_PRIO_RESP selects entry 1 (index 1 < 4)
    //   data = 16'h5555 → only entry 4 matches (bits[15:8] ≠ AB)
    // ----------------------------------------------------------------
    $display("\n-- T3: priority --");
    do_insert(16'h0000, 16'h0000, 8'b0001_0000);  // entry 4, match-all
    do_lookup(16'hABCD, "T3a  entry1 beats entry4 (priority)");
    do_lookup(16'h5555, "T3b  only entry4 (bits[15:8]=55≠AB)");
    do_lookup(16'h0000, "T3c  only entry4 (all-zero)");
    do_lookup(16'h1234, "T3d  entry0+entry4; entry0 wins");

    // ----------------------------------------------------------------
    // T4 – DELETE entry 0; verify it is gone while others remain
    //   16'h1234 no longer matches entry0's exact slices 2,3
    //   but entry4 (wildcard) still catches it → returns entry4
    // ----------------------------------------------------------------
    $display("\n-- T4: delete entry0 --");
    do_delete(8'b0000_0001);
    do_lookup(16'h1234, "T4a  entry0 gone; entry4 hits");
    do_lookup(16'hABFF, "T4b  entry1 survives delete");

    // ----------------------------------------------------------------
    // T5 – DELETE entry 4 (wildcard); verify total miss on non-entry1 patterns
    // ----------------------------------------------------------------
    $display("\n-- T5: delete entry4 (wildcard) --");
    do_delete(8'b0001_0000);
    do_lookup(16'h5555, "T5a  entry4 gone; clean miss");
    do_lookup(16'h1234, "T5b  entry0+4 gone; miss");
    do_lookup(16'hABFF, "T5c  entry1 still present");
    do_lookup(16'hAB00, "T5d  entry1 hit (low byte=00)");

    // ----------------------------------------------------------------
    // Summary
    // ----------------------------------------------------------------
    #10;
    $display("\n========================================");
    $display("  TCAM Testbench Result");
    $display("  PASS: %0d  FAIL: %0d", pass_cnt, fail_cnt);
    $display("========================================\n");
    $finish;
  end

  // VCD trace
  initial begin
    if ($test$plusargs("trace") != 0) begin
      $display("[%0t] Tracing to logs/vlt_dump.vcd...\n", $time);
      $dumpfile("logs/vlt_dump.vcd");
      $dumpvars();
    end
    $display("[%0t] Model running...\n", $time);
  end

endmodule
