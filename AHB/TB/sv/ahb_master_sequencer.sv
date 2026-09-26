//  Class: ahb_master_sequencer
//
class ahb_master_sequencer extends uvm_sequencer #(ahb_master_sequence_item);
    `uvm_component_utils(ahb_master_sequencer);

    //  Group: Functions

    //  Constructor: new
    function new(string name = "ahb_master_sequencer", uvm_component parent);
        super.new(name, parent);
    endfunction: new

    function void start_of_simulation_phase(uvm_phase phase);
        super.start_of_simulation_phase(phase);
    endfunction: start_of_simulation_phase
    
endclass: ahb_master_sequencer
