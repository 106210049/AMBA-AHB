//  Class: ahb_env
//
class ahb_env extends uvm_env;
    `uvm_component_utils(ahb_env);

   ahb_master_agent master_agent;
   ahb_slave_agent slave_agent;
   ahb_scoreboard ahb_scb;
   func_cov slave_cov;

    //  Group: Functions

    //  Constructor: new
    function new(string name = "ahb_env", uvm_component parent);
        super.new(name, parent);
    endfunction: new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        master_agent = ahb_master_agent::type_id::create("master_agent", this);
        slave_agent = ahb_slave_agent::type_id::create("slave_agent", this);
        ahb_scb = ahb_scoreboard::type_id::create("ahb_scb", this);
        slave_cov = func_cov::type_id::create("slave_cov", this);
    endfunction: build_phase

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        master_agent.monitor.item_collected_port.connect(ahb_scb.master_imp);
        slave_agent.monitor.item_collected_port.connect(ahb_scb.slave_imp);
        slave_agent.monitor.item_collected_port.connect(slave_cov.analysis_export);
    endfunction: connect_phase

    function void start_of_simulation_phase(uvm_phase phase);
        `uvm_info(get_type_name(), {"start of simulation for ", get_full_name()}, UVM_HIGH)
    endfunction : start_of_simulation_phase
    
endclass: ahb_env
