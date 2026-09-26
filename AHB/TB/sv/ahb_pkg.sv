package ahb_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    typedef uvm_config_db#(virtual ahb_if.master) ahb_master_vif_config;
    typedef uvm_config_db#(virtual ahb_if.slave) ahb_slave_vif_config;
    `include "ahb_master_sequence_item.sv"
    `include "ahb_master_sequences.sv"
    `include "ahb_master_sequencer.sv"
    `include "ahb_master_driver.sv"
    `include "ahb_master_monitor.sv"
    `include "ahb_master_agent.sv"

    `include "ahb_slave_sequence_item.sv"
    `include "ahb_slave_sequences.sv"
    `include "ahb_slave_sequencer.sv"
    `include "ahb_slave_driver.sv"
    `include "ahb_slave_monitor.sv"
    `include "ahb_slave_agent.sv"
    `include "ahb_subscriber.sv"
    `include "ahb_scoreboard.sv"
    `include "ahb_env.sv"

endpackage: ahb_pkg