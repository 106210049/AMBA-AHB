// generator.sv
// Purpose: Create AHB transactions for different scenarios and send to driver via mailbox.
// - Supports fixed address, random address (with or without range), and protocol-only BUSY/IDLE cases.
// - RTL has NO BURST support => we NEVER generate HTRANS_SEQ. Data transfers use HTRANS_NONSEQ.

`default_nettype none

import ahb_pkg::*;  
import testcase_pkg::*;
class generator #(
  parameter int ADDR_WIDTH = 32,
  parameter int DATA_WIDTH = 32
);

  typedef bit [ADDR_WIDTH-1:0] addr_t;  // address type
  typedef bit [DATA_WIDTH-1:0] data_t;  // data type

  // Mailbox to driver
  mailbox gen_to_drv;

  // Config knobs
  integer   num_gen;    // number of transactions to generate
  bit       FIXED_HSIZE; // when 1 => force HSIZE=WORD
  test_case test;        // selected test scenario

  // Address range configuration
  bit [ADDR_WIDTH-1:0] addr_lo;
  bit [ADDR_WIDTH-1:0] addr_hi;

  // Working transaction
  ahb_trans#(ADDR_WIDTH, DATA_WIDTH) tr;

  function new(mailbox gen_to_drv);
    this.gen_to_drv = gen_to_drv;
  endfunction

  // Helper: random write data sized to DATA_WIDTH
  function automatic data_t rand_wdata();
    return data_t'($urandom());
  endfunction

  // -------------------------------------------------------------
  // FIXED ADDR: single fixed address (currently 0x0000_0004)
  // - If FIXED_HSIZE=1: force HSIZE_WORD (alignment ensured by transaction constraint).
  // - Else: randomize HSIZE with weights (transaction will reject illegal sizes).
  // -------------------------------------------------------------
  task fixed_addr(bit FIXED_HSIZE);
    repeat (num_gen) begin
      tr = new();

      if (FIXED_HSIZE) begin
        assert(tr.randomize() with {
          i_hwrite dist {0:=50, 1:=50};
        }) else $fatal("[GEN] randomize failed (fixed_addr - FIXED)");
        tr.i_hsize = HSIZE_WORD; // force size; alignment handled by tr constraint
      end
      else begin
        assert(tr.randomize() with {
          i_hwrite dist {0:=50, 1:=50};
          i_hsize  dist {
            HSIZE_BYTE   := 25,
            HSIZE_HWORD  := 10,
            HSIZE_WORD   := 55,
            HSIZE_DWORD  := 5,
            HSIZE_128BIT := 5
          };
        }) else $fatal("[GEN] randomize failed (fixed_addr)");
      end

      // Fixed address
      tr.i_haddr  = addr_t'(32'h0000_0004);
      tr.i_htrans = HTRANS_NONSEQ;
      tr.i_hwdata = tr.i_hwrite ? rand_wdata() : '0;

      tr.display(); // optional
      gen_to_drv.put(tr);
    end
  endtask

  // -------------------------------------------------------------
  // RAND ADDR: address randomized within [addr_lo:addr_hi]
  // - Alignment and size legality are ensured by transaction constraints.
  // - FIXED_HSIZE=1 forces WORD; else size is randomized by weights.
  // -------------------------------------------------------------
  task rand_addr();
  repeat (num_gen) begin
    tr = new();

    assert(tr.randomize() with {
        i_hwrite dist {0:=50, 1:=50};
        i_haddr inside {[addr_lo : addr_hi]};
        // i_hsize == HSIZE_WORD; 
    }) else $fatal("[GEN] randomize failed (rand_addr)");
    tr.i_hsize = HSIZE_WORD;
    tr.i_htrans = HTRANS_NONSEQ;
    tr.i_hwdata = tr.i_hwrite ? rand_wdata() : '0;

    tr.display("RAND_ADDR");
    gen_to_drv.put(tr);
  end
endtask

  // -------------------------------------------------------------
  // RAND ADDR IN RANGE (fixed white-list)
  // - Example whitelist: {0x0, 0x4, 0x10, 0x20}
  // - Alignment is still guaranteed by transaction constraint.
  // -------------------------------------------------------------
  task rand_addr_inrange(bit FIXED_HSIZE);
    repeat (num_gen) begin
      tr = new();

      if (FIXED_HSIZE) begin
        assert(tr.randomize() with {
          i_hwrite dist {0:=50, 1:=50};
          i_haddr inside { addr_t'(32'h0), addr_t'(32'h4),
                           addr_t'(32'h8), addr_t'(32'h20) };
        }) else $fatal("[GEN] randomize failed (rand_addr_inrange - FIXED)");
        tr.i_hsize = HSIZE_WORD; // force size; alignment handled by tr constraint
      end
      else begin
        assert(tr.randomize() with {
          i_hwrite dist {0:=50, 1:=50};
          i_hsize  dist {
            HSIZE_BYTE   := 25,
            HSIZE_HWORD  := 10,
            HSIZE_WORD   := 55,
            HSIZE_DWORD  := 5,
            HSIZE_128BIT := 5
          };
          i_haddr inside { addr_t'(32'h0), addr_t'(32'h4),
                           addr_t'(32'h8), addr_t'(32'h20) };
          // (alignment checked in transaction)
        }) else $fatal("[GEN] randomize failed (rand_addr_inrange)");
      end

      tr.i_htrans = HTRANS_NONSEQ;
      tr.i_hwdata = tr.i_hwrite ? rand_wdata() : '0;

      tr.display(); // optional
      gen_to_drv.put(tr);
    end
  endtask
  // -------------------------------------------------------------
  // BUSY state only (protocol stimulus):
  // - Drive HTRANS=BUSY to insert protocol BUSY cycles.
  // - Size/addr set to legal values; scoreboard may ignore data compare here.
  // -------------------------------------------------------------
  task test_Busy_State;
    repeat (num_gen) begin
      tr = new();
      assert(tr.randomize() with {
        i_hwrite dist {0:=50, 1:=50};
      }) else $fatal("[GEN] randomize failed (BUSY)");
      tr.i_haddr  = addr_t'(32'h0000_0004);
      tr.i_htrans = HTRANS_BUSY;
      tr.i_hsize  = HSIZE_WORD; // harmless default
      tr.i_hwdata = tr.i_hwrite ? rand_wdata() : '0;

      tr.display(); // optional
      gen_to_drv.put(tr);
    end
  endtask

  // -------------------------------------------------------------
  // IDLE state only (protocol stimulus):
  // - Drive HTRANS=IDLE to create idle cycles.
  // -------------------------------------------------------------
  task test_IDLE_State;
    repeat (num_gen) begin
      tr = new();
      assert(tr.randomize() with {
        i_hwrite dist {0:=50, 1:=50};
      }) else $fatal("[GEN] randomize failed (IDLE)");
      tr.i_haddr  = '0;
      tr.i_htrans = HTRANS_IDLE;
      tr.i_hsize  = HSIZE_WORD; // harmless default
      tr.i_hwdata = '0;

      tr.display(); // optional
      gen_to_drv.put(tr);
    end
  endtask

  task test_SEQ;
    repeat (num_gen) begin
      tr = new();
      assert(tr.randomize() with {
        i_hwrite dist {0:=50, 1:=50};
        i_haddr inside { addr_t'(32'h0), addr_t'(32'h8),
                           addr_t'(32'h10), addr_t'(32'h20) };
      }) else $fatal("[GEN] randomize failed (IDLE)");
      tr.i_htrans = HTRANS_SEQ;
      tr.i_hsize  = HSIZE_WORD; // harmless default
      tr.i_hwdata = tr.i_hwrite ? rand_wdata() : '0;

      tr.display(); // optional
      gen_to_drv.put(tr);
    end
  endtask

  task test_hresp;
    repeat (num_gen) begin
    tr = new();

    assert(tr.randomize() with {
        i_hwrite dist {0:=50, 1:=50};
        i_haddr inside {[addr_lo : addr_hi]};
        i_hsize == HSIZE_DWORD; 
    }) else $fatal("[GEN] randomize failed (rand_addr)");
    
    tr.i_htrans = HTRANS_NONSEQ;
    tr.i_hwdata = tr.i_hwrite ? rand_wdata() : '0;

    tr.display("TEST HRESP");
    gen_to_drv.put(tr);
  end
  endtask

  // -------------------------------------------------------------
  // RUN TEST CASES
  // -------------------------------------------------------------
  task automatic run;
    case (test)
      TEST_RAND_HSIZE,
      READ_WAIT_STATE,
      WRITE_WAIT_STATE,
      FIXED_ADDR:        fixed_addr(FIXED_HSIZE);
      RAND_ADDR:         rand_addr();
      RAND_ADDR_INRANGE: rand_addr_inrange(FIXED_HSIZE);
      TEST_BUSY:         test_Busy_State();
      TEST_IDLE:         test_IDLE_State();
      TEST_SEQ:          test_SEQ();
      TEST_HRESP:        test_hresp();
      default:           $fatal("[GEN] Unknown test case");
    endcase
  endtask

endclass

`default_nettype wire
