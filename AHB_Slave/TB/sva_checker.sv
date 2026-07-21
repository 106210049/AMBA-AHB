`define AHB_OKAY  1'b0
`define AHB_ERROR 1'b1

program sva_checker (taxi_ahbl_if vif);

  // ==========================================
  // 1. VALID SIGNAL (no X/Z)
  // ==========================================
  property p_valid_resp;
  @(vif.cb_mon)
    disable iff (!vif.cb_mon.i_hreset)
    (vif.cb_mon.i_hsel &&
     vif.cb_mon.i_htrans[1] &&   // VALID transfer
     vif.cb_mon.o_hreadyout)
    |->
    (!$isunknown(vif.cb_mon.o_hreadyout) &&
     !$isunknown(vif.cb_mon.o_hresp));
endproperty

  ASSERT_VALID_RESP: assert property(p_valid_resp)
  $display("[PASS] VALID_RESP OK");
else
  $error("[FAIL] HREADYOUT/HRESP is X/Z");



  // ==========================================
  // 2. OKAY COMPLETE (coverage)
  // ==========================================
  property p_okay_complete;
    @(vif.cb_drv iff vif.cb_drv.o_hreadyout)
      disable iff (!vif.cb_mon.i_hreset)
      (vif.cb_mon.o_hreadyout == 1 &&
       vif.cb_mon.o_hresp == `AHB_OKAY);
  endproperty

  COVER_OKAY: cover property(p_okay_complete)
    $display("[COVER] OKAY COMPLETE observed");


  // ==========================================
  // 3. ERROR must be 2-cycle
  // ==========================================
  property p_error_two_cycle;
    @(vif.cb_drv iff vif.cb_drv.o_hreadyout)
      disable iff (!vif.cb_mon.i_hreset)
      (vif.cb_mon.o_hresp == `AHB_ERROR &&
       vif.cb_mon.o_hreadyout == 0)
      |=> (vif.cb_mon.o_hresp == `AHB_ERROR &&
           vif.cb_mon.o_hreadyout == 1);
  endproperty

  ASSERT_ERROR_2CYCLE: assert property(p_error_two_cycle)
    $display("[PASS] ERROR 2-cycle OK");
    else
    $error("[FAIL] ERROR must be 2 cycles");

  // ==========================================
  // 4. No single-cycle ERROR
  // ==========================================
  property p_no_single_cycle_error;
    @(vif.cb_drv iff vif.cb_drv.o_hreadyout)
      disable iff (!vif.cb_mon.i_hreset)
      (vif.cb_mon.o_hresp == `AHB_ERROR &&
       vif.cb_mon.o_hreadyout == 1)
      |-> $past(vif.cb_mon.o_hresp == `AHB_ERROR &&
                vif.cb_mon.o_hreadyout == 0);
  endproperty

  ASSERT_NO_SINGLE_ERR: assert property(p_no_single_cycle_error)
    $display("[PASS] NO SINGLE ERROR OK");
    else
    $error("[FAIL] Single-cycle ERROR not allowed");


  // ==========================================
  // 5. HSIZE == 3 must return ERROR
  // ==========================================
  property p_hsize3_error;
    @(vif.cb_drv iff vif.cb_drv.o_hreadyout)
      disable iff (!vif.cb_mon.i_hreset)
      (vif.cb_mon.i_hsize == 3)
      |->
      (vif.cb_mon.o_hresp == `AHB_ERROR);
  endproperty

  ASSERT_HSIZE3_ERROR: assert property(p_hsize3_error)
    $display("[PASS] HSIZE=3 correctly returns ERROR");
  else
    $error("[FAIL] HSIZE=3 must return ERROR");

	
   property p_htrans_seq_error;
    @(vif.cb_drv iff vif.cb_drv.o_hreadyout)
      disable iff (!vif.cb_mon.i_hreset)
      (vif.cb_mon.i_htrans == HTRANS_SEQ)
      |->
      (vif.cb_mon.o_hresp == `AHB_ERROR);
    endproperty

    ASSERT_HTRANS_SEQ_ERROR: assert property(p_htrans_seq_error)
      $display("[PASS] HTRANS=SEQ correctly returns ERROR");
    else
      $error("[FAIL] HTRANS=SEQ must return ERROR");


endprogram