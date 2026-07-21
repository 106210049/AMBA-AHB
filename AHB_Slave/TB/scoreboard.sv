`ifndef SCOREBOARD_SV
`define SCOREBOARD_SV

`default_nettype none

import ahb_pkg::*;

class scoreboard #(
  parameter int ADDR_WIDTH = 32,
  parameter int DATA_WIDTH = 32,
  parameter int MEM_BYTES  = (1<<16)
);

  mailbox mon_to_sb;

  ahb_trans #(ADDR_WIDTH,DATA_WIDTH) tr;

  //--------------------------------------------------
  // Reference Memory
  //--------------------------------------------------
  byte unsigned ref_mem[];

  //--------------------------------------------------
  // Statistics
  //--------------------------------------------------
  int n_wr;
  int n_rd;
  int n_err;

  //--------------------------------------------------
  // Constructor
  //--------------------------------------------------
  function new(mailbox mon_to_sb);

    this.mon_to_sb = mon_to_sb;

    ref_mem = new[MEM_BYTES];

    reset();

  endfunction

  //--------------------------------------------------
  // Reset
  //--------------------------------------------------
  function void reset();

    foreach(ref_mem[i])
      ref_mem[i] = 8'h00;

    n_wr  = 0;
    n_rd  = 0;
    n_err = 0;

  endfunction

  //--------------------------------------------------
  // Byte count
  //--------------------------------------------------
  function automatic int nb(hsize_e size);
    return hsize2bytes(size);
  endfunction

  //--------------------------------------------------
  // Build compare mask
  //--------------------------------------------------
  function automatic bit [DATA_WIDTH-1:0]
  build_mask(hsize_e size);

    case(size)

      HSIZE_BYTE :
        return 32'hFF000000;

      HSIZE_HWORD:
        return 32'hFFFF0000;

      HSIZE_WORD :
        return 32'hFFFFFFFF;

      default :
        return 32'hFFFFFFFF;

    endcase

  endfunction

  //--------------------------------------------------
  // Reference write
  //--------------------------------------------------
  function void write_ref(
    logic [ADDR_WIDTH-1:0] addr,
    logic [DATA_WIDTH-1:0] data,
    hsize_e                size
  );

    int n;

    n = nb(size);

    // DUT của bạn đang trả dữ liệu kiểu Big-Endian lane
    for (int i=0;i<n;i++) begin

      if ((addr+i) < MEM_BYTES)
        ref_mem[addr+i]
          = data[((DATA_WIDTH/8)-1-i)*8 +: 8];

    end

  endfunction

  //--------------------------------------------------
  // Expected read
  //--------------------------------------------------
  function automatic bit [DATA_WIDTH-1:0]
  read_ref(
    logic [ADDR_WIDTH-1:0] addr,
    hsize_e                size
  );

    bit [DATA_WIDTH-1:0] exp;

    int n;

    exp = '0;

    n = nb(size);

    for (int i=0;i<n;i++) begin

      if ((addr+i) < MEM_BYTES)
        exp[((DATA_WIDTH/8)-1-i)*8 +: 8]
          = ref_mem[addr+i];

    end

    return exp;

  endfunction

  //--------------------------------------------------
  // Process transaction
  //--------------------------------------------------
  function void process_one(
    ahb_trans #(ADDR_WIDTH,DATA_WIDTH) tr
  );

    bit [DATA_WIDTH-1:0] exp_data;
    bit [DATA_WIDTH-1:0] mask;

    //------------------------------------------------
    // Ignore IDLE/BUSY
    //------------------------------------------------
    if (tr.i_htrans inside {HTRANS_IDLE, HTRANS_BUSY})
      return;

    //------------------------------------------------
    // Burst not supported
    //------------------------------------------------
    if (tr.i_htrans == HTRANS_SEQ) begin
      if (tr.i_hwrite)
        n_wr++;
      else
        n_rd++;

      if (tr.o_hrdata != '0) begin
        n_err++;
        $error(
          "[SB] Illegal SEQ transfer ADDR=0x%08h",
          tr.i_haddr
        );
      end
      return;
    end

    //------------------------------------------------
    // Ignore ERROR response
    //------------------------------------------------
    if (tr.o_hresp)
      return;

    //------------------------------------------------
    // Unsupported size
    //------------------------------------------------
    if (nb(tr.i_hsize) > (DATA_WIDTH/8)) begin

      n_err++;

      $error(
        "[SB] Unsupported HSIZE=%s for DATA_WIDTH=%0d",
        hsize_name(tr.i_hsize),
        DATA_WIDTH
      );

      return;

    end

    //------------------------------------------------
    // WRITE
    //------------------------------------------------
    if (tr.i_hwrite) begin

      write_ref(
        tr.i_haddr,
        tr.i_hwdata,
        tr.i_hsize
      );

      n_wr++;

      $display(
        "[%0t][SB-WRITE] ADDR=0x%08h SIZE=%s DATA=0x%08h",
        $time,
        tr.i_haddr,
        hsize_name(tr.i_hsize),
        tr.i_hwdata
      );

    end

    //------------------------------------------------
    // READ
    //------------------------------------------------
    else begin

      exp_data = read_ref(
        tr.i_haddr,
        tr.i_hsize
      );

      mask = build_mask(tr.i_hsize);

      if ((exp_data & mask) ===
          (tr.o_hrdata & mask)) begin

        $display(
          "[%0t][SB-PASS ] ADDR=0x%08h SIZE=%s EXP=0x%08h ACT=0x%08h",
          $time,
          tr.i_haddr,
          hsize_name(tr.i_hsize),
          exp_data,
          tr.o_hrdata
        );

      end
      else begin

        n_err++;

        $error(
          "[%0t][SB-FAIL ] ADDR=0x%08h SIZE=%s EXP=0x%08h ACT=0x%08h",
          $time,
          tr.i_haddr,
          hsize_name(tr.i_hsize),
          exp_data,
          tr.o_hrdata
        );

      end

      n_rd++;

    end

  endfunction

  //--------------------------------------------------
  // Run
  //--------------------------------------------------
  task run();

    forever begin

      mon_to_sb.get(tr);

      process_one(tr);

    end

  endtask

  //--------------------------------------------------
  // Summary
  //--------------------------------------------------
  task print_summary();

    int total;

    total = n_wr + n_rd;

    $display("\n================ SCOREBOARD SUMMARY ================");
    $display("  Transactions : %0d", total);
    $display("    Writes     : %0d", n_wr);
    $display("    Reads      : %0d", n_rd);
    $display("  Errors       : %0d", n_err);

    if (total != 0)
      $display(
        "  Pass Rate    : %0.2f%%",
        100.0 * (total - n_err) / total
      );

    $display(
      "  RESULT       : %s",
      (n_err == 0) ? "PASS ✅" : "FAIL ❌"
    );

    $display("===================================================\n");

  endtask

endclass

`default_nettype wire
`endif