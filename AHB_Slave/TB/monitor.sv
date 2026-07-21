`define MON_DEBUG 1
import ahb_pkg::*;
class monitor #(
  parameter int ADDR_WIDTH = 32,
  parameter int DATA_WIDTH = 32,
  parameter bit GATE_ADDR_BY_READY = 1
);
  virtual taxi_ahbl_if#(ADDR_WIDTH, DATA_WIDTH).MON vif;

  mailbox mon_to_sb;

  // -------------------------
  // Constructor
  // -------------------------
  function new(virtual taxi_ahbl_if#(ADDR_WIDTH, DATA_WIDTH).MON vif,
               mailbox mon_to_sb = null);
    this.vif       = vif;
    this.mon_to_sb = mon_to_sb;
  endfunction

  // -------------------------
  // Helper: Check reset active (active-low)
  // -------------------------
  function bit reset_active();
    // Dùng case-equality để tránh X/Z
    return (vif.cb_mon.i_hreset === 1'b0);
  endfunction

  // -------------------------
 
  // -------------------------
  function bit addr_phase_valid();
    bit base;
    base = ((vif.cb_mon.i_hsel      === 1'b1) &&
            (vif.cb_mon.i_htrans[1] === 1'b1));
    return base;
  endfunction

  // -------------------------
  // -------------------------
  function bit addr_accept_gate();
    return ((vif.cb_mon.i_hsel      === 1'b1) &&
            (vif.cb_mon.i_htrans[1] === 1'b1) &&
            (vif.cb_mon.o_hreadyout === 1'b1));
  endfunction

  // -------------------------
  // -------------------------
  task Address_phase(input ahb_trans#(ADDR_WIDTH,DATA_WIDTH) tr);
    if (tr == null) return; // an toàn, tránh null access

    // Snapshot request (address-phase) fields
    tr.i_haddr  = vif.cb_mon.i_haddr;
    tr.i_hwrite = vif.cb_mon.i_hwrite;
    tr.i_hsize  = hsize_e'(vif.cb_mon.i_hsize);
    tr.i_htrans = htrans_e'(vif.cb_mon.i_htrans);
    tr.sample_coverage();
    `ifdef MON_DEBUG
      $display("[%0t][MON-ADDR] A=0x%0h W=%0b HSIZE=%s HTRANS=%s",
               $time,
               tr.i_haddr,
               tr.i_hwrite,
               hsize_name(tr.i_hsize),
               htrans_name(tr.i_htrans));
    `endif
  endtask

  // -------------------------
  // -------------------------
  task Data_phase(input ahb_trans#(ADDR_WIDTH,DATA_WIDTH) tr);
    if (tr == null) return; // an toàn, tránh null access

    waiting_state(); // chờ completion

    tr.o_hreadyout = vif.cb_mon.o_hreadyout;
    tr.o_hresp     = vif.cb_mon.o_hresp;

    if (tr.i_hwrite) begin
      // WRITE: dữ liệu do master cung cấp, chụp tại completion
      tr.i_hwdata = vif.cb_mon.i_hwdata;
      `ifdef MON_DEBUG
        $display("[%0t][MON-WR]  A=0x%0h WDATA=0x%0h RESP=%0b",
                 $time, tr.i_haddr, tr.i_hwdata, tr.o_hresp);
      `endif
    end
    else begin
      // READ: dữ liệu do slave trả về, chụp tại completion
      tr.o_hrdata = vif.cb_mon.o_hrdata;
      `ifdef MON_DEBUG
        $display("[%0t][MON-RD]  A=0x%0h RDATA=0x%0h RESP=%0b",
                 $time, tr.i_haddr, tr.o_hrdata, tr.o_hresp);
      `endif
    end

    // Publish sang scoreboard nếu có
    if (mon_to_sb != null) mon_to_sb.put(tr);
  endtask

  // -------------------------
  // Task: Chờ đến khi HREADYOUT==1 (completion)
  // -------------------------
  task waiting_state();
    do @(vif.cb_mon); while (vif.cb_mon.o_hreadyout !== 1'b1);
  endtask

  // -------------------------
  // RUN: Vòng lặp chính của monitor
  // -------------------------
  task run;
    ahb_trans#(ADDR_WIDTH,DATA_WIDTH) tr;

    forever begin
      @(vif.cb_mon);

      if (reset_active()) begin
        tr = null;
        continue;
      end

      if (GATE_ADDR_BY_READY ? addr_accept_gate() : addr_phase_valid()) begin
        tr = new();

        Address_phase(tr);

        Data_phase(tr);

        tr = null;
      end
    end
  endtask

endclass