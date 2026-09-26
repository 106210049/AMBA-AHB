//  Class: ahb_master_driver
//
class ahb_master_driver extends uvm_driver #(ahb_master_sequence_item);
    `uvm_component_utils(ahb_master_driver);

    int num_pkg_sent;
    virtual interface ahb_if.master vif;

    //  Group: Functions

    //  Constructor: new
    function new(string name = "ahb_master_driver", uvm_component parent);
        super.new(name, parent);
    endfunction: new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction: build_phase

    virtual function void connect_phase(uvm_phase phase);
        if(!ahb_master_vif_config::get(this, "", "vif", vif))
            `uvm_error(get_type_name(), $sformatf("virtual interface must be set for: %s vif", get_full_name()))
        else 
            `uvm_info(get_type_name(), "Driver is connected with interface", UVM_HIGH)
    endfunction: connect_phase

    function void start_of_simulation_phase(uvm_phase phase);
        `uvm_info(get_type_name(), {"start of simulation for ", get_full_name()}, UVM_HIGH)
    endfunction : start_of_simulation_phase

    task run_phase(uvm_phase phase);
        `uvm_info(get_type_name(),$sformatf("Driver is running"), UVM_LOW);
        fork 
           begin
                @(negedge vif.hreset_n);
                @(posedge vif.hreset_n);
                `uvm_info(get_type_name(), "Detected Reset Done", UVM_MEDIUM)
                forever begin
                    seq_item_port.get_next_item(req);
                    send_packet(req);
                    seq_item_port.item_done();
                end
            end
            reset_signals();
        join
    endtask: run_phase


    virtual task send_packet(ahb_master_sequence_item ahb_master_pkt);
        `uvm_info(get_type_name(), $sformatf("Sending Packet :\n%s", ahb_master_pkt.sprint()), UVM_HIGH)
        fork
            begin
                case(ahb_master_pkt.i_burst_type)
                    SINGLE: begin
                        vif.drive_single_write_trans(ahb_master_pkt.i_burst_type, ahb_master_pkt.i_addr, ahb_master_pkt.i_data, ahb_master_pkt.i_data_size);
                        vif.drive_single_read_trans(ahb_master_pkt.i_burst_type, ahb_master_pkt.i_addr, ahb_master_pkt.i_data_size);
                    end
                    INCR:   begin
                        vif.drive_incr_write_trans(ahb_master_pkt.i_burst_type, ahb_master_pkt.i_addr, ahb_master_pkt.i_data, ahb_master_pkt.i_data_size);
                        vif.drive_incr_read_trans(ahb_master_pkt.i_burst_type, ahb_master_pkt.i_addr, ahb_master_pkt.i_data_size);
                    end
                    INCR4:  begin
                        vif.drive_incr4_write_trans(ahb_master_pkt.i_burst_type, ahb_master_pkt.i_addr, ahb_master_pkt.i_data, ahb_master_pkt.i_data_size);
                        vif.drive_incr4_read_trans(ahb_master_pkt.i_burst_type, ahb_master_pkt.i_addr, ahb_master_pkt.i_data_size);
                    end
                    INCR8: begin
                        vif.drive_incr8_write_trans(ahb_master_pkt.i_burst_type, ahb_master_pkt.i_addr, ahb_master_pkt.i_data, ahb_master_pkt.i_data_size);
                        vif.drive_incr8_read_trans(ahb_master_pkt.i_burst_type, ahb_master_pkt.i_addr, ahb_master_pkt.i_data_size);
                    end
                    INCR16: begin
                        vif.drive_incr16_write_trans(ahb_master_pkt.i_burst_type, ahb_master_pkt.i_addr, ahb_master_pkt.i_data, ahb_master_pkt.i_data_size);
                        vif.drive_incr16_read_trans(ahb_master_pkt.i_burst_type, ahb_master_pkt.i_addr, ahb_master_pkt.i_data_size);
                    end
                    WRAP4: begin
                        vif.drive_wrap4_write_trans(ahb_master_pkt.i_burst_type, ahb_master_pkt.i_addr, ahb_master_pkt.i_data, ahb_master_pkt.i_data_size);
                        vif.drive_wrap4_read_trans(ahb_master_pkt.i_burst_type, ahb_master_pkt.i_addr, ahb_master_pkt.i_data_size);
                    end
                    WRAP8: begin
                        vif.drive_wrap8_write_trans(ahb_master_pkt.i_burst_type, ahb_master_pkt.i_addr, ahb_master_pkt.i_data, ahb_master_pkt.i_data_size);
                        vif.drive_wrap8_read_trans(ahb_master_pkt.i_burst_type, ahb_master_pkt.i_addr, ahb_master_pkt.i_data_size);
                    end
                    WRAP16: begin
                        vif.drive_wrap16_write_trans(ahb_master_pkt.i_burst_type, ahb_master_pkt.i_addr, ahb_master_pkt.i_data, ahb_master_pkt.i_data_size);
                        vif.drive_wrap16_read_trans(ahb_master_pkt.i_burst_type, ahb_master_pkt.i_addr, ahb_master_pkt.i_data_size);
                    end
                    default:    begin
                        vif.drive_single_write_trans(ahb_master_pkt.i_burst_type, ahb_master_pkt.i_addr, ahb_master_pkt.i_data, ahb_master_pkt.i_data_size);
                        vif.drive_single_read_trans(ahb_master_pkt.i_burst_type, ahb_master_pkt.i_addr, ahb_master_pkt.i_data_size);
                    end
                endcase
            end
            @(posedge vif.master_drvstart) void'(begin_tr(req, "Driver_AHB_Master"));
        join
        end_tr(req);
        num_pkg_sent++;
    endtask: send_packet

    task reset_signals();
        vif.master_reset_signals();
    endtask: reset_signals
    
endclass: ahb_master_driver

class ahb_master_driver_wait_state extends ahb_master_driver;
    `uvm_component_utils(ahb_master_driver_wait_state)

    function new(string name = "ahb_master_driver_wait_state", uvm_component parent);
        super.new(name, parent);
    endfunction

    task send_packet(ahb_master_sequence_item ahb_master_pkt);
        `uvm_info(get_type_name(), $sformatf("Sending Packet :\n%s", ahb_master_pkt.sprint()), UVM_HIGH)
         fork
            begin
                case(ahb_master_pkt.i_burst_type)
                    INCR, INCR4, INCR8, INCR16: begin
                        vif.drive_incr_wait_write_trans(ahb_master_pkt.i_burst_type, ahb_master_pkt.i_addr, ahb_master_pkt.i_data, ahb_master_pkt.i_data_size);
                        vif.drive_incr_wait_read_trans(ahb_master_pkt.i_burst_type, ahb_master_pkt.i_addr, ahb_master_pkt.i_data_size);
                    end
                    WRAP4, WRAP8, WRAP16:   begin
                        vif.drive_wrap_wait_write_trans(ahb_master_pkt.i_burst_type, ahb_master_pkt.i_addr, ahb_master_pkt.i_data, ahb_master_pkt.i_data_size);
                        vif.drive_wrap_wait_read_trans(ahb_master_pkt.i_burst_type, ahb_master_pkt.i_addr, ahb_master_pkt.i_data_size);
                    end
                endcase
            end
            @(posedge vif.master_drvstart) void'(begin_tr(req, "Driver_AHB_Master"));
        join
        end_tr(req);
        num_pkg_sent++;
    endtask: send_packet
    
endclass: ahb_master_driver_wait_state