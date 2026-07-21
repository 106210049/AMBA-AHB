class env #(
  parameter int ADDR_WIDTH = 32,
  parameter int DATA_WIDTH = 32
);

  // -----------------------------
  // Components
  // -----------------------------
  agent     #(ADDR_WIDTH, DATA_WIDTH) agt;
  scoreboard#(ADDR_WIDTH, DATA_WIDTH) scb;

  // -----------------------------
  // Mailboxes
  // -----------------------------
  mailbox mon_to_sb;

  // -----------------------------
  // Constructor
  // -----------------------------
  function new(
    virtual taxi_ahbl_if#(ADDR_WIDTH, DATA_WIDTH).DRV drv_vif,
    virtual taxi_ahbl_if#(ADDR_WIDTH, DATA_WIDTH).MON mon_vif
  );
    // Shared mailbox (Monitor -> Scoreboard)
    mon_to_sb = new();

    // Agent: contains generator/driver/monitor
    agt = new(drv_vif, mon_vif, mon_to_sb);

    // Scoreboard: consumes monitor transactions
    scb = new(mon_to_sb);
  endfunction

  // -----------------------------
  // Run
  // -----------------------------
  task run();
    fork
      agt.run();
      scb.run();
    join_none
  endtask

  // -----------------------------
  // Optional: Summary hook
  // Call at end of sim
  // -----------------------------
  task report();
    scb.print_summary();
  endtask

endclass