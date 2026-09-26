//  Class: ahb_slave_sequences
//
class ahb_slave_sequences extends uvm_sequence #(ahb_slave_sequence_item);
    `uvm_object_utils(ahb_slave_sequences);


    //  Group: Functions

    //  Constructor: new
    function new(string name = "ahb_slave_sequences");
        super.new(name);
    endfunction: new

    //  Task: pre_start
    //  This task is a user-definable callback that is called before the optional 
    //  execution of <pre_body>.
    // extern virtual task pre_start();

    //  Task: pre_body
    //  This task is a user-definable callback that is called before the execution 
    //  of <body> ~only~ when the sequence is started with <start>.
    //  If <start> is called with ~call_pre_post~ set to 0, ~pre_body~ is not called.
    // extern virtual task pre_body();
    task pre_body();
        uvm_phase phase;
        `ifdef UVM_VERSION_1_2
            phase = get_starting_phase();
        `else 
            phase = starting_phase;
        `endif
        if(phase != null) begin
            // Raise objection to prevent the run_phase from ending before the sequence is complete
            phase.raise_objection(this, get_type_name());
            `uvm_info(get_type_name(), "raise objection", UVM_MEDIUM)
        end
    endtask: pre_body

    //  Task: post_body
    //  This task is a user-definable callback task that is called after the execution 
    //  of <body> ~only~ when the sequence is started with <start>.
    //  If <start> is called with ~call_pre_post~ set to 0, ~post_body~ is not called.
    // extern virtual task post_body();
    task post_body();
        uvm_phase phase;
        `ifdef UVM_VERSION_1_2
            phase = get_starting_phase();
        `else 
            phase = starting_phase;
        `endif
        if(phase != null) begin
            // Raise objection to prevent the run_phase from ending before the sequence is complete
            phase.drop_objection(this, get_type_name());
            `uvm_info(get_type_name(), "drop objection", UVM_MEDIUM)
        end
    endtask: post_body
    
endclass: ahb_slave_sequences

class ahb_slave_single_sequences extends ahb_slave_sequences;
    `uvm_object_utils(ahb_slave_single_sequences)

    function new(string name = "ahb_slave_single_sequences");
        super.new(name);
    endfunction: new

    task body();
        `uvm_info(get_type_name(), "Executing ahb_slave_single_sequences", UVM_LOW)
        `uvm_do_with(req, {req.hburst == SINGLE;})
    endtask: body
endclass: ahb_slave_single_sequences

class ahb_slave_incr_sequences extends ahb_slave_sequences;
    `uvm_object_utils(ahb_slave_incr_sequences)

    function new(string name = "ahb_slave_incr_sequences");
        super.new(name);
    endfunction: new

    task body();
        `uvm_info(get_type_name(), "Executing ahb_slave_incr_sequences", UVM_LOW)
        `uvm_do_with(req, {req.hburst == INCR;})
    endtask: body
endclass: ahb_slave_incr_sequences

class ahb_slave_incr4_sequences extends ahb_slave_sequences;
    `uvm_object_utils(ahb_slave_incr4_sequences)

    function new(string name = "ahb_slave_incr4_sequences");
        super.new(name);
    endfunction: new

    task body();
        `uvm_info(get_type_name(), "Executing ahb_slave_incr4_sequences", UVM_LOW)
        `uvm_do_with(req, {req.hburst == INCR4;})
    endtask: body
endclass: ahb_slave_incr4_sequences