//  Class: ahb_sequence_item
//
import ahb_define_pkg::*;
import ahb_master_pkg::*;
class ahb_master_sequence_item extends uvm_sequence_item;

    localparam int ADDR_WIDTH = 32;
    localparam int DATA_WIDTH = 32;
    //  Group: Variables
    rand bit [ADDR_WIDTH-1:0]   i_addr;
    rand bit [DATA_WIDTH-1:0]   i_data;
    rand burst_t                i_burst_type;
    rand hsize_t                i_data_size;

    logic                       i_enb;
    logic                       i_write;
    logic                       i_wrap_en;
    logic                       i_busy;
    logic     [ADDR_WIDTH-1:0]  haddr;
    // logic                       i_wait_1;
    // logic                       i_wait_2;
    // logic                       i_wait_3;
    // logic                       i_wait_4;

    // logic                       o_hrdata;

    `uvm_object_utils_begin(ahb_master_sequence_item)
        `uvm_field_int(i_addr, UVM_ALL_ON)
        `uvm_field_int(i_data, UVM_ALL_ON)
        `uvm_field_enum(burst_t, i_burst_type, UVM_ALL_ON)
        `uvm_field_enum(hsize_t, i_data_size, UVM_ALL_ON)
        `uvm_field_int(haddr,  UVM_ALL_ON)
        `uvm_field_int(i_write, UVM_ALL_ON)
        `uvm_field_int(i_wrap_en, UVM_ALL_ON)
        `uvm_field_int(i_busy, UVM_ALL_ON)
        // `uvm_field_int(i_wait_1, UVM_ALL_ON)
        // `uvm_field_int(i_wait_2, UVM_ALL_ON)
        // `uvm_field_int(i_wait_3, UVM_ALL_ON)
        // `uvm_field_int(i_wait_4, UVM_ALL_ON)
    `uvm_object_utils_end

    //  Group: Functions

    //  Constructor: new
    function new(string name = "ahb_master_sequence_item");
        super.new(name);
    endfunction: new

    /*----------------------------------------------------------------------------*/
    /*  Constraints                                                               */
    /*----------------------------------------------------------------------------*/

    constraint c_solve_order { solve i_data_size before i_addr; }
    // (1) Limit transfer size by DATA_WIDTH to avoid illegal sizes
    constraint c_hsize_by_datawidth {
        if (DATA_WIDTH <= 8)       { i_data_size inside {HSIZE_BYTE}; } 
        else if (DATA_WIDTH <= 16) { i_data_size inside {HSIZE_BYTE, HSIZE_HWORD}; } 
        else if (DATA_WIDTH <= 32) { i_data_size inside {HSIZE_BYTE, HSIZE_HWORD, HSIZE_WORD}; } 
        else if (DATA_WIDTH <= 64) { i_data_size inside {HSIZE_BYTE, HSIZE_HWORD, HSIZE_WORD, HSIZE_DWORD}; } 
        else                       { i_data_size inside {HSIZE_BYTE, HSIZE_HWORD, HSIZE_WORD, HSIZE_DWORD, HSIZE_128BIT}; }
    }

    constraint c_valid_addr {
        i_addr inside {[32'h0:32'h0000_0CFF]};
    }
    
    // (2) Address alignment to transfer size (AHB rule)
    // E.g., HWORD -> addr % 2 == 0; WORD -> addr % 4 == 0.
    constraint c_haddr_alignment {
        (longint'(i_addr) % hsize2bytes(i_data_size)) == 0;
    }

    constraint c_burst {
        i_burst_type inside {SINGLE, INCR, INCR4, INCR8, INCR16, WRAP4, WRAP8, WRAP16};
    }

    
endclass: ahb_master_sequence_item
