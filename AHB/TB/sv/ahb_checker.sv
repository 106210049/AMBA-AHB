import ahb_define_pkg::*;
`define AHB_OKAY  1'b0
`define AHB_ERROR 1'b1
program ahb_checker (ahb_if vif);


    property p_okay_complete;
    @(posedge hclk)
        disable iff (!hreset_n)
        (vif.hready && vif.hresp == `AHB_OKAY);
    endproperty

    COVER_OKAY: cover property(p_okay_complete)
    $display("[COVER] OKAY COMPLETE observed");

    property p_wait_state;
    @(posedge hclk)
        disable iff (!hreset_n)
        $rose(vif.i_wait_1) |=> (!vif.hready);
    endproperty

    ASSERT_WAIT: assert property(p_wait_state)
    $display("[PASS] Wait State check OK");
    else
    $error("[FAIL] When i_wait_1 rises, hready must=0 next cycle");

    COVER_WAIT: cover property(p_wait_state)
    $display("[COVER] Wait State observed");


    // property p_master_busy;
    // @(posedge hclk)
    //     disable iff (!hreset_n)
    //     $rose(vif.i_busy) |-> ##1
    //     (vif.htrans != ahb_define_pkg::IDLE &&
    //         !vif.hready &&
    //         vif.htrans == ahb_define_pkg::BUSY);
    // endproperty

    // ASSERT_BUSY_NEXT: assert property(p_master_busy)
    // $display("[PASS] BUSY State check OK");
    // else
    // $error("[FAIL] When i_busy rises and htrans != IDLE, hready must=0 and htrans=BUSY next cycle");

    // COVER_BUSY_NEXT: cover property(p_master_busy)
    // $display("[COVER] BUSY transaction observed");

endprogram: ahb_checker