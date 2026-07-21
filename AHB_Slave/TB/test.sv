program test(taxi_ahbl_if vif);

  import testcase_pkg::*;

  // -----------------------------
  // Environment
  // -----------------------------
  env env_o;

  // -----------------------------
  // Runtime params
  // -----------------------------
  string testname;
  int    timeout;

  // -----------------------------
  // Main
  // -----------------------------
  initial begin

    //----------------------------------------
    // Default config
    //----------------------------------------
    testname = "RAND_ADDR";
    timeout  = 10000;

    //----------------------------------------
    // Override via plusargs
    //----------------------------------------
    void'($value$plusargs("TESTNAME=%s", testname));
    void'($value$plusargs("TIMEOUT=%d", timeout));

    $display("[TEST] TESTNAME=%s TIMEOUT=%0d", testname, timeout);

    //----------------------------------------
    // Create ENV
    // IMPORTANT: pass correct modports
    //----------------------------------------
    env_o = new(vif.DRV, vif.MON);

    //----------------------------------------
    // Configure TEST
    //----------------------------------------
    case (testname)

      //--------------------------------------------------
      // Address tests
      //--------------------------------------------------
      "FIXED_ADDR":
        env_o.agt.cfg_gen(8, 1, FIXED_ADDR);

      "RAND_ADDR":
        env_o.agt.cfg_gen(16, 0, RAND_ADDR,
                          32'h0000_0000,
                          32'h0000_00FF);

      "RAND_ADDR_INRANGE":
        env_o.agt.cfg_gen(30, 1, RAND_ADDR_INRANGE);

      //--------------------------------------------------
      // Protocol behavior tests
      //--------------------------------------------------
      "TEST_BUSY":
        env_o.agt.cfg_gen(10, 1, TEST_BUSY);

      "TEST_IDLE":
        env_o.agt.cfg_gen(10, 1, TEST_IDLE);

      "TEST_SEQ":
        env_o.agt.cfg_gen(10, 1, TEST_SEQ);

      //--------------------------------------------------
      // HSIZE stress test
      //--------------------------------------------------
      "TEST_RAND_HSIZE":
        env_o.agt.cfg_gen(8, 0, TEST_RAND_HSIZE);

      "READ_WAIT_STATE":
        env_o.agt.cfg_gen(8, 1, READ_WAIT_STATE);

      "WRITE_WAIT_STATE":
        env_o.agt.cfg_gen(8, 1, WRITE_WAIT_STATE);

       "TEST_HRESP":
        env_o.agt.cfg_gen(8, 1, TEST_HRESP);

      //--------------------------------------------------
      default:
        $fatal("[TEST] Unknown TESTNAME=%s", testname);

    endcase

    //----------------------------------------
    // Start ENV
    //----------------------------------------
    env_o.run();

    //----------------------------------------
    // Timeout control
    //----------------------------------------
    #(timeout);

    //----------------------------------------
    // Report + Finish
    //----------------------------------------
    $display("[TEST] TIMEOUT reached");

    env_o.report();

    $finish;

  end

endprogram