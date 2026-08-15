`timescale 1ns/1ps
import ahb_pkg::*;

module ahb_top_tb;

    parameter DATA_WIDTH = 32;
    parameter ADDR_WIDTH = 32;

    // Clock & reset
    logic hclk;
    logic hreset_n;

    // Stimulus cho Master
    logic                     i_enb;
    logic [DATA_WIDTH-1:0]    i_data;
    logic                     i_write;
    logic [ADDR_WIDTH-1:0]    i_addr;
    logic                     i_wrap_en;
    burst_t                   i_burst_type;
    hsize_t                   i_data_size;
    logic                     i_busy;

    // Stimulus cho Slave wait
    logic i_wait_1, i_wait_2, i_wait_3, i_wait_4;

    // DUT
    ahb_top #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
        .hclk(hclk),
        .hreset_n(hreset_n),
        .i_enb(i_enb),
        .i_data(i_data),
        .i_write(i_write),
        .i_addr(i_addr),
        .i_wrap_en(i_wrap_en),
        .i_burst_type(i_burst_type),
        .i_data_size(i_data_size),
        .i_busy(i_busy),
        .i_wait_1(i_wait_1),
        .i_wait_2(i_wait_2),
        .i_wait_3(i_wait_3),
        .i_wait_4(i_wait_4)
    );

    // Clock generation
    initial begin
        hclk = 0;
        forever #5 hclk = ~hclk; // 100MHz
    end

    // Reset
    initial begin
        hreset_n = 0;
        #20 hreset_n = 1;
    end

    // Stimulus
    initial begin
        i_enb       = 0;
        i_data      = 0;
        i_write     = 0;
        i_addr      = 32'h0000_0000;
        i_wrap_en   = 0;
        i_burst_type= SINGLE;
        i_data_size = HSIZE_WORD;
        i_busy      = 0;
        i_wait_1    = 0;
        i_wait_2    = 0;
        i_wait_3    = 0;
        i_wait_4    = 0;

        @(posedge hreset_n);

        // ------------------------------
        // Test Slave1: haddr[11:10] = 00
        // ------------------------------
        $display("=== Test Slave1 ===");
        @(posedge hclk);
        i_enb   = 1; i_write = 1; 
        i_addr  = 32'h0000_0000; // bit[11:10]=00
        @(posedge hclk);
        i_enb   = 0; 
         @(posedge hclk);
        i_data  = 32'h1111_1111;
        repeat(2) @(posedge hclk);
        // đọc lại
        @(posedge hclk);
        i_enb   = 1; i_write = 0;
        i_addr  = 32'h0000_0000;
        @(posedge hclk);
        i_enb   = 0;
        repeat(2) @(posedge hclk);

        // ------------------------------
        // Test Slave2: haddr[11:10] = 01
        // ------------------------------
        $display("=== Test Slave2 ===");
        @(posedge hclk);
        i_enb   = 1; i_write = 1; 
        i_addr  = 32'h0000_0400; // bit[11:10]=01
        @(posedge hclk);
        i_enb   = 0; 
        @(posedge hclk);
        i_data  = 32'h2222_2222;

        repeat(2) @(posedge hclk);
        // đọc lại
        @(posedge hclk);
        i_enb   = 1; i_write = 0;
        i_addr  = 32'h0000_0400;
        @(posedge hclk);
        i_enb   = 0;
        repeat(2) @(posedge hclk);

        // ------------------------------
        // Test Slave3: haddr[11:10] = 10
        // ------------------------------
        $display("=== Test Slave3 ===");
        @(posedge hclk);
        i_enb   = 1; i_write = 1; 
        i_addr  = 32'h0000_0800; // bit[11:10]=10
        @(posedge hclk);
        i_enb   = 0;
        @(posedge hclk);
        i_data  = 32'h3333_3333;

        repeat(2) @(posedge hclk);
        // đọc lại
        @(posedge hclk);
        i_enb   = 1; i_write = 0;
        i_addr  = 32'h0000_0800;
        @(posedge hclk);
        i_enb   = 0;
        repeat(2) @(posedge hclk);

        // ------------------------------
        // Test Slave4: haddr[11:10] = 11
        // ------------------------------
        $display("=== Test Slave4 ===");
        @(posedge hclk);
        i_enb   = 1; i_write = 1; 
        i_addr  = 32'h0000_0C00; // bit[11:10]=11
        @(posedge hclk);
        i_enb   = 0;
        @(posedge hclk);
        i_data  = 32'h4444_4444;
        repeat(2) @(posedge hclk);
        // đọc lại
        @(posedge hclk);
        i_enb   = 1; i_write = 0;
        i_addr  = 32'h0000_0C00;
        @(posedge hclk);
        i_enb   = 0;
        repeat(2) @(posedge hclk);

        #200 $finish;
    end

    // Monitor để debug
    always @(posedge hclk) begin
        if (dut.master_if.hsel && dut.master_if.hready) begin
            $display("[%0t] ADDR=%h WRITE=%b WDATA=%h RDATA=%h READY=%b BURST=%0d SIZE=%0d",
                     $time, dut.master_if.haddr, dut.master_if.hwrite,
                     dut.master_if.hwdata, dut.master_if.hrdata, dut.master_if.hready,
                     dut.master_if.hburst, dut.master_if.hsize);
        end
    end

endmodule
