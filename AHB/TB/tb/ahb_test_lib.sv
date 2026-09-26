//  Class: ahb_test_lib
//
class ahb_test_lib extends uvm_test;
    `uvm_component_utils(ahb_test_lib);

    ahb_tb tb;
    //  Group: Functions

    //  Constructor: new
    function new(string name = "ahb_test_lib", uvm_component parent);
        super.new(name, parent);
    endfunction: new

    virtual function void build_phase(uvm_phase phase);
        uvm_config_int::set(this, "tb.env.master_agent", "is_active", UVM_ACTIVE);
        uvm_config_int::set(this, "tb.env.slave_agent", "is_active", UVM_PASSIVE);
        uvm_config_int::set(this, "*", "recording_detail", 1);
        super.build_phase(phase);
        tb = ahb_tb::type_id::create("tb", this);
    endfunction: build_phase

    // function end of elaboration phase
    virtual function void end_of_elaboration_phase(uvm_phase phase);
        // Print the topology of the testbench
        `uvm_info(get_type_name(), $sformatf("End of Elaboration Phase of Test is being executed!"), UVM_HIGH)
        uvm_top.print_topology();
        super.end_of_elaboration_phase(phase);        
    endfunction: end_of_elaboration_phase

    task run_phase(uvm_phase phase);
         // Set drain time to 200ns to allow for any pending transactions to complete before ending     
        uvm_objection obj = phase.get_objection();
        obj.set_drain_time(this, 200ns);
        `uvm_info(get_type_name(), $sformatf("Run Phase of Test is being executed!"), UVM_HIGH)
        super.run_phase(phase);
        phase.raise_objection(this, get_type_name());
        `uvm_info(get_type_name(), $sformatf("Raise objection in run phase"), UVM_HIGH)
        phase.drop_objection(this, get_type_name());
        `uvm_info(get_type_name(), $sformatf("Drop objection in run phase"), UVM_HIGH)
    endtask: run_phase
    
    function void check_phase(uvm_phase phase);
        `uvm_info(get_type_name(),"Check config usage at check phase", UVM_HIGH);
        check_config_usage();
    endfunction: check_phase
    
endclass: ahb_test_lib

class ahb_master_slv1_test extends ahb_test_lib;
    `uvm_component_utils(ahb_master_slv1_test)

    function new(string name = "ahb_master_slv1_test", uvm_component parent);
        super.new(name, parent);
    endfunction: new
    
    function void build_phase(uvm_phase phase);
        uvm_config_wrapper::set(    this,
                                "tb.env.master_agent.sequencer.run_phase", 
                                "default_sequence", 
                                ahb_master_slv1_sequences::get_type()
        );
        super.build_phase(phase);  
    endfunction: build_phase
endclass: ahb_master_slv1_test

class ahb_master_slv2_test extends ahb_test_lib;
    `uvm_component_utils(ahb_master_slv2_test)

    function new(string name = "ahb_master_slv2_test", uvm_component parent);
        super.new(name, parent);
    endfunction: new
    
    function void build_phase(uvm_phase phase);
        uvm_config_wrapper::set(    this,
                                "tb.env.master_agent.sequencer.run_phase", 
                                "default_sequence", 
                                ahb_master_slv2_sequences::get_type()
        );
        super.build_phase(phase);  
    endfunction: build_phase
endclass: ahb_master_slv2_test

class ahb_master_slv3_test extends ahb_test_lib;
    `uvm_component_utils(ahb_master_slv3_test)

    function new(string name = "ahb_master_slv3_test", uvm_component parent);
        super.new(name, parent);
    endfunction: new
    
    function void build_phase(uvm_phase phase);
        uvm_config_wrapper::set(    this,
                                "tb.env.master_agent.sequencer.run_phase", 
                                "default_sequence", 
                                ahb_master_slv3_sequences::get_type()
        );  
        super.build_phase(phase);
    endfunction: build_phase
endclass: ahb_master_slv3_test

class ahb_master_slv4_test extends ahb_test_lib;
    `uvm_component_utils(ahb_master_slv4_test)

    function new(string name = "ahb_master_slv4_test", uvm_component parent);
        super.new(name, parent);
    endfunction: new
    
    function void build_phase(uvm_phase phase);
        uvm_config_wrapper::set(    this,
                                "tb.env.master_agent.sequencer.run_phase", 
                                "default_sequence", 
                                ahb_master_slv4_sequences::get_type()
        );  
        super.build_phase(phase);
    endfunction: build_phase
endclass: ahb_master_slv4_test

class ahb_master_single_test extends ahb_test_lib;
    `uvm_component_utils(ahb_master_single_test)

    function new(string name = "ahb_master_single_test", uvm_component parent);
        super.new(name, parent);
    endfunction: new
    
    function void build_phase(uvm_phase phase);
        uvm_config_wrapper::set(    this,
                                "tb.env.master_agent.sequencer.run_phase", 
                                "default_sequence", 
                                ahb_master_single_sequences::get_type()
        );  
        super.build_phase(phase);
    endfunction: build_phase
endclass: ahb_master_single_test

class ahb_master_incr_test extends ahb_test_lib;
    `uvm_component_utils(ahb_master_incr_test)

    function new(string name = "ahb_master_incr_test", uvm_component parent);
        super.new(name, parent);
    endfunction: new
    
    function void build_phase(uvm_phase phase);
        uvm_config_wrapper::set(    this,
                                "tb.env.master_agent.sequencer.run_phase", 
                                "default_sequence", 
                                ahb_master_incr_sequences::get_type()
        );  
        super.build_phase(phase);
    endfunction: build_phase
endclass: ahb_master_incr_test

class ahb_master_incr4_test extends ahb_test_lib;
    `uvm_component_utils(ahb_master_incr4_test)

    function new(string name = "ahb_master_incr4_test", uvm_component parent);
        super.new(name, parent);
    endfunction: new
    
    function void build_phase(uvm_phase phase);
        uvm_config_wrapper::set(    this,
                                "tb.env.master_agent.sequencer.run_phase", 
                                "default_sequence", 
                                ahb_master_incr4_sequences::get_type()
        );  
        super.build_phase(phase);
    endfunction: build_phase
endclass: ahb_master_incr4_test

class ahb_master_incr8_test extends ahb_test_lib;
    `uvm_component_utils(ahb_master_incr8_test)

    function new(string name = "ahb_master_incr8_test", uvm_component parent);
        super.new(name, parent);
    endfunction: new
    
    function void build_phase(uvm_phase phase);
        uvm_config_wrapper::set(    this,
                                "tb.env.master_agent.sequencer.run_phase", 
                                "default_sequence", 
                                ahb_master_incr8_sequences::get_type()
        );  
        super.build_phase(phase);
    endfunction: build_phase
endclass: ahb_master_incr8_test

class ahb_master_incr16_test extends ahb_test_lib;
    `uvm_component_utils(ahb_master_incr16_test)

    function new(string name = "ahb_master_incr16_test", uvm_component parent);
        super.new(name, parent);
    endfunction: new
    
    function void build_phase(uvm_phase phase);
        uvm_config_wrapper::set(    this,
                                "tb.env.master_agent.sequencer.run_phase", 
                                "default_sequence", 
                                ahb_master_incr16_sequences::get_type()
        );  
        super.build_phase(phase);
    endfunction: build_phase
endclass: ahb_master_incr16_test

class ahb_master_wrap4_test extends ahb_test_lib;
    `uvm_component_utils(ahb_master_wrap4_test)

    function new(string name = "ahb_master_wrap4_test", uvm_component parent);
        super.new(name, parent);
    endfunction: new
    
    function void build_phase(uvm_phase phase);
        uvm_config_wrapper::set(    this,
                                "tb.env.master_agent.sequencer.run_phase", 
                                "default_sequence", 
                                ahb_master_wrap4_sequences::get_type()
        );  
        super.build_phase(phase);
    endfunction: build_phase
endclass: ahb_master_wrap4_test

class ahb_master_wrap8_test extends ahb_test_lib;
    `uvm_component_utils(ahb_master_wrap8_test)

    function new(string name = "ahb_master_wrap8_test", uvm_component parent);
        super.new(name, parent);
    endfunction: new
    
    function void build_phase(uvm_phase phase);
        uvm_config_wrapper::set(    this,
                                "tb.env.master_agent.sequencer.run_phase", 
                                "default_sequence", 
                                ahb_master_wrap8_sequences::get_type()
        );  
        super.build_phase(phase);
    endfunction: build_phase
endclass: ahb_master_wrap8_test

class ahb_master_wrap16_test extends ahb_test_lib;
    `uvm_component_utils(ahb_master_wrap16_test)

    function new(string name = "ahb_master_wrap16_test", uvm_component parent);
        super.new(name, parent);
    endfunction: new
    
    function void build_phase(uvm_phase phase);
        uvm_config_wrapper::set(    this,
                                "tb.env.master_agent.sequencer.run_phase", 
                                "default_sequence", 
                                ahb_master_wrap16_sequences::get_type()
        );  
        super.build_phase(phase);
    endfunction: build_phase
endclass: ahb_master_wrap16_test

class ahb_master_hsize_byte_test extends ahb_test_lib;
    `uvm_component_utils(ahb_master_hsize_byte_test)

    function new(string name = "ahb_master_hsize_byte_test", uvm_component parent);
        super.new(name, parent);
    endfunction: new
    
    function void build_phase(uvm_phase phase);
        uvm_config_wrapper::set(    this,
                                "tb.env.master_agent.sequencer.run_phase", 
                                "default_sequence", 
                                ahb_master_hsize_byte_sequences::get_type()
        );  
        super.build_phase(phase);
    endfunction: build_phase
endclass: ahb_master_hsize_byte_test

class ahb_master_hsize_hword_test extends ahb_test_lib;
    `uvm_component_utils(ahb_master_hsize_hword_test)

    function new(string name = "ahb_master_hsize_hword_test", uvm_component parent);
        super.new(name, parent);
    endfunction: new
    
    function void build_phase(uvm_phase phase);
        uvm_config_wrapper::set(    this,
                                "tb.env.master_agent.sequencer.run_phase", 
                                "default_sequence", 
                                ahb_master_hsize_hword_sequences::get_type()
        );  
        super.build_phase(phase);
    endfunction: build_phase
endclass: ahb_master_hsize_hword_test

class ahb_master_hsize_word_test extends ahb_test_lib;
    `uvm_component_utils(ahb_master_hsize_word_test)

    function new(string name = "ahb_master_hsize_word_test", uvm_component parent);
        super.new(name, parent);
    endfunction: new
    
    function void build_phase(uvm_phase phase);
        uvm_config_wrapper::set(    this,
                                "tb.env.master_agent.sequencer.run_phase", 
                                "default_sequence", 
                                ahb_master_hsize_word_sequences::get_type()
        );  
        super.build_phase(phase);
    endfunction: build_phase
endclass: ahb_master_hsize_word_test

class ahb_master_random_test extends ahb_test_lib;
    `uvm_component_utils(ahb_master_random_test)

    function new(string name = "ahb_master_random_test", uvm_component parent);
        super.new(name, parent);
    endfunction: new
    
    function void build_phase(uvm_phase phase);
        uvm_config_wrapper::set(    this,
                                "tb.env.master_agent.sequencer.run_phase", 
                                "default_sequence", 
                                ahb_master_random_sequences::get_type()
        );  
        super.build_phase(phase);
    endfunction: build_phase
endclass: ahb_master_random_test

class ahb_master_random_30_test extends ahb_test_lib;
    `uvm_component_utils(ahb_master_random_30_test)

    function new(string name = "ahb_master_random_30_test", uvm_component parent);
        super.new(name, parent);
    endfunction: new
    
    function void build_phase(uvm_phase phase);
        uvm_config_wrapper::set(    this,
                                "tb.env.master_agent.sequencer.run_phase", 
                                "default_sequence", 
                                ahb_master_random_30_sequences::get_type()
        );  
        super.build_phase(phase);
    endfunction: build_phase
endclass: ahb_master_random_30_test

class ahb_master_data_zero_test extends ahb_test_lib;
    `uvm_component_utils(ahb_master_data_zero_test)

    function new(string name = "ahb_master_data_zero_test", uvm_component parent);
        super.new(name, parent);
    endfunction: new
    
    function void build_phase(uvm_phase phase);
        uvm_config_wrapper::set(    this,
                                "tb.env.master_agent.sequencer.run_phase", 
                                "default_sequence", 
                                ahb_master_data_zero_sequences::get_type()
        );  
        super.build_phase(phase);
    endfunction: build_phase
endclass: ahb_master_data_zero_test

class ahb_master_data_full_one_test extends ahb_test_lib;
    `uvm_component_utils(ahb_master_data_full_one_test)

    function new(string name = "ahb_master_data_full_one_test", uvm_component parent);
        super.new(name, parent);
    endfunction: new
    
    function void build_phase(uvm_phase phase);
        uvm_config_wrapper::set(    this,
                                "tb.env.master_agent.sequencer.run_phase", 
                                "default_sequence", 
                                ahb_master_data_full_one_sequences::get_type()
        );  
        super.build_phase(phase);
    endfunction: build_phase
endclass: ahb_master_data_full_one_test

class ahb_master_high_boundary_address_test extends ahb_test_lib;
    `uvm_component_utils(ahb_master_high_boundary_address_test)

    function new(string name = "ahb_master_high_boundary_address_test", uvm_component parent);
        super.new(name, parent);
    endfunction: new
    
    function void build_phase(uvm_phase phase);
        uvm_config_wrapper::set(    this,
                                "tb.env.master_agent.sequencer.run_phase", 
                                "default_sequence", 
                                ahb_master_high_boundary_address_sequences::get_type()
        );  
        super.build_phase(phase);
    endfunction: build_phase
endclass: ahb_master_high_boundary_address_test

class ahb_master_low_boundary_address_test extends ahb_test_lib;
    `uvm_component_utils(ahb_master_low_boundary_address_test)

    function new(string name = "ahb_master_low_boundary_address_test", uvm_component parent);
        super.new(name, parent);
    endfunction: new
    
    function void build_phase(uvm_phase phase);
        uvm_config_wrapper::set(    this,
                                "tb.env.master_agent.sequencer.run_phase", 
                                "default_sequence", 
                                ahb_master_low_boundary_address_sequences::get_type()
        );  
        super.build_phase(phase);
    endfunction: build_phase
endclass: ahb_master_low_boundary_address_test

class ahb_master_driver_wait_state_test extends ahb_test_lib;
    `uvm_component_utils(ahb_master_driver_wait_state_test)

    function new(string name = "ahb_master_driver_wait_state_test", uvm_component parent);
        super.new(name, parent);
    endfunction: new
    
    function void build_phase(uvm_phase phase);
        set_type_override_by_type(ahb_master_driver::get_type(), ahb_master_driver_wait_state::get_type());
        uvm_config_wrapper::set(    this,
                                "tb.env.master_agent.sequencer.run_phase", 
                                "default_sequence", 
                                ahb_master_wait_state_sequences::get_type()
        );  
        super.build_phase(phase);
    endfunction: build_phase
endclass: ahb_master_driver_wait_state_test