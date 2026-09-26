//  Class: ahb_master_monitor
//
class ahb_master_monitor extends uvm_monitor;
    `uvm_component_utils(ahb_master_monitor);

    ahb_master_sequence_item ahb_master_pkt;
    int num_pkt_col;
    uvm_analysis_port #(ahb_master_sequence_item) item_collected_port;
    virtual interface ahb_if.master vif;
    //  Group: Functions

    //  Constructor: new
    function new(string name = "ahb_master_monitor", uvm_component parent);
        super.new(name, parent);
        item_collected_port = new("item_collected_port", this);
    endfunction: new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction: build_phase

    function void connect_phase(uvm_phase phase);
        if(!ahb_master_vif_config::get(this, "", "vif", vif))
            `uvm_error(get_type_name(), $sformatf("virtual interface must be set for: %s vif", get_full_name()))
        else 
            `uvm_info(get_type_name(), "Driver is connected with interface", UVM_HIGH)
    endfunction: connect_phase

    function void start_of_simulation_phase(uvm_phase phase);
        `uvm_info(get_type_name(), {"start of simulation for ", get_full_name()}, UVM_HIGH)
    endfunction : start_of_simulation_phase


    task run_phase(uvm_phase phase);
        @(negedge vif.hreset_n);
        @(posedge vif.hreset_n);
        `uvm_info(get_type_name(), "Detected Reset Done", UVM_MEDIUM)

        forever begin
            ahb_master_pkt = ahb_master_sequence_item::type_id::create("ahb_master_sequence_item", this);

           fork
                // if(vif.i_burst_type == SINGLE)  begin
                //     `uvm_info(get_type_name(), {"Sample with Single ", get_full_name()}, UVM_HIGH)
                //     vif.ahb_master_single_collector(ahb_master_pkt.i_write, 
                //                             ahb_master_pkt.i_burst_type, 
                //                             ahb_master_pkt.i_data_size, 
                //                             ahb_master_pkt.haddr, 
                //                             ahb_master_pkt.i_data);
                // end
                // else    begin
                //     `uvm_info(get_type_name(), {"Sample with Burst ", get_full_name()}, UVM_HIGH)
                //     vif.ahb_master_burst_collector(ahb_master_pkt.i_write, 
                //                                 ahb_master_pkt.i_burst_type, 
                //                                 ahb_master_pkt.i_data_size, 
                //                                 ahb_master_pkt.haddr, 
                //                                 ahb_master_pkt.i_data);
                // end
                // `uvm_info(get_type_name(),
                //     $sformatf("Master Monitor will sample with burst type = %s", vif.i_burst_type.name()),
                //     UVM_HIGH)
                vif.ahb_master_burst_collector(ahb_master_pkt.i_write, 
                                                ahb_master_pkt.i_burst_type, 
                                                ahb_master_pkt.i_data_size, 
                                                ahb_master_pkt.haddr, 
                                                ahb_master_pkt.i_data);
                // begin
                //     @(posedge vif.master_monstart)
                //     void'(begin_tr(ahb_master_pkt, "Monitor_AHB_Master"));    
                // end
            join
            // end_tr(ahb_master_pkt);
            item_collected_port.write(ahb_master_pkt);
            `uvm_info(get_type_name(), $sformatf("Packet Collected :\n%s", ahb_master_pkt.sprint()), UVM_LOW)
            num_pkt_col++;
        end
    endtask: run_phase

    function void report_phase(uvm_phase phase);
        `uvm_info(get_type_name(),
            $sformatf("Report: AHB Master Monitor observed %0d transactions", num_pkt_col),
            UVM_LOW)
        if(num_pkt_col == 0)
            `uvm_error(get_type_name(), "No packets observed")
    endfunction

endclass: ahb_master_monitor
