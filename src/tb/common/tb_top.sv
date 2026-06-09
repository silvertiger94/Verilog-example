`timescale 1ns / 1ps

module tb_top;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import base_pkg::*;

  clock_reset_if u_clock_reset_if ();
  generic_dut_if u_generic_dut_if ();

  sdpram #(
      .DATA_WIDTH(32),
      .WORD_DEPTH(2)
  ) u_dut (
      .clk   (u_clock_reset_if.clk),
      .resetn(u_clock_reset_if.resetn),
      .addra (u_generic_dut_if.addr_a),
      .dina  (u_generic_dut_if.data_in),
      .wea   (u_generic_dut_if.wen),
      .ena   (u_generic_dut_if.en_a),
      .addrb (u_generic_dut_if.addr_b),
      .enb   (u_generic_dut_if.en_b),
      .doutb (u_generic_dut_if.data_out)
  );

  // Print some stuff as an example
  initial begin
    if ($test$plusargs("trace") != 0) begin
      $display("[%0t] Tracing to logs/vlt_dump.vcd...\n", $time);
      $dumpfile("logs/vlt_dump.vcd");
      $dumpvars();
    end
    $display("[%0t] Model running...\n", $time);
  end

  initial begin
    uvm_config_db#(virtual clock_reset_if)::set(null, "uvm_test_top.*", "clk_rst_vif",
                                                u_clock_reset_if);
    uvm_config_db#(virtual generic_dut_if #())::set(null, "uvm_test_top.*", "dut_vif",
                                                    u_generic_dut_if);
    run_test("base_test");
  end

endmodule
