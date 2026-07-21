// agent.sv
// Purpose: Bundle generator/driver/monitor and wire them to the AHB interface modports.
// - Keeps a mailbox from generator -> driver.
// - Passes the DRV modport to driver and the MON modport to monitor.
// - Can run with or without the generator (push items directly from test).
// - Provides convenient push APIs to send transactions to the driver.

`default_nettype none

// import ahb_pkg::*; // for enums HTRANS_*, HSIZE_* used in push APIs

class agent #(
  parameter int ADDR_WIDTH = 32,
  parameter int DATA_WIDTH = 32
);

  // Virtual interface modports (clocking views)
  virtual taxi_ahbl_if#(ADDR_WIDTH, DATA_WIDTH).DRV drv_vif;
  virtual taxi_ahbl_if#(ADDR_WIDTH, DATA_WIDTH).MON mon_vif;

  // Components
  generator  #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH)) gen;
  driver     #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH)) drv;
  monitor    #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH)) mon;

  // Mailboxes
  mailbox gen_to_drv; // generator -> driver
  mailbox mon_to_sb;  // monitor   -> scoreboard (provided by testbench/top)

  // Start guards (avoid multiple spawns)
  // bit started_drv_mon;
  // bit started_all;

  // --------------------------------------------
  // Constructor
  // --------------------------------------------
  function new( virtual taxi_ahbl_if#(ADDR_WIDTH, DATA_WIDTH).DRV drv_vif,
                virtual taxi_ahbl_if#(ADDR_WIDTH, DATA_WIDTH).MON mon_vif,
                mailbox mon_to_sb );
    this.drv_vif   = drv_vif;
    this.mon_vif   = mon_vif;
    this.mon_to_sb = mon_to_sb;

    // Create mailbox for generator -> driver
    gen_to_drv = new();

    // Create components
    gen = new(gen_to_drv);
    drv = new(gen_to_drv, this.drv_vif);
    mon = new(this.mon_vif, this.mon_to_sb);

    // started_drv_mon = 1'b0;
    // started_all     = 1'b0;
  endfunction

  // --------------------------------------------
  // (Optional) Configure generator via a clean API
  // tc: 0=FIXED_ADDR, 1=RAND_ADDR, 2=RAND_ADDR_INRANGE, 3=TEST_BUSY, 4=TEST_IDLE
  // --------------------------------------------
  function void cfg_gen(
      input int                 num_gen,
      input bit                 fixed_hsize,
      input test_case           tc,
      input bit [ADDR_WIDTH-1:0] addr_lo = '0,
      input bit [ADDR_WIDTH-1:0] addr_hi = '1
  );
    gen.num_gen     = num_gen;
    gen.FIXED_HSIZE = fixed_hsize;
    gen.test        = tc;      // implicit cast to enum inside generator
    gen.addr_lo     = addr_lo;
    gen.addr_hi     = addr_hi;
  endfunction

  // --------------------------------------------
  // Start driver + monitor ONCE (recommended for generator-mode)
  // --------------------------------------------
  // task run_drv_mon();
  //   if (!started_drv_mon) begin
  //     started_drv_mon = 1'b1;
  //     fork
  //       drv.run();
  //       mon.run();
  //     join_none
  //   end
  // endtask

  // // --------------------------------------------
  // // Run generator ONCE (blocking)
  // // Call after cfg_gen(), typically in tb_top per testcase
  // // --------------------------------------------
  // task run_gen();
  //   gen.run();
  // endtask
  task run();
    fork
      gen.run();
      drv.run();
      mon.run();
    join_none
  endtask

endclass

`default_nettype wire