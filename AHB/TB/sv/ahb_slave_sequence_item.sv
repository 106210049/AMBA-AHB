//  Class: ahb_slave_sequence_item
//
import ahb_define_pkg::*;
import ahb_slave_pkg::*;
class ahb_slave_sequence_item extends uvm_sequence_item;
    localparam int ADDR_WIDTH = 32;
    localparam int DATA_WIDTH = 32;
    //  Group: Variables
    rand bit [ADDR_WIDTH-1:0]   haddr;
    rand bit                    hwrite;
    rand hsize_t                hsize;
    rand burst_t                hburst;
    rand htrans_t               htrans;
    rand bit                    hmastlock;
    rand bit [3:0]              hprot;
    rand bit                    hsel;

    
    // Write Data
    rand bit [DATA_WIDTH-1:0]   hwdata;

   
    // Output of Slave (Input of Master)
    logic [DATA_WIDTH-1:0]   hrdata;
    logic                    hready;
    logic                    hresp;

    `uvm_object_utils_begin(ahb_slave_sequence_item)
        `uvm_field_int(haddr, UVM_ALL_ON)
        `uvm_field_int(hwrite, UVM_ALL_ON)
        `uvm_field_enum(burst_t, hburst, UVM_ALL_ON)
        `uvm_field_enum(hsize_t, hsize, UVM_ALL_ON)
        `uvm_field_enum(htrans_t, htrans, UVM_ALL_ON)
        `uvm_field_int(hwdata, UVM_ALL_ON)
        `uvm_field_int(hrdata, UVM_ALL_ON)
        `uvm_field_int(hready, UVM_ALL_ON)
        `uvm_field_int(hresp, UVM_ALL_ON)
    `uvm_object_utils_end

    //  Group: Constraints
    constraint c_solve_order { solve hsize before haddr; }
    // (1) Limit transfer size by DATA_WIDTH to avoid illegal sizes
    constraint c_hsize_by_datawidth {
        if (DATA_WIDTH <= 8)       { hsize inside {HSIZE_BYTE}; } 
        else if (DATA_WIDTH <= 16) { hsize inside {HSIZE_BYTE, HSIZE_HWORD}; } 
        else if (DATA_WIDTH <= 32) { hsize inside {HSIZE_BYTE, HSIZE_HWORD, HSIZE_WORD}; } 
        else if (DATA_WIDTH <= 64) { hsize inside {HSIZE_BYTE, HSIZE_HWORD, HSIZE_WORD, HSIZE_DWORD}; } 
        else                       { hsize inside {HSIZE_BYTE, HSIZE_HWORD, HSIZE_WORD, HSIZE_DWORD, HSIZE_128BIT}; }
    }
    constraint c_valid_addr {
        haddr inside {[32'h0:32'h0000_0CFF]};
    }

    constraint c_haddr_alignment {
        (longint'(haddr) % hsize2bytes(hsize)) == 0;
    }

    constraint c_burst {
        hburst inside {SINGLE, INCR, INCR4, INCR8, INCR16, WRAP4, WRAP8, WRAP16};
    }

    //  Group: Functions

    //  Constructor: new
    function new(string name = "ahb_slave_sequence_item");
        super.new(name);
    endfunction: new

    
    
endclass: ahb_slave_sequence_item


/*----------------------------------------------------------------------------*/
/*  Constraints                                                               */
/*----------------------------------------------------------------------------*/




/*----------------------------------------------------------------------------*/
/*  Functions                                                                 */
/*----------------------------------------------------------------------------*/

