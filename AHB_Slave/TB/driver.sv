// driver.sv (fixed to not toggle when o_hreadyout==0)
// – Only update signals at @(vif.cb_drv iff o_hreadyout)
// – Do not drive i_hreadyin (it is tied‑high inside the interface and read‑only in the DRV modport)

import ahb_pkg::*;

class driver #(
  parameter int ADDR_WIDTH = 32,
  parameter int DATA_WIDTH = 32
);

    mailbox gen_to_drv;

    virtual taxi_ahbl_if #(ADDR_WIDTH, DATA_WIDTH).DRV vif;

    ahb_trans #(ADDR_WIDTH, DATA_WIDTH) tr;

    function new(mailbox gen_to_drv, virtual taxi_ahbl_if#(ADDR_WIDTH, DATA_WIDTH).DRV vif);
        this.gen_to_drv = gen_to_drv;
        this.vif = vif;
    endfunction

    
    task automatic drive_idle();
    @(vif.cb_drv iff vif.cb_drv.o_hreadyout);
    vif.cb_drv.i_hsel   <= 1'b0;
    vif.cb_drv.i_haddr  <= '0;
    vif.cb_drv.i_hwrite <= 1'b0;
    vif.cb_drv.i_hsize  <= HSIZE_WORD;
    vif.cb_drv.i_htrans <= HTRANS_IDLE;
    vif.cb_drv.i_hwdata <= '0;
    endtask

    task automatic drive_busy(input ahb_trans#(ADDR_WIDTH, DATA_WIDTH) tr);
        @(vif.cb_drv iff vif.cb_drv.o_hreadyout);
        vif.cb_drv.i_hsel   <= 1'b1;
        vif.cb_drv.i_haddr  <= tr.i_haddr;
        vif.cb_drv.i_hwrite <= 1'b0;
        vif.cb_drv.i_hsize  <= HSIZE_WORD;
        vif.cb_drv.i_htrans <= HTRANS_BUSY;
        vif.cb_drv.i_hwdata <= '0;
    endtask

    task automatic Address_phase(input ahb_pkg::htrans_e HTRANS,
                                input ahb_trans#(ADDR_WIDTH, DATA_WIDTH) tr);
        @(vif.cb_drv iff vif.cb_drv.o_hreadyout);
        vif.cb_drv.i_hsel   <= 1'b1;
        vif.cb_drv.i_haddr  <= tr.i_haddr;
        vif.cb_drv.i_hwrite <= tr.i_hwrite;
        vif.cb_drv.i_hsize  <= tr.i_hsize;
        vif.cb_drv.i_htrans <= HTRANS;
        vif.cb_drv.i_hreadyin <= 1'b1;
    endtask


    task automatic Data_phase(input ahb_trans#(ADDR_WIDTH, DATA_WIDTH) tr);
        @(vif.cb_drv iff vif.cb_drv.o_hreadyout);
        if (tr.i_hwrite)  vif.cb_drv.i_hwdata <= tr.i_hwdata;
        else              vif.cb_drv.i_hwdata <= '0;
    endtask

    task automatic waiting_state();
        do @(vif.cb_drv); while (vif.cb_drv.o_hreadyout !== 1'b1);
    endtask
    
    task reset();
        wait (vif.cb_drv.i_hreset == 1'b0);
        // 2) While reset is active, drive benign/IDLE on cb edge
        @(vif.cb_drv);
        drive_idle();
        // 3) Wait for reset deasserted
        wait (vif.cb_drv.i_hreset == 1'b1);
    endtask

    task non_seq(
        input ahb_trans#(ADDR_WIDTH, DATA_WIDTH) tr
    );
        // 1) ADDRESS PHASE: issued on a clock edge where o_hreadyout = 1
        Address_phase(ahb_pkg::HTRANS_NONSEQ, tr);
        // 2) DATA PHASE ENTRY:
        // To prevent signal changes during wait states, hwdata is updated only on a ready = 1 edge.
        // (If the slave deasserts ready immediately after the address phase,
        //  the driver delays the data update until the next ready = 1 cycle.)
        Data_phase(tr);
        // 3) WAIT-STATE HANDLING: wait until the transfer completes (ready returns to 1)
        // Do not re‑assign any signal during the wait period (keep all values stable).
        waiting_state();
    endtask
    
    task seq(input ahb_trans#(ADDR_WIDTH, DATA_WIDTH) tr);
        // 1) ADDRESS PHASE: issued on a clock edge where o_hreadyout = 1
        Address_phase(ahb_pkg::HTRANS_SEQ, tr);
        // 2) DATA PHASE ENTRY:
        // To prevent signal changes during wait states, hwdata is updated only on a ready = 1 edge.
        // (If the slave deasserts ready immediately after the address phase,
        //  the driver delays the data update until the next ready = 1 cycle.)
        Data_phase(tr);
        // 3) WAIT-STATE HANDLING: wait until the transfer completes (ready returns to 1)
        // Do not re‑assign any signal during the wait period (keep all values stable).
        waiting_state();
    endtask
    

    task run;
        reset();
        forever begin
            wait(vif.cb_drv.o_hreadyout == 1'b1);
            gen_to_drv.get(tr);
            unique case (tr.i_htrans)
                HTRANS_NONSEQ: non_seq(tr);
                HTRANS_SEQ:    seq(tr);
                HTRANS_BUSY  : begin
                drive_busy(tr);
                // (tuỳ chọn) 1 beat IDLE để rõ dạng sóng
                // drive_idle_1beat();
                end
                HTRANS_IDLE  : drive_idle();   // 1 idle beat
                default      : drive_idle();   // fallback an toàn
            endcase
        end
    endtask

endclass