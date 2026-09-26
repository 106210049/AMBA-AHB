//-----------------------------------------------------------------------------
// ahb_scoreboard.sv
// UVM scoreboard: always take least-significant nbytes of original write value
// and left-justify them into MSB for expected comparison.
// Requires ahb_define_pkg with helpers: logical_to_phys, byte_at_lane,
// set_byte_at_lane, get_logical_byte_from_word_32, build_mask_msb_shifted.
//-----------------------------------------------------------------------------

`include "uvm_macros.svh"
import ahb_define_pkg::*;

typedef struct {
  int unsigned addr;
  bit [31:0] data;      // merged memory word (physical lanes)
  bit [31:0] orig_data; // original write value (hwdata) as driven by master
} snapshot_t;

class ahb_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(ahb_scoreboard);

  // Analysis imp declarations (macro kept for compatibility)
  `uvm_analysis_imp_decl(_master)
  `uvm_analysis_imp_decl(_slave)

  uvm_analysis_imp_master #(ahb_master_sequence_item, ahb_scoreboard) master_imp;
  uvm_analysis_imp_slave  #(ahb_slave_sequence_item,  ahb_scoreboard) slave_imp;

  // Queues
  ahb_master_sequence_item exp_queue[$];
  ahb_slave_sequence_item  act_queue[$];

  // History (last-write snapshot per 32-bit word)
  snapshot_t history[$];
  bit [31:0] write_data_by_addr[int unsigned];
  // Stats
  int total;
  int n_wr;
  int n_rd;
  int n_err;

  // Config
  endian_e endian;
  localparam int DATA_WIDTH = 32;

  // Constructor
  function new(string name = "ahb_scoreboard", uvm_component parent = null);
    super.new(name, parent);
    master_imp = new("master_imp", this);
    slave_imp  = new("slave_imp", this);
    total = 0; n_wr = 0; n_rd = 0; n_err = 0;
    endian = BIG_ENDIAN; // default; testbench can override
  endfunction

  // -------------------------
  // Store write into history (merge bytes into 32-bit word at word_base)
  // Also store original write value (orig_data) for expected building.
  // - wdata: 32-bit value driven on bus for the write (hwdata)
  // - size: hsize_t (HSIZE_BYTE/HWORD/WORD...)
  // Behavior:
  // - compute word_base = addr & ~3
  // - compute byte_index = addr & 3
  // - for j=0..nbytes-1: extract logical j-th byte from wdata (logical order)
  //   and write it into physical lane = logical_to_phys(byte_index, j, endian)
  // -------------------------
  task automatic store_history_aligned(input int unsigned addr,
                                      input bit [DATA_WIDTH-1:0] wdata,
                                      input hsize_t size);
    int unsigned word_base;
    int byte_index;
    int nbytes;
    int i;
    int j;
    int phys;
    bit found;
    bit [31:0] cur_word;
    snapshot_t snap;
    byte b;

    word_base  = addr & ~32'h3;
    byte_index = addr & 3;
    nbytes     = hsize2bytes(size);

    // search existing snapshot
    found = 0;
    for (i = history.size() - 1; i >= 0; i = i - 1) begin
      if (history[i].addr == word_base) begin
        cur_word = history[i].data;
        for (j = 0; j < nbytes; j = j + 1) begin
          phys = logical_to_phys(byte_index, j, endian);
          // get logical j-th byte from wdata (logical order inside field)
          b = get_logical_byte_from_word_32(wdata, byte_index, j, endian);
          cur_word = set_byte_at_lane(cur_word, phys, b);
        end
        // update merged word and original write value
        history[i].data      = cur_word;
        history[i].orig_data = wdata;
        found = 1;
        break;
      end
    end

    if (!found) begin
      bit [31:0] new_word = '0;
      for (j = 0; j < nbytes; j = j + 1) begin
        phys = logical_to_phys(byte_index, j, endian);
        b = get_logical_byte_from_word_32(wdata, byte_index, j, endian);
        new_word = set_byte_at_lane(new_word, phys, b);
      end
      snap.addr      = word_base;
      snap.data      = new_word;
      snap.orig_data = wdata;
      history.push_back(snap);
    end
  endtask

  // Retrieve last history entry for word_base = addr & ~3
  // Returns merged data and original write value
  task automatic get_history_aligned(input int unsigned addr,
                                     output bit [DATA_WIDTH-1:0] data,
                                     output bit [DATA_WIDTH-1:0] orig,
                                     output bit found);
    int unsigned word_base;
    int i;
    word_base = addr & ~32'h3;
    data  = '0;
    orig  = '0;
    found = 0;
    for (i = history.size() - 1; i >= 0; i = i - 1) begin
      if (history[i].addr == word_base) begin
        data  = history[i].data;
        orig  = history[i].orig_data;
        found = 1;
        break;
      end
    end
  endtask

  // -------------------------
  // Build expected ALWAYS left-justified to MSB from original write value
  // - Extract least-significant nbytes from orig_data and left-shift into MSB.
  // Example: orig_data = 0xF10EEA87, HWORD -> extract 0xEA87 -> exp = 0xEA870000
  // -------------------------
    function automatic bit [DATA_WIDTH-1:0] build_expected_msb_from_orig(
      input int unsigned addr,
      input bit [DATA_WIDTH-1:0] orig_data,
      input hsize_t size
    );

        int nbytes;
        bit [DATA_WIDTH-1:0] low_mask;

        nbytes = hsize2bytes(size);

        if (nbytes >= 4)
        return orig_data;

        low_mask = (32'h1 << (nbytes * 8)) - 1;

        return (orig_data & low_mask) << (DATA_WIDTH - nbytes * 8);
  endfunction

  // Wrapper to call package mask helper MSB-shifted
  function automatic bit [DATA_WIDTH-1:0] build_mask_msb_shifted_wrapper(hsize_t size, int byte_index);
    build_mask_msb_shifted_wrapper = build_mask_msb_shifted(size, byte_index);
  endfunction

  // -------------------------
  // Analysis write callbacks
  // -------------------------
  function void write_master(ahb_master_sequence_item pkt);
    ahb_master_sequence_item scb_pkt;
    uvm_object tmp;
    tmp = pkt.clone();
    $cast(scb_pkt, tmp);
    exp_queue.push_back(scb_pkt);
    total = total + 1;
    if (pkt.i_write) n_wr = n_wr + 1;
    else n_rd = n_rd + 1;
  endfunction

  function void write_slave(ahb_slave_sequence_item pkt);
    ahb_slave_sequence_item scb_pkt;
    uvm_object tmp;
    tmp = pkt.clone();
    $cast(scb_pkt, tmp);
    act_queue.push_back(scb_pkt);
  endfunction

  // -------------------------
  // Main check_phase
  // -------------------------
   function void check_phase(uvm_phase phase);
    ahb_master_sequence_item exp;
    ahb_slave_sequence_item  act;

    int size_bytes;
    int k;
    bit match;
    bit [31:0] exp_word;
    bit [31:0] mask;
    bit [31:0] original_write_data;

    while ((exp_queue.size() > 0) && (act_queue.size() > 0)) begin
      exp = exp_queue.pop_front();
      act = act_queue.pop_front();

      size_bytes = hsize2bytes(exp.i_data_size);
      match = 1'b0;

      // Address check
      case (exp.i_burst_type)
        SINGLE:
          match = (act.haddr == exp.haddr);

        INCR:
          match = (act.haddr >= exp.haddr) &&
                  (((act.haddr - exp.haddr) % size_bytes) == 0);

        INCR4:
          for (k = 0; k < 4; k++)
            if (act.haddr == exp.haddr + size_bytes*k)
              match = 1'b1;

        INCR8:
          for (k = 0; k < 8; k++)
            if (act.haddr == exp.haddr + size_bytes*k)
              match = 1'b1;

        INCR16:
          for (k = 0; k < 16; k++)
            if (act.haddr == exp.haddr + size_bytes*k)
              match = 1'b1;

        WRAP4:
          for (k = 0; k < 4; k++)
            if (act.haddr ==
                (exp.haddr & ~((size_bytes*4)-1)) +
                ((exp.haddr + size_bytes*k) & ((size_bytes*4)-1)))
              match = 1'b1;

        WRAP8:
          for (k = 0; k < 8; k++)
            if (act.haddr ==
                (exp.haddr & ~((size_bytes*8)-1)) +
                ((exp.haddr + size_bytes*k) & ((size_bytes*8)-1)))
              match = 1'b1;

        WRAP16:
          for (k = 0; k < 16; k++)
            if (act.haddr ==
                (exp.haddr & ~((size_bytes*16)-1)) +
                ((exp.haddr + size_bytes*k) & ((size_bytes*16)-1)))
              match = 1'b1;

        default:
          match = (act.haddr == exp.haddr);
      endcase

      if (!match) begin
        n_err++;

        `uvm_error("SCOREBOARD_ADDR",
          $sformatf(
            "ADDR FAIL: expected=0x%0h actual=0x%0h burst=%s size=%s",
            exp.haddr,
            act.haddr,
            exp.i_burst_type.name(),
            exp.i_data_size.name()))
      end
      else begin
        `uvm_info("SCOREBOARD_ADDR",
          $sformatf(
            "ADDR PASS: expected=0x%0h actual=0x%0h burst=%s size=%s",
            exp.haddr,
            act.haddr,
            exp.i_burst_type.name(),
            exp.i_data_size.name()),
          UVM_MEDIUM)
      end

      // Data check
      if (exp.i_write) begin
        // Mỗi lần WRITE sẽ cập nhật dữ liệu mới nhất tại địa chỉ đó.
        // Vì vậy WRITE sau sẽ ghi đè WRITE trước.
        write_data_by_addr[act.haddr] = exp.i_data;

        if (act.hwdata !== exp.i_data) begin
          n_err++;

          `uvm_error("SCOREBOARD_DATA",
            $sformatf(
              "WRITE FAIL: addr=0x%0h exp=0x%0h act=0x%0h",
              act.haddr,
              exp.i_data,
              act.hwdata))
        end
        else begin
          `uvm_info("SCOREBOARD_DATA",
            $sformatf(
              "WRITE PASS: addr=0x%0h data=0x%0h",
              act.haddr,
              act.hwdata),
            UVM_MEDIUM)
        end
      end
      else begin
        if (!write_data_by_addr.exists(act.haddr)) begin
          n_err++;

          `uvm_error("SCOREBOARD_DATA",
            $sformatf(
              "READ FAIL: no WRITE history for addr=0x%0h",
              act.haddr))
        end
        else begin
          // Lấy WRITE mới nhất tại đúng địa chỉ.
          original_write_data = write_data_by_addr[act.haddr];

          exp_word = build_expected_msb_from_orig(
                       act.haddr,
                       original_write_data,
                       exp.i_data_size);

          mask = build_mask_msb_shifted_wrapper(
                   exp.i_data_size,
                   act.haddr & 3);

          if ((act.hrdata & mask) !== (exp_word & mask)) begin
            n_err++;

            `uvm_error("SCOREBOARD_DATA",
              $sformatf(
                "READ FAIL: addr=0x%0h write_data=0x%0h exp=0x%0h act=0x%0h mask=0x%0h",
                act.haddr,
                original_write_data,
                exp_word,
                act.hrdata,
                mask))
          end
          else begin
            `uvm_info("SCOREBOARD_DATA",
              $sformatf(
                "READ PASS: addr=0x%0h exp=0x%0h act=0x%0h",
                act.haddr,
                exp_word,
                act.hrdata),
              UVM_MEDIUM)
          end
        end
      end
    end

    if ((exp_queue.size() != 0) || (act_queue.size() != 0)) begin
      n_err++;

      `uvm_error("SCOREBOARD",
        $sformatf(
          "Transaction count mismatch: expected_queue=%0d actual_queue=%0d",
          exp_queue.size(),
          act_queue.size()))
    end
  endfunction

  // Report phase summary
  function void report_phase(uvm_phase phase);
    `uvm_info(get_type_name(),
      $sformatf("Scoreboard Summary: Total=%0d WR=%0d RD=%0d ERR=%0d",
                total, n_wr, n_rd, n_err), UVM_NONE)
  endfunction

endclass : ahb_scoreboard
