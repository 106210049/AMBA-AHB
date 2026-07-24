// ============================================
// ahb_monitor.sv
// ============================================
import ahb_pkg::*;

class monitor #(
  parameter int ADDR_WIDTH = 32,
  parameter int DATA_WIDTH = 32,
  parameter bit GATE_ADDR_BY_READY = 1
);

  virtual taxi_ahbl_if#(ADDR_WIDTH, DATA_WIDTH).MON vif;
  mailbox mon_to_sb;

  // ------------------------------------------
  // Constructor
  // ------------------------------------------
  function new(
    virtual taxi_ahbl_if#(ADDR_WIDTH, DATA_WIDTH).MON vif,
    mailbox mon_to_sb = null
  );
    this.vif       = vif;
    this.mon_to_sb = mon_to_sb;
  endfunction

  // ------------------------------------------
  // Reset check (active-low)
  // ------------------------------------------
  function bit reset_active();
    return (vif.cb_mon.i_hreset === 1'b0);
  endfunction

  // ------------------------------------------
  // Address phase valid
  // ------------------------------------------
  function bit addr_phase_valid();
    return ((vif.cb_mon.i_hsel      === 1'b1));
  endfunction

  // ------------------------------------------
  // Address phase gated by HREADYOUT
  // ------------------------------------------
  function bit addr_accept_gate();
    return ((vif.cb_mon.i_hsel      === 1'b1) &&
            (vif.cb_mon.o_hreadyout === 1'b1));
  endfunction

  // ------------------------------------------
  // Capture Address phase
  // ------------------------------------------
  task capture_address_phase(
    ref ahb_trans#(ADDR_WIDTH,DATA_WIDTH) tr
  );
    tr.i_haddr  = vif.cb_mon.i_haddr;
    tr.i_hwrite = vif.cb_mon.i_hwrite;
    tr.i_hsize  = hsize_e'(vif.cb_mon.i_hsize);
    tr.i_htrans = htrans_e'(vif.cb_mon.i_htrans);
    tr.sample_coverage();

    $display(
      "[%0t][MON-ADDR] A=0x%0h W=%0b HSIZE=%s HTRANS=%s",
      $time,
      tr.i_haddr,
      tr.i_hwrite,
      hsize_name(tr.i_hsize),
      htrans_name(tr.i_htrans)
    );
  endtask

  // ------------------------------------------
  // Wait until Data phase complete (HREADYOUT=1)
  // ------------------------------------------
  task wait_data_complete();
    do @(vif.cb_mon);
    while (vif.cb_mon.o_hreadyout !== 1'b1);
  endtask

  // ------------------------------------------
  // Capture Data phase
  // ------------------------------------------
  task capture_data_phase(
    ref ahb_trans#(ADDR_WIDTH,DATA_WIDTH) tr
  );

    wait_data_complete();

    tr.o_hreadyout = vif.cb_mon.o_hreadyout;
    tr.o_hresp     = vif.cb_mon.o_hresp;

    if (tr.i_hwrite) begin
      tr.i_hwdata = vif.cb_mon.i_hwdata;
      $display(
        "[%0t][WRITE][MON-DATA] A=0x%0h WDATA=0x%0h RESP=%0b",
        $time,
        tr.i_haddr,
        tr.i_hwdata,
        tr.o_hresp
      );
    end
    else begin
      tr.o_hrdata = vif.cb_mon.o_hrdata;
      $display(
        "[%0t][READ][MON-DATA] A=0x%0h RDATA=0x%0h RESP=%0b",
        $time,
        tr.i_haddr,
        tr.o_hrdata,
        tr.o_hresp
      );
    end

    if (mon_to_sb != null)
      mon_to_sb.put(tr);

  endtask

  // ------------------------------------------
  // Main monitor loop
  // ------------------------------------------
  task run();

    ahb_trans#(ADDR_WIDTH,DATA_WIDTH) tr;

    forever begin
      @(vif.cb_mon);

      if (reset_active())
        continue;

      if (GATE_ADDR_BY_READY ? addr_accept_gate() : addr_phase_valid()) begin

        tr = new();

        capture_address_phase(tr);

        capture_data_phase(tr);

      end
    end

  endtask

endclass
