//  Class: ahb_slave_driver
//
class ahb_slave_driver extends uvm_driver #(ahb_slave_sequence_item);
    `uvm_component_utils(ahb_slave_driver);

    int num_pkg_sent;
    virtual interface ahb_if.slave vif;

    //  Group: Functions

    //  Constructor: new
    function new(string name = "ahb_slave_driver", uvm_component parent);
        super.new(name, parent);
    endfunction: new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction: build_phase

    function void connect_phase(uvm_phase phase);
        if(!ahb_slave_vif_config::get(this, "", "vif", vif))
            `uvm_error(get_type_name(), $sformatf("virtual interface must be set for: %s vif", get_full_name()))
        else 
            `uvm_info(get_type_name(), "Driver is connected with interface", UVM_HIGH)
    endfunction: connect_phase

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

    task send_packet(ahb_slave_sequence_item ahb_slave_pkt);
        `uvm_info(get_type_name(), $sformatf("Sending Packet :\n%s", ahb_slave_pkt.sprint()), UVM_HIGH)
        fork
            // begin
            //     case(ahb_slave_pkt.hburst)
            //         SINGLE: begin
            //             vif.drv_slv_single();
            //         end
            //         INCR:   begin
            //             vif.drv_slv_incr();
            //         end
            //         INCR4:  begin
            //             vif.drv_slv_incr4();
            //         end
            //         INCR8: begin
            //             vif.drv_slv_incr8();
            //         end
            //         INCR16: begin
            //             vif.drv_slv_incr16();
            //         end
            //         default:    begin
                        
            //         end
            //     endcase
            // end
            // @(posedge vif.slave_drvstart) void'(begin_tr(req, "Driver_AHB_Slave"));
        join
        // end_tr(req);
        num_pkg_sent++;
    endtask: send_packet

    task reset_signals();
        vif.slave_reset_signals();
    endtask: reset_signals
endclass: ahb_slave_driver
