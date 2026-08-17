import ahb_pkg::*;
module ahb_top #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter MEM_DEPTH  = 256
)(
    input logic hclk,
    input logic hreset_n,

    // Master user inputs
    input  logic                     i_enb,
    input  logic [DATA_WIDTH-1:0]    i_data,
    input  logic                     i_write,
    input  logic [ADDR_WIDTH-1:0]    i_addr,
    input  logic                     i_wrap_en,
    input  burst_t                   i_burst_type,
    input  hsize_t                   i_data_size,
    input  logic                     i_busy,


    // Wait signals input to the slave
    input logic i_wait_1,
    input logic i_wait_2,
    input logic i_wait_3,
    input logic i_wait_4
);

    //------------------------------------------------------
    // Shared AHB Interfaces
    //------------------------------------------------------
    ahb_if #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH)) master_if();
    ahb_if #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH)) decoder_if();
    ahb_if #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH)) slave1_if();
    ahb_if #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH)) slave2_if();
    ahb_if #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH)) slave3_if();
    ahb_if #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH)) slave4_if();

    assign master_if.hclk     = hclk;
    assign master_if.hreset_n = hreset_n;

    // Decoder signals
    logic hsel_1;
    logic hsel_2;
    logic hsel_3;
    logic hsel_4;
    logic [1:0] mux_select;

    // Per-slave read-data / handshake outputs
    logic [DATA_WIDTH-1:0] hrdata_1;
    logic [DATA_WIDTH-1:0] hrdata_2;
    logic [DATA_WIDTH-1:0] hrdata_3;
    logic [DATA_WIDTH-1:0] hrdata_4;

    logic hready_1, hready_2, hready_3, hready_4;
    logic hresp_1,  hresp_2,  hresp_3,  hresp_4;

    // Select
    assign slave1_if.hsel = hsel_1;
    assign slave2_if.hsel = hsel_2;
    assign slave3_if.hsel = hsel_3;
    assign slave4_if.hsel = hsel_4;

    // Broadcast the shared address/control/write-data phase to all slaves
    assign slave1_if.hclk      = master_if.hclk;
    assign slave1_if.hreset_n  = master_if.hreset_n;
    assign slave1_if.haddr     = master_if.haddr;
    assign slave1_if.hwrite    = master_if.hwrite;
    assign slave1_if.htrans    = master_if.htrans;
    assign slave1_if.hsize     = master_if.hsize;
    assign slave1_if.hburst    = master_if.hburst;
    assign slave1_if.hwdata    = master_if.hwdata;
    assign slave1_if.hprot     = master_if.hprot;
    assign slave1_if.hmastlock = master_if.hmastlock;

    assign slave2_if.hclk      = master_if.hclk;
    assign slave2_if.hreset_n  = master_if.hreset_n;
    assign slave2_if.haddr     = master_if.haddr;
    assign slave2_if.hwrite    = master_if.hwrite;
    assign slave2_if.htrans    = master_if.htrans;
    assign slave2_if.hsize     = master_if.hsize;
    assign slave2_if.hburst    = master_if.hburst;
    assign slave2_if.hwdata    = master_if.hwdata;
    assign slave2_if.hprot     = master_if.hprot;
    assign slave2_if.hmastlock = master_if.hmastlock;

    assign slave3_if.hclk      = master_if.hclk;
    assign slave3_if.hreset_n  = master_if.hreset_n;
    assign slave3_if.haddr     = master_if.haddr;
    assign slave3_if.hwrite    = master_if.hwrite;
    assign slave3_if.htrans    = master_if.htrans;
    assign slave3_if.hsize     = master_if.hsize;
    assign slave3_if.hburst    = master_if.hburst;
    assign slave3_if.hwdata    = master_if.hwdata;
    assign slave3_if.hprot     = master_if.hprot;
    assign slave3_if.hmastlock = master_if.hmastlock;

    assign slave4_if.hclk      = master_if.hclk;
    assign slave4_if.hreset_n  = master_if.hreset_n;
    assign slave4_if.haddr     = master_if.haddr;
    assign slave4_if.hwrite    = master_if.hwrite;
    assign slave4_if.htrans    = master_if.htrans;
    assign slave4_if.hsize     = master_if.hsize;
    assign slave4_if.hburst    = master_if.hburst;
    assign slave4_if.hwdata    = master_if.hwdata;
    assign slave4_if.hprot     = master_if.hprot;
    assign slave4_if.hmastlock = master_if.hmastlock;

    assign decoder_if.hclk      = master_if.hclk;
    assign decoder_if.hreset_n  = master_if.hreset_n;
    assign decoder_if.haddr     = master_if.haddr;
    assign decoder_if.hwrite    = master_if.hwrite;
    assign decoder_if.htrans    = master_if.htrans;
    assign decoder_if.hsize     = master_if.hsize;
    assign decoder_if.hburst    = master_if.hburst;
    assign decoder_if.hwdata    = master_if.hwdata;
    assign decoder_if.hprot     = master_if.hprot;
    assign decoder_if.hmastlock = master_if.hmastlock;


    // Pull each slave's response phase out into the flat signals used by the mux
    assign hrdata_1 = slave1_if.hrdata;
    assign hready_1 = slave1_if.hready;
    assign hresp_1  = slave1_if.hresp;

    assign hrdata_2 = slave2_if.hrdata;
    assign hready_2 = slave2_if.hready;
    assign hresp_2  = slave2_if.hresp;

    assign hrdata_3 = slave3_if.hrdata;
    assign hready_3 = slave3_if.hready;
    assign hresp_3  = slave3_if.hresp;

    assign hrdata_4 = slave4_if.hrdata;
    assign hready_4 = slave4_if.hready;
    assign hresp_4  = slave4_if.hresp;

    //------------------------------------------------------
    // Master
    //------------------------------------------------------
    // Master
    ahb_master #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_master (
        .ahb(master_if),
        .i_enb(i_enb),
        .i_data(i_data),
        .i_write(i_write),
        .i_addr(i_addr),
        .i_wrap_en(i_wrap_en),
        .i_burst_type(i_burst_type),
        .i_data_size(i_data_size),
        .i_busy(i_busy)
    );

    //------------------------------------------------------
    // Decoder
    //------------------------------------------------------
    ahb_address_decoder u_decoder(

        .ahb(decoder_if),
        .hsel_1(hsel_1),
        .hsel_2(hsel_2),
        .hsel_3(hsel_3),
        .hsel_4(hsel_4),

        .mux_select(mux_select)
    );

    //------------------------------------------------------
    // Slave 1
    //------------------------------------------------------
    ahb_slave_1 #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .MEM_DEPTH(MEM_DEPTH)
    ) u_slave1 (
        .ahb(slave1_if),
        .i_wait(i_wait_1)
    );

    //------------------------------------------------------
    // Slave 2
    //------------------------------------------------------
    ahb_slave_2 #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .MEM_DEPTH(MEM_DEPTH)
    ) u_slave2 (
        .ahb(slave2_if),
        .i_wait(i_wait_2)
    );

    //------------------------------------------------------
    // Slave 3
    //------------------------------------------------------
    ahb_slave_3 #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .MEM_DEPTH(MEM_DEPTH)
    ) u_slave3 (
        .ahb(slave3_if),
        .i_wait(i_wait_3)
    );

    //------------------------------------------------------
    // Slave 4
    //------------------------------------------------------
    ahb_slave_4 #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .MEM_DEPTH(MEM_DEPTH)
    ) u_slave4 (
        .ahb(slave4_if),
        .i_wait(i_wait_4)
    );

    //------------------------------------------------------
    // HRDATA Mux
    //------------------------------------------------------
    ahb_hrdata_mux u_hrdata_mux(

        .mux_select(mux_select),
        .hrdata_1(hrdata_1),
        .hrdata_2(hrdata_2),
        .hrdata_3(hrdata_3),
        .hrdata_4(hrdata_4),
        .hrdata(master_if.hrdata)

    );

    //------------------------------------------------------
    // HREADY/HRESP Mux
    //------------------------------------------------------
    always_comb begin
        case (mux_select)

            2'b00: begin
                master_if.hready = hready_1;
                master_if.hresp  = hresp_1;
            end

            2'b01: begin
                master_if.hready = hready_2;
                master_if.hresp  = hresp_2;
            end

            2'b10: begin
                master_if.hready = hready_3;
                master_if.hresp  = hresp_3;
            end

            2'b11: begin
                master_if.hready = hready_4;
                master_if.hresp  = hresp_4;
            end

            default: begin
                master_if.hready = 1'b1;
                master_if.hresp  = 1'b0;
            end

        endcase
    end

endmodule