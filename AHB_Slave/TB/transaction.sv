// transaction.sv
// Purpose: AHB transaction object used by generator/driver/monitor/scoreboard.
// - Captures master->slave request fields and observed slave responses.
// - Provides size/alignment utilities and friendly display/compare helpers.

import ahb_pkg::*;

// ------------------------------------
// Bitmask for field-by-field mismatch
// Each bit indicates one specific field differs.
// ------------------------------------
typedef bit [5:0] mismatch_t;

localparam mismatch_t MM_NONE     = 6'b000000;
localparam mismatch_t MM_ADDR     = 6'b000001;
localparam mismatch_t MM_WRITE    = 6'b000010;
localparam mismatch_t MM_SIZE     = 6'b000100;
localparam mismatch_t MM_TRANS    = 6'b001000;
localparam mismatch_t MM_WDATA    = 6'b010000;
localparam mismatch_t MM_NULL_RHS = 6'b100000;

class ahb_trans #(
  parameter int ADDR_WIDTH = 32,
  parameter int DATA_WIDTH = 32
);

  // -------------------------
  // Master -> Slave (request)
  // -------------------------
  rand bit [ADDR_WIDTH-1:0] i_haddr;  // Address
  rand bit                  i_hwrite; // 1=write, 0=read
  rand hsize_e              i_hsize;  // Transfer size (BYTE/HWORD/WORD/...)
  rand htrans_e             i_htrans; // Transfer type (IDLE/BUSY/NONSEQ/SEQ)
  rand bit [DATA_WIDTH-1:0] i_hwdata; // Write data

  // -------------------------
  // Slave -> Master (observe)
  // -------------------------
  bit [DATA_WIDTH-1:0]      o_hrdata;    // Read data
  bit                       o_hreadyout; // Handshake ready/complete
  bit                       o_hresp;     // AHB response: 0=OKAY (successful), 1=ERROR (failed)

  covergroup cov_addr;
    cp_addr: coverpoint i_haddr {
      bins fixed_addr = {32'h0000_0004};
      bins rand_addr_inrange = {32'h0000_0000, 32'h0000_0004, 32'h0000_0008, 32'h0000_0020};
      bins rand_addr = {[32'h0000_0000:32'h0000_00FF]};
    }

  endgroup

  covergroup cov_hsize;
    cp_hsize: coverpoint i_hsize {
      bins BYTE = {HSIZE_BYTE};
      bins HWORD = {HSIZE_HWORD};
      bins WORD = {HSIZE_WORD};
    }
  endgroup

  covergroup cov_htrans;
    cp_htrans: coverpoint i_htrans{
      // bins IDLE = {HTRANS_IDLE};
      // bins BUSY = {HTRANS_BUSY};
      bins NONSEQ = {HTRANS_NONSEQ};
      bins SEQ = {HTRANS_SEQ};
      ignore_bins idle_busy = {HTRANS_IDLE, HTRANS_BUSY};
    }
  endgroup

  covergroup cov_hwrite;
    cp_hwrite: coverpoint i_hwrite{
      bins WRITE = {1};
      bins READ = {0};
    }
  endgroup

  // ---------- Constructor ----------
  function new();
    i_haddr     = '0;
    i_hwrite    = 1'b0;
    i_hsize     = HSIZE_WORD;
    i_htrans    = HTRANS_IDLE;
    i_hwdata    = '0;
    cov_addr = new();
    cov_htrans = new();
    cov_hwrite = new();
    cov_hsize = new();
  endfunction

  

  // ---------- Shallow copy (request fields) ----------
  function ahb_trans#(ADDR_WIDTH, DATA_WIDTH) copy();
    ahb_trans#(ADDR_WIDTH, DATA_WIDTH) t = new();
    t.i_haddr     = this.i_haddr;
    t.i_hwrite    = this.i_hwrite;
    t.i_hsize     = this.i_hsize;
    t.i_htrans    = this.i_htrans;
    t.i_hwdata    = this.i_hwdata;
    
    // If needed, also copy observed fields:
    // t.o_hrdata    = this.o_hrdata;
    // t.o_hreadyout = this.o_hreadyout;
    // t.o_hresp     = this.o_hresp;
    return t;
  endfunction

  // ---------- Diff (field-by-field) ----------
  // Returns a bitmask of mismatched request fields.
  // Multiple bits can be set when more than one field differs.
  function mismatch_t diff(input ahb_trans#(ADDR_WIDTH, DATA_WIDTH) rhs);
    mismatch_t m = MM_NONE;
    if (rhs == null) return MM_NULL_RHS;

    if (this.i_haddr  !== rhs.i_haddr ) m |= MM_ADDR;
    if (this.i_hwrite !== rhs.i_hwrite) m |= MM_WRITE;
    if (this.i_hsize  !== rhs.i_hsize ) m |= MM_SIZE;
    if (this.i_htrans !== rhs.i_htrans) m |= MM_TRANS;
    if (this.i_hwdata !== rhs.i_hwdata) m |= MM_WDATA;
    return m;
  endfunction

  // ---------- Compare (request fields) ----------
  // Backward-compatible wrapper around diff().
  // When show_mismatch=1, prints per-field mismatch lines.
  function bit compare(input ahb_trans#(ADDR_WIDTH, DATA_WIDTH) rhs,
                      bit show_mismatch = 1'b0);
    mismatch_t m = diff(rhs);
    if (show_mismatch && (m != MM_NONE)) begin
      if (m & MM_NULL_RHS) $display("[COMPARE] rhs is null");
      if (m & MM_ADDR    ) $display("[COMPARE] i_haddr mismatch:  exp=0x%0h got=0x%0h", rhs.i_haddr,  this.i_haddr );
      if (m & MM_WRITE   ) $display("[COMPARE] i_hwrite mismatch: exp=%0b   got=%0b",   rhs.i_hwrite, this.i_hwrite);
      if (m & MM_SIZE    ) $display("[COMPARE] i_hsize mismatch:  exp=%s    got=%s",    hsize_name(rhs.i_hsize),  hsize_name(this.i_hsize));
      if (m & MM_TRANS   ) $display("[COMPARE] i_htrans mismatch: exp=%s    got=%s",    htrans_name(rhs.i_htrans), htrans_name(this.i_htrans));
      if (m & MM_WDATA   ) $display("[COMPARE] i_hwdata mismatch: exp=0x%0h got=0x%0h", rhs.i_hwdata, this.i_hwdata);
    end
    return (m == MM_NONE);
  endfunction

  // ---------- Display ----------
  function void display(string prefix = "AHB_TRANS");
    $display("[%s] %s i_hsize=%s i_htrans=%s i_haddr=0x%0h i_hwdata=0x%0h",
              prefix, (i_hwrite ? "WRITE" : "READ"), hsize_name(i_hsize), htrans_name(i_htrans), i_haddr, i_hwdata);
  endfunction

  function void sample_coverage();
      if (cov_addr != null && cov_htrans != null && cov_hwrite!=null && cov_hsize!=null) begin
          cov_addr.sample();
          cov_htrans.sample();
          cov_hwrite.sample();
          cov_hsize.sample();
      end
  endfunction

  // ---------- Constraints ----------
//   constraint c_solve_order { solve i_hsize before i_haddr; }
//   // (1) Limit transfer size by DATA_WIDTH to avoid illegal sizes
//   constraint c_hsize_by_datawidth {
//     if (DATA_WIDTH <= 8)       { i_hsize inside {HSIZE_BYTE}; } 
//     else if (DATA_WIDTH <= 16) { i_hsize inside {HSIZE_BYTE, HSIZE_HWORD}; } 
//     else if (DATA_WIDTH <= 32) { i_hsize inside {HSIZE_BYTE, HSIZE_HWORD, HSIZE_WORD}; } 
//     else if (DATA_WIDTH <= 64) { i_hsize inside {HSIZE_BYTE, HSIZE_HWORD, HSIZE_WORD, HSIZE_DWORD}; } 
//     else                       { i_hsize inside {HSIZE_BYTE, HSIZE_HWORD, HSIZE_WORD, HSIZE_DWORD, HSIZE_128BIT}; }
//   }
  // (2) Address alignment to transfer size (AHB rule)
  // E.g., HWORD -> addr % 2 == 0; WORD -> addr % 4 == 0.
  constraint c_haddr_alignment {
    (longint'(i_haddr) % hsize2bytes(i_hsize)) == 0;
  }

  // (3) Limit HTRANS to the supported set for this RTL (no burst SEQ in data)
  constraint c_htrans_supported {
    i_htrans inside { HTRANS_IDLE, HTRANS_BUSY, HTRANS_NONSEQ };
  }
  

endclass

