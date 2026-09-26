//  Class: ahb_master_sequences
//
class ahb_master_sequences extends uvm_sequence #(ahb_master_sequence_item);
    `uvm_object_utils(ahb_master_sequences);

    //  Group: Functions

    //  Constructor: new
    function new(string name = "ahb_master_sequences");
        super.new(name);
    endfunction: new

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
    
endclass: ahb_master_sequences

class ahb_master_slv1_sequences extends ahb_master_sequences;
    `uvm_object_utils(ahb_master_slv1_sequences)

    function new(string name = "ahb_master_slv1_sequences");
        super.new(name);
    endfunction: new

    task body();
        `uvm_info(get_type_name(), "Executing ahb_master_slv1_sequences", UVM_LOW)
        `uvm_do_with(req, {req.i_addr == 32'h0000_0000;})
    endtask: body
endclass: ahb_master_slv1_sequences

class ahb_master_slv2_sequences extends ahb_master_sequences;
    `uvm_object_utils(ahb_master_slv2_sequences)

    function new(string name = "ahb_master_slv2_sequences");
        super.new(name);
    endfunction: new

    task body();
        `uvm_info(get_type_name(), "Executing ahb_master_slv2_sequences", UVM_LOW)
        `uvm_do_with(req, {req.i_addr == 32'h0000_0400;})
    endtask: body
endclass: ahb_master_slv2_sequences

class ahb_master_slv3_sequences extends ahb_master_sequences;
    `uvm_object_utils(ahb_master_slv3_sequences)

    function new(string name = "ahb_master_slv3_sequences");
        super.new(name);
    endfunction: new

    task body();
        `uvm_info(get_type_name(), "Executing ahb_master_slv3_sequences", UVM_LOW)
        `uvm_do_with(req, {req.i_addr == 32'h0000_0800;})
    endtask: body
endclass: ahb_master_slv3_sequences

class ahb_master_slv4_sequences extends ahb_master_sequences;
    `uvm_object_utils(ahb_master_slv4_sequences)

    function new(string name = "ahb_master_slv4_sequences");
        super.new(name);
    endfunction: new

    task body();
        `uvm_info(get_type_name(), "Executing ahb_master_slv4_sequences", UVM_LOW)
        `uvm_do_with(req, {req.i_addr == 32'h0000_0C00;})
    endtask: body
endclass: ahb_master_slv4_sequences

class ahb_master_single_sequences extends ahb_master_sequences;
    `uvm_object_utils(ahb_master_single_sequences)

    function new(string name = "ahb_master_single_sequences");
        super.new(name);
    endfunction: new

    task body();
        `uvm_info(get_type_name(), "Executing ahb_master_single_sequences", UVM_LOW)
        // repeat(5)
        `uvm_do_with(req, {req.i_burst_type == SINGLE;})
    endtask: body
endclass: ahb_master_single_sequences

class ahb_master_incr_sequences extends ahb_master_sequences;
    `uvm_object_utils(ahb_master_incr_sequences)

    function new(string name = "ahb_master_incr_sequences");
        super.new(name);
    endfunction: new

    task body();
        `uvm_info(get_type_name(), "Executing ahb_master_incr_sequences", UVM_LOW)
        `uvm_do_with(req, {req.i_burst_type == INCR;})
    endtask: body
endclass: ahb_master_incr_sequences

class ahb_master_incr4_sequences extends ahb_master_sequences;
    `uvm_object_utils(ahb_master_incr4_sequences)

    function new(string name = "ahb_master_incr4_sequences");
        super.new(name);
    endfunction: new

    task body();
        `uvm_info(get_type_name(), "Executing ahb_master_incr4_sequences", UVM_LOW)
        `uvm_do_with(req, {req.i_burst_type == INCR4;})
    endtask: body
endclass: ahb_master_incr4_sequences

class ahb_master_incr8_sequences extends ahb_master_sequences;
    `uvm_object_utils(ahb_master_incr8_sequences)

    function new(string name = "ahb_master_incr8_sequences");
        super.new(name);
    endfunction: new

    task body();
        `uvm_info(get_type_name(), "Executing ahb_master_incr8_sequences", UVM_LOW)
        `uvm_do_with(req, {req.i_burst_type == INCR8;})
    endtask: body
endclass: ahb_master_incr8_sequences

class ahb_master_incr16_sequences extends ahb_master_sequences;
    `uvm_object_utils(ahb_master_incr16_sequences)

    function new(string name = "ahb_master_incr16_sequences");
        super.new(name);
    endfunction: new

    task body();
        `uvm_info(get_type_name(), "Executing ahb_master_incr16_sequences", UVM_LOW)
        `uvm_do_with(req, {req.i_burst_type == INCR16;})
    endtask: body
endclass: ahb_master_incr16_sequences

class ahb_master_wrap4_sequences extends ahb_master_sequences;
    `uvm_object_utils(ahb_master_wrap4_sequences)

    function new(string name = "ahb_master_wrap4_sequences");
        super.new(name);
    endfunction: new

    task body();
        `uvm_info(get_type_name(), "Executing ahb_master_wrap4_sequences", UVM_LOW)
        `uvm_do_with(req, {req.i_burst_type == WRAP4;})
    endtask: body
endclass: ahb_master_wrap4_sequences

class ahb_master_wrap8_sequences extends ahb_master_sequences;
    `uvm_object_utils(ahb_master_wrap8_sequences)

    function new(string name = "ahb_master_wrap8_sequences");
        super.new(name);
    endfunction: new

    task body();
        `uvm_info(get_type_name(), "Executing ahb_master_wrap8_sequences", UVM_LOW)
        `uvm_do_with(req, {req.i_burst_type == WRAP8;})
    endtask: body
endclass: ahb_master_wrap8_sequences

class ahb_master_wrap16_sequences extends ahb_master_sequences;
    `uvm_object_utils(ahb_master_wrap16_sequences)

    function new(string name = "ahb_master_wrap16_sequences");
        super.new(name);
    endfunction: new

    task body();
        `uvm_info(get_type_name(), "Executing ahb_master_wrap16_sequences", UVM_LOW)
        `uvm_do_with(req, {req.i_burst_type == WRAP16;})
    endtask: body
endclass: ahb_master_wrap16_sequences

class ahb_master_hsize_byte_sequences extends ahb_master_sequences;
    `uvm_object_utils(ahb_master_hsize_byte_sequences)

    function new(string name = "ahb_master_hsize_byte_sequences");
        super.new(name);
    endfunction: new

    task body();
        `uvm_info(get_type_name(), "Executing ahb_master_hsize_byte_sequences", UVM_LOW)
        `uvm_do_with(req, {req.i_data_size == HSIZE_BYTE;})
    endtask: body
endclass: ahb_master_hsize_byte_sequences

class ahb_master_hsize_hword_sequences extends ahb_master_sequences;
    `uvm_object_utils(ahb_master_hsize_hword_sequences)

    function new(string name = "ahb_master_hsize_hword_sequences");
        super.new(name);
    endfunction: new

    task body();
        `uvm_info(get_type_name(), "Executing ahb_master_hsize_hword_sequences", UVM_LOW)
        `uvm_do_with(req, {req.i_data_size == HSIZE_HWORD;})
    endtask: body
endclass: ahb_master_hsize_hword_sequences

class ahb_master_hsize_word_sequences extends ahb_master_sequences;
    `uvm_object_utils(ahb_master_hsize_word_sequences)

    function new(string name = "ahb_master_hsize_word_sequences");
        super.new(name);
    endfunction: new

    task body();
        `uvm_info(get_type_name(), "Executing ahb_master_hsize_word_sequences", UVM_LOW)
        `uvm_do_with(req, {req.i_data_size == HSIZE_HWORD;})
    endtask: body
endclass: ahb_master_hsize_word_sequences

class ahb_master_random_sequences extends ahb_master_sequences;
    `uvm_object_utils(ahb_master_random_sequences)

    function new(string name = "ahb_master_random_sequences");
        super.new(name);
    endfunction: new

    task body();
        `uvm_info(get_type_name(), "Executing ahb_master_random_sequences", UVM_LOW)
        `uvm_do(req)
    endtask: body
endclass: ahb_master_random_sequences

class ahb_master_random_30_sequences extends ahb_master_sequences;
    `uvm_object_utils(ahb_master_random_30_sequences)

    function new(string name = "ahb_master_random_30_sequences");
        super.new(name);
    endfunction: new

    task body();
        `uvm_info(get_type_name(), "Executing ahb_master_random_30_sequences", UVM_LOW)
        repeat(30)
            `uvm_do_with(req, {req.i_burst_type != SINGLE;})
    endtask: body
endclass: ahb_master_random_30_sequences

class ahb_master_data_zero_sequences extends ahb_master_sequences;
    `uvm_object_utils(ahb_master_data_zero_sequences)

    function new(string name = "ahb_master_data_zero_sequences");
        super.new(name);
    endfunction: new

    task body();
        `uvm_info(get_type_name(), "Executing ahb_master_data_zero_sequences", UVM_LOW)
        `uvm_do_with(req, {req.i_data == 32'h0000_0000; req.i_burst_type == SINGLE;})
    endtask: body
endclass: ahb_master_data_zero_sequences

class ahb_master_data_full_one_sequences extends ahb_master_sequences;
    `uvm_object_utils(ahb_master_data_full_one_sequences)

    function new(string name = "ahb_master_data_full_one_sequences");
        super.new(name);
    endfunction: new

    task body();
        `uvm_info(get_type_name(), "Executing ahb_master_data_full_one_sequences", UVM_LOW)
        `uvm_do_with(req, {req.i_data == 32'hFFFF_FFFF; req.i_burst_type == SINGLE;})
    endtask: body
endclass: ahb_master_data_full_one_sequences

class ahb_master_high_boundary_address_sequences extends ahb_master_sequences;
    `uvm_object_utils(ahb_master_high_boundary_address_sequences)

    function new(string name = "ahb_master_high_boundary_address_sequences");
        super.new(name);
    endfunction: new

    task body();
        `uvm_info(get_type_name(), "Executing ahb_master_high_boundary_address_sequences", UVM_LOW)
        `uvm_do_with(req, {req.i_addr == 32'h0000_0CFC;})
    endtask: body
endclass: ahb_master_high_boundary_address_sequences

class ahb_master_low_boundary_address_sequences extends ahb_master_sequences;
    `uvm_object_utils(ahb_master_low_boundary_address_sequences)

    function new(string name = "ahb_master_low_boundary_address_sequences");
        super.new(name);
    endfunction: new

    task body();
        `uvm_info(get_type_name(), "Executing ahb_master_low_boundary_address_sequences", UVM_LOW)
        `uvm_do_with(req, {req.i_addr == 32'h0000_0000;})
    endtask: body
endclass: ahb_master_low_boundary_address_sequences

class ahb_master_wait_state_sequences extends ahb_master_sequences;
    `uvm_object_utils(ahb_master_wait_state_sequences)

    function new(string name = "ahb_master_wait_state_sequences");
        super.new(name);
    endfunction: new

    task body();
        `uvm_info(get_type_name(), "Executing ahb_master_wait_state_sequences", UVM_LOW)
        `uvm_do_with(req, {req.i_addr == 32'h0000_0000; req.i_burst_type != SINGLE;})
    endtask: body
endclass: ahb_master_wait_state_sequences