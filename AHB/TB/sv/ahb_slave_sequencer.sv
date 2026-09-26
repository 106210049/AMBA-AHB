//  Class: ahb_slave_sequencer
//
class ahb_slave_sequencer extends uvm_sequencer #(ahb_slave_sequence_item);
    `uvm_component_utils(ahb_slave_sequencer);


    //  Group: Functions

    //  Constructor: new
    function new(string name = "ahb_slave_sequencer", uvm_component parent);
        super.new(name, parent);
    endfunction: new

    function void start_of_simulation_phase(uvm_phase phase);
        super.start_of_simulation_phase(phase);
    endfunction: start_of_simulation_phase

    
endclass: ahb_slave_sequencer
