`timescale 1ns/1ps

import ahb_pkg::*;
import ahb_master_pkg::*;

module tb_ahb_master;

    localparam DATA_WIDTH = 32;
    localparam ADDR_WIDTH = 32;

    // Instantiate interface
    ahb_if #(DATA_WIDTH, ADDR_WIDTH) ahb();

    // Stimulus signals
    logic                     i_enb;
    logic [DATA_WIDTH-1:0]    i_data;
    logic                     i_write;
    logic [ADDR_WIDTH-1:0]    i_addr;
    logic                     i_wrap_en;
    burst_t                   i_burst_type;
    hsize_t                   i_data_size;
    logic                     i_busy;

    // DUT
    ahb_master #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
        .ahb(ahb.master),
        .i_enb(i_enb),
        .i_data(i_data),
        .i_write(i_write),
        .i_addr(i_addr),
        .i_wrap_en(i_wrap_en),
        .i_burst_type(i_burst_type),
        .i_data_size(i_data_size),
        .i_busy(i_busy)
    );

    // Clock generation
    initial begin
        ahb.hclk = 0;
        forever #5 ahb.hclk = ~ahb.hclk; // 100MHz clock
    end

    // Reset
    initial begin
        ahb.hreset_n = 0;
        #20;
        ahb.hreset_n = 1;
    end

    // Slave model (simple ready/response)
    initial begin
        ahb.hready = 1;
        ahb.hresp  = 0;
        ahb.hrdata = 32'h12345678;
    end

    // Stimulus
    initial begin
        // Default values
        i_enb       = 0;
        i_data      = 0;
        i_write     = 0;
        i_addr      = 32'h0000_0000;
        i_wrap_en   = 0;
        i_burst_type= SINGLE;
        i_data_size = HSIZE_WORD;
        i_busy      = 0;

        // Wait reset
        @(posedge ahb.hreset_n);

        // SINGLE WRITE transaction
        @(posedge ahb.hclk);
        i_enb   = 1;
        i_write = 1;
        i_addr  = 32'h1000_0000;
        i_burst_type = SINGLE;
        @(posedge ahb.hclk);
        i_enb   = 0;
        @(posedge ahb.hclk);
        i_data  = 32'hDEADBEEF;

        repeat(5) @(posedge ahb.hclk);
        
        // SINGLE READ transaction
        @(posedge ahb.hclk);
        i_enb   = 1;
        i_write = 0;
        i_addr  = 32'h2000_0000;
        i_burst_type = SINGLE;
        @(posedge ahb.hclk);
        i_enb   = 0;

        repeat(5) @(posedge ahb.hclk);

        // INCR burst 6 beat
        // @(posedge ahb.hclk);
        // i_enb       = 1;
        // i_write     = 1;
        // i_addr      = 32'h6000_0000;
        // i_burst_type= INCR;
        // i_data      = 32'hDDDD0001;
        // @(posedge ahb.hclk);
        // i_enb       = 0;

        // repeat(5) @(posedge ahb.hclk) i_data = i_data + 1;

        // // Kết thúc burst bằng IDLE
        // @(posedge ahb.hclk);
        // i_enb       = 0; // giữ nguyên, DUT sẽ phát HTRANS=IDLE

        // INCR4 WRITE burst
        @(posedge ahb.hclk);
        i_enb   = 1;
        i_write = 1;
        i_addr  = 32'h3000_0000;
        i_burst_type = INCR4;
        @(posedge ahb.hclk);
        i_enb   = 0;
        @(posedge ahb.hclk);
        i_data  = 32'hAAAA0001;
        repeat(5) @(posedge ahb.hclk) i_data = i_data + 1;

        // INCR8 WRITE burst
        @(posedge ahb.hclk);
        i_enb   = 1;
        i_write = 1;
        i_addr  = 32'h4000_0000;
        i_burst_type = INCR8;
        @(posedge ahb.hclk);
        i_enb   = 0;
        @(posedge ahb.hclk);
        i_data  = 32'hBBBB0001;
        repeat(8) @(posedge ahb.hclk) i_data = i_data + 1;

        // INCR16 WRITE burst
        @(posedge ahb.hclk);
        i_enb   = 1;
        i_write = 1;
        i_addr  = 32'h5000_0000;
        i_burst_type = INCR16;
        @(posedge ahb.hclk);
        i_enb   = 0;
        @(posedge ahb.hclk);
        i_data  = 32'hCCCC0001;
        repeat(15) @(posedge ahb.hclk) i_data = i_data + 1;

        repeat(20) @(posedge ahb.hclk);

        // End simulation
        $finish;
    end

    // Monitor
    initial begin
        $monitor("T=%0t | State=%0d | HADDR=%h | HWDATA=%h | HWRITE=%b | HBURST=%b | HTRANS=%b | HRDATA=%h",
                 $time, dut.current_state, ahb.haddr, ahb.hwdata, ahb.hwrite, ahb.hburst, ahb.htrans, ahb.hrdata);
    end

endmodule
