module tb_ahb_top;
// import the UVM library
import uvm_pkg::*;
import ahb_define_pkg::*;
import ahb_master_pkg::*;
import ahb_slave_pkg::*;
import ahb_pkg::*;
// include the UVM macros
`include "uvm_macros.svh"
`include "../sv/ahb_checker.sv"
`include "ahb_tb.sv"
`include "ahb_test_lib.sv"

parameter int DATA_WIDTH = 32;
parameter int ADDR_WIDTH = 32;
logic hclk, hreset_n;

initial hclk = 1'b0;
initial hreset_n = 1'b1;
always #5 hclk = ~hclk;

initial begin
    @(posedge hclk);
    hreset_n = 1'b0;
    repeat(2)@(posedge hclk);
    hreset_n = 1'b1;
end

    ahb_if ahb_if0 (hclk, hreset_n);

    // DUT
    ahb_top #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) uut (
        .hclk(hclk),
        .hreset_n(hreset_n),
        .i_enb(ahb_if0.i_enb),
        .i_data(ahb_if0.i_data),
        .i_write(ahb_if0.i_write),
        .i_addr(ahb_if0.i_addr),
        .i_wrap_en(ahb_if0.i_wrap_en),
        .i_burst_type(ahb_if0.i_burst_type),
        .i_data_size(ahb_if0.i_data_size),
        .i_busy(ahb_if0.i_busy),
        .i_wait_1(ahb_if0.i_wait_1),
        .i_wait_2(ahb_if0.i_wait_2),
        .i_wait_3(ahb_if0.i_wait_3),
        .i_wait_4(ahb_if0.i_wait_4),
        .o_hready(ahb_if0.hready),
        .o_hresp(ahb_if0.hresp),
        .o_hrdata(ahb_if0.hrdata)
    );

    // UVM run
    initial begin
        // cấu hình virtual interface cho agent
        ahb_master_vif_config::set(null, "*.tb.env.master_agent.*", "vif", ahb_if0);
        ahb_slave_vif_config::set(null, "*.tb.env.slave_agent.*", "vif", ahb_if0);
        run_test();
    end
    ahb_checker ahb_chk(ahb_if0);
endmodule