interface ahb_if #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
);
    // Global signals
    logic                    hclk;
    logic                    hreset_n;

    
    // Address & Control
    logic [ADDR_WIDTH-1:0]   haddr;
    logic                    hwrite;
    logic [2:0]              hsize;
    logic [2:0]              hburst;
    logic [1:0]              htrans;
    logic                    hmastlock;
    logic [3:0]              hprot;
    logic                    hsel;

    
    // Write Data
    logic [DATA_WIDTH-1:0]   hwdata;

   
    // Read Data & Response
    logic [DATA_WIDTH-1:0]   hrdata;
    logic                    hready;
    logic                    hresp;

    modport master (
        input  hclk,
        input  hreset_n,
        input  hrdata,
        input  hready,
        input  hresp,

        output haddr,
        output hwdata,
        output hwrite,
        output hsize,
        output hburst,
        output htrans,
        output hmastlock,
        output hprot
    );

    modport slave (
        input  hclk,
        input  hreset_n,

        input  haddr,
        input  hwdata,
        input  hwrite,
        input  hsize,
        input  hburst,
        input  htrans,
        input  hmastlock,
        input  hprot,
        input  hsel,

        output hrdata,
        output hready,
        output hresp
    );
endinterface: ahb_if