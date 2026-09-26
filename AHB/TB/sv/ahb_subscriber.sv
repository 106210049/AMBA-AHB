import ahb_define_pkg::*;

class func_cov extends uvm_subscriber #(ahb_slave_sequence_item);
  `uvm_component_utils(func_cov)

  localparam int ADDR_WIDTH = 32;
  localparam int DATA_WIDTH = 32;

  bit [ADDR_WIDTH-1:0] haddr;
  bit                  hwrite;
  hsize_t              hsize;
  burst_t              hburst;
  htrans_t             htrans;
  bit                  hmastlock;
  bit [3:0]            hprot;
  bit                  hsel;
  bit [DATA_WIDTH-1:0] hwdata;
  bit [DATA_WIDTH-1:0] hrdata;
  bit                  hready;
  bit                  hresp;

  covergroup slave_cg;
    option.per_instance = 1;

    cp_haddr: coverpoint haddr {
        bins slave_1 = {[32'h0000_0000:32'h0000_03FF]};
        bins slave_2 = {[32'h0000_0400:32'h0000_07FF]};
        bins slave_3 = {[32'h0000_0800:32'h0000_0BFF]};
        bins slave_4 = {[32'h0000_0C00:32'h0000_0FFF]};
    }

    cp_hwrite: coverpoint hwrite {
        bins read  = {1'b0};
        bins write = {1'b1};
    }

    cp_hsize: coverpoint hsize {
        bins byte_transfer  = {HSIZE_BYTE};
        bins hword_transfer = {HSIZE_HWORD};
        bins word_transfer  = {HSIZE_WORD};
        // bins dword_transfer = {HSIZE_DWORD};
        // bins transfer_128bit = {HSIZE_128BIT};
    }

    cp_hburst: coverpoint hburst {
        bins single = {SINGLE};
        bins incr   = {INCR};
        bins incr4  = {INCR4};
        bins incr8  = {INCR8};
        bins incr16 = {INCR16};
        bins wrap4  = {WRAP4};
        bins wrap8  = {WRAP8};
        bins wrap16 = {WRAP16};
    }

    cp_htrans: coverpoint htrans {
        bins idle   = {ahb_define_pkg::IDLE};
        bins busy   = {ahb_define_pkg::BUSY};
        bins nonseq = {ahb_define_pkg::NONSEQ};
        bins seq    = {ahb_define_pkg::SEQ};
    }

    cp_hwdata: coverpoint hwdata {
      bins zero     = {32'h0000_0000};
      bins all_ones = {32'hFFFF_FFFF};
      bins other    = default;
    }

    cp_hrdata: coverpoint hrdata {
      bins zero     = {32'h0000_0000};
      bins all_ones = {32'hFFFF_FFFF};
      bins other    = default;
    }

    cp_hresp: coverpoint hresp {
      bins okay  = {1'b0};
      bins error = {1'b1};
    }

    size_x_burst: cross cp_hsize, cp_hburst;
    write_x_size: cross cp_hwrite, cp_hsize;
    burst_x_trans: cross cp_hburst, cp_htrans {
        ignore_bins busy_idle = binsof(cp_htrans) intersect {ahb_define_pkg::BUSY, ahb_define_pkg::IDLE};
        ignore_bins single = binsof(cp_htrans.seq) && binsof(cp_hburst.single);
    }

    write_x_resp: cross cp_hwrite, cp_hresp;
  endgroup

  function new(string name = "func_cov", uvm_component parent = null);
    super.new(name, parent);
    slave_cg = new();
  endfunction

  virtual function void write(ahb_slave_sequence_item t);
    if (t == null) begin
      `uvm_warning(get_type_name(), "Ignoring null slave sequence item")
      return;
    end

    haddr     = t.haddr;
    hwrite    = t.hwrite;
    hsize     = t.hsize;
    hburst    = t.hburst;
    htrans    = t.htrans;
    // hmastlock = t.hmastlock;
    // hprot     = t.hprot;
    // hsel      = t.hsel;
    hwdata    = t.hwdata;
    hrdata    = t.hrdata;
    hready    = t.hready;
    hresp     = t.hresp;
    slave_cg.sample();
  endfunction
endclass: func_cov