//  Class: ahb_tb
//
class ahb_tb extends uvm_env;
    `uvm_component_utils(ahb_tb);

    ahb_env env;

    //  Group: Functions

    //  Constructor: new
    function new(string name = "ahb_tb", uvm_component parent);
        super.new(name, parent);
    endfunction: new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = ahb_env::type_id::create("env", this);
        `uvm_info(get_type_name(), $sformatf("Testbench Build Phase is being executed !"), UVM_HIGH)
    endfunction: build_phase

    function void start_of_simulation_phase(uvm_phase phase);
        `uvm_info(get_type_name(), {"start of simulation for ", get_full_name()}, UVM_HIGH)
    endfunction : start_of_simulation_phase
    
    task run_phase(uvm_phase phase);
        `uvm_info(get_type_name(), $sformatf("Testbench Run Phase is begin executed!"), UVM_LOW) 
    endtask: run_phase

endclass: ahb_tb
