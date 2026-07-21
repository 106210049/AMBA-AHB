`timescale 1ns/1ns
`default_nettype none
`include "taxi_ahbl_if.sv"
`include "taxi_ahbl_ram.sv"
`include "ahb_pkg.sv"
`include "transaction.sv"
`include "testcase_pkg.sv"
`include "generator.sv"
`include "driver.sv"
`include "monitor.sv"
`include "scoreboard.sv"
`include "agent.sv"
`include "env.sv"
`include "sva_checker.sv"
`include "test.sv"
module ahb_tb_top;

  // --------------------------------------------------
  // Parameters
  // --------------------------------------------------
  localparam int ADDR_WIDTH = 32;
  localparam int DATA_WIDTH = 32;

  localparam int MEMORY_DEPTH          = 512;
  localparam int WAIT_WRITE            = 0;
  localparam int WAIT_READ             = 0;
  localparam int REGISTER_SELECT_BITS  = 12;
  localparam int SLAVE_SELECT_BITS     = 20;

  // --------------------------------------------------
  // Clock & Reset
  // --------------------------------------------------
  bit i_hclk;
  bit i_hreset; // active-low (as your design)

  // Clock: 100 MHz
  initial i_hclk = 0;
  always #5 i_hclk = ~i_hclk;

  // Reset sequence
  initial begin
    i_hreset = 1'b0;                 // assert reset
    repeat (20) @(posedge i_hclk);
    i_hreset = 1'b1;                 // deassert reset
  end

  // --------------------------------------------------
  // Wave dump
  // --------------------------------------------------
  initial begin
    $dumpfile("ahb_wave.vcd");
    $dumpvars(0, ahb_tb_top);
  end

  // --------------------------------------------------
  // Interface
  // --------------------------------------------------
  taxi_ahbl_if #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
  ) ahb_if0 (
    .i_hclk   (i_hclk),
    .i_hreset (i_hreset)
  );

  // --------------------------------------------------
  // DUT
  // --------------------------------------------------
  taxi_ahbl_ram #(
    .ADDR_WIDTH           (ADDR_WIDTH),
    .DATA_WIDTH           (DATA_WIDTH),
    .MEMORY_DEPTH         (MEMORY_DEPTH),
    .WAIT_WRITE           (WAIT_WRITE),
    .WAIT_READ            (WAIT_READ),
    .REGISTER_SELECT_BITS (REGISTER_SELECT_BITS),
    .SLAVE_SELECT_BITS    (SLAVE_SELECT_BITS)
  ) u_dut (
    .i_hclk   (i_hclk),
    .i_hreset (i_hreset),
    .s_ahb    (ahb_if0.slv)
  );

  // --------------------------------------------------
  // Test program (connect full interface)
  // --------------------------------------------------
  test t1(ahb_if0);
  sva_checker chk (ahb_if0);
endmodule

`default_nettype wire