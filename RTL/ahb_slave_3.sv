import ahb_slave_pkg::*;
import ahb_pkg::*;
module ahb_slave_3 #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter MEM_DEPTH  = 256,
    parameter logic [ADDR_WIDTH-1:0] BASE_ADDR = 32'h0000_0800
)(
    ahb_if.slave ahb,
    input logic i_wait
);

    // State register declaration 
    state_t current_state, next_state;
    
    // Address-phase latch registers
    logic [ADDR_WIDTH-1:0]  addr_lat   ;
    logic                   hwrite_lat ;
    logic [2:0]             hsize_lat  ;
    logic [2:0]             hburst_lat ;
    logic [1:0]             htrans_lat ;

    // Memory
    logic [DATA_WIDTH-1:0]  mem [0:MEM_DEPTH-1];

    // Active transfer: NONSEQ or SEQ, slave selected
    logic active_transfer;
    logic write_en;
    logic ahb_read;
    assign active_transfer = ahb.hsel & (ahb.htrans == ahb_pkg::NONSEQ || ahb.htrans == ahb_pkg::SEQ);

    // -------------------------------------------------------------------------
    // State register
    // -------------------------------------------------------------------------
    always_ff @(posedge ahb.hclk or negedge ahb.hreset_n) begin : state_reg
        if (!ahb.hreset_n)
            current_state <= ahb_slave_pkg::IDLE;
        else
            current_state <= next_state;
    end

    // -------------------------------------------------------------------------
    // Address-phase latch
    // Latch on every active transfer when hready=1 (bus is free to advance)
    // -------------------------------------------------------------------------
    always_ff @(posedge ahb.hclk or negedge ahb.hreset_n) begin : addr_latch
        if (!ahb.hreset_n) begin
            addr_lat   <= '0                    ;
            hwrite_lat <= 1'b0                  ;
            hsize_lat  <= ahb_pkg::HSIZE_BYTE   ;
            hburst_lat <= ahb_pkg::SINGLE       ;
            htrans_lat <= ahb_pkg::IDLE         ;
        end
        else if (active_transfer && ahb.hready) begin
            addr_lat   <= (ahb.haddr - BASE_ADDR);
            hwrite_lat <= ahb.hwrite ;
            hsize_lat  <= ahb.hsize  ;
            hburst_lat <= ahb.hburst ;
            htrans_lat <= ahb.htrans ;
        end
    end

    // -------------------------------------------------------------------------
    // Next-state logic
    // -------------------------------------------------------------------------
    always_comb begin
        case(current_state)
            ahb_slave_pkg::IDLE:    begin
                if(ahb.hwrite & active_transfer)  
                    next_state = i_wait ? ahb_slave_pkg::WR_WAIT_PHASE : ahb_slave_pkg::WR_READY_PHASE        ;
                else if(!ahb.hwrite & active_transfer)
                    next_state = i_wait ? ahb_slave_pkg::RD_WAIT_PHASE : ahb_slave_pkg::RD_READY_PHASE        ;
                else
                    next_state = ahb_slave_pkg::IDLE                                                          ;
            end

            ahb_slave_pkg::WR_READY_PHASE: begin
                if (ahb.htrans == ahb_pkg::BUSY )
                    next_state = ahb_slave_pkg::WR_WAIT_PHASE ;
                else if (active_transfer && ahb.hwrite)
                    next_state = i_wait ? ahb_slave_pkg::WR_WAIT_PHASE : ahb_slave_pkg::WR_READY_PHASE       ;   // back-to-back write
                else if (active_transfer && !ahb.hwrite)
                    next_state = i_wait ? ahb_slave_pkg::RD_WAIT_PHASE  : ahb_slave_pkg::RD_READY_PHASE      ;    // write → read switch
                else 
                    next_state = ahb_slave_pkg::IDLE                                                         ;
            end

            ahb_slave_pkg::WR_WAIT_PHASE: begin
                if (i_wait || ahb.htrans == ahb_pkg::BUSY)
                    next_state = ahb_slave_pkg::WR_WAIT_PHASE;
                else
                    next_state = ahb_slave_pkg::WR_READY_PHASE;
            end

            ahb_slave_pkg::RD_READY_PHASE:  begin
                if (ahb.htrans == ahb_pkg::BUSY )
                    next_state = ahb_slave_pkg::RD_WAIT_PHASE ;
                else if (active_transfer && !ahb.hwrite)
                    next_state = i_wait ? ahb_slave_pkg::RD_WAIT_PHASE  : ahb_slave_pkg::RD_READY_PHASE;    // back-to-back read
                else if (active_transfer && ahb.hwrite)
                    next_state = i_wait ? ahb_slave_pkg::WR_WAIT_PHASE  : ahb_slave_pkg::WR_READY_PHASE;   // read → write switch
                else
                    next_state = ahb_slave_pkg::IDLE;
            end

            ahb_slave_pkg::RD_WAIT_PHASE:   begin
                if (i_wait || ahb.htrans == ahb_pkg::BUSY)
                    next_state = ahb_slave_pkg::RD_WAIT_PHASE;
                else
                    next_state = ahb_slave_pkg::RD_READY_PHASE;
            end

            default:
                next_state = ahb_slave_pkg::IDLE;
            
        endcase
    end

    // Memory write (data phase)
    // Uses addr_lat — address captured in the PREVIOUS cycle's address phase
    
    always_ff @(posedge ahb.hclk or negedge ahb.hreset_n) begin : mem_write
        if (!ahb.hreset_n) begin
            for (int k = 0; k < MEM_DEPTH; k++)
                mem[k] <= '0;
        end
        else if (active_transfer && write_en && hwrite_lat && ahb.hready) begin
            case (hsize_lat)
                HSIZE_BYTE: begin
                    `ifdef BIG_EDIAN
                        mem[addr_lat >> 2][ (3-addr_lat[1:0])*8 +: 8 ] <= ahb.hwdata[7:0];
                    `else // LITTLE ENDIAN
                        mem[addr_lat >> 2][ (addr_lat[1:0]*8) +: 8 ]   <= ahb.hwdata[7:0];
                    `endif
                end

                HSIZE_HWORD: begin
                    `ifdef BIG_EDIAN
                        mem[addr_lat >> 2][ (1-addr_lat[1])*16 +: 16 ] <= ahb.hwdata[15:0];
                    `else // LITTLE ENDIAN
                        mem[addr_lat >> 2][ (addr_lat[1]*16) +: 16 ]   <= ahb.hwdata[15:0];
                    `endif
                end

                HSIZE_WORD: begin
                    mem[addr_lat >> 2] <= ahb.hwdata;
                end
            endcase
        end
    end

    // Output logic
    always_comb begin : output_logic

        ahb.hready = 1'b1;
        ahb.hresp  = 1'b0;
        // ahb.hrdata = '0  ;
        ahb_read   = 1'b0;
        case (current_state)

            ahb_slave_pkg::IDLE: begin
                ahb.hready = 1'b1;
                ahb.hresp  = 1'b0;
                // ahb.hrdata = '0;
                write_en   = 1'b0;
                ahb_read   = 1'b0;
            end

            ahb_slave_pkg::WR_READY_PHASE: begin
                ahb.hready = 1'b1;
                ahb.hresp  = 1'b0;
                // ahb.hrdata = '0;
                write_en   = 1'b1;
                ahb_read   = 1'b0;
            end

            ahb_slave_pkg::WR_WAIT_PHASE: begin
                ahb.hready = 1'b0;              // stall master
                ahb.hresp  = 1'b0;
                // ahb.hrdata = '0;
                write_en   = 1'b0;
                ahb_read   = 1'b0;
            end

            ahb_slave_pkg::RD_READY_PHASE: begin
                ahb.hready = (active_transfer) ? 1'b1 : 1'b0 ;
                ahb.hresp  = 1'b0                            ;
                // ahb.hrdata = mem[addr_lat]                   ;    // drive data using latched address
                write_en   = 1'b0 ;
                ahb_read   = 1'b1 ;
            end

            ahb_slave_pkg::RD_WAIT_PHASE: begin
                ahb.hready = 1'b0 ;                               // stall master while fetching
                ahb.hresp  = 1'b0 ;
                // ahb.hrdata = '0   ;
                write_en   = 1'b0 ;
                ahb_read   = 1'b0 ;
            end

            default: begin
                ahb.hready = 1'b1 ;
                ahb.hresp  = 1'b0 ;
                // ahb.hrdata = '0   ;
                write_en   = 1'b0 ;
                ahb_read   = 1'b0 ;
            end

        endcase
    end

    // Memory read (data phase)
    always_comb begin
        if (ahb_read) begin
            case (hsize_lat && ahb.hready)
                HSIZE_BYTE: begin
                    `ifdef BIG_EDIAN
                        ahb.hrdata = {mem[addr_lat >> 2][ (3-addr_lat[1:0])*8 +: 8 ], 24'b0};
                    `else // LITTLE ENDIAN
                        ahb.hrdata = { mem[addr_lat >> 2][ (addr_lat[1:0]*8) +: 8 ], 24'b0};
                    `endif
                end

                HSIZE_HWORD: begin
                    `ifdef BIG_EDIAN
                        ahb.hrdata = {mem[addr_lat >> 2][ (1-addr_lat[1])*16 +: 16 ], 16'b0};
                    `else // LITTLE ENDIAN
                        ahb.hrdata = {mem[addr_lat >> 2][ (addr_lat[1]*16) +: 16 ], 16'b0};
                    `endif
                end

                HSIZE_WORD: begin
                    ahb.hrdata = mem[addr_lat >> 2];
                end

                default: ahb.hrdata = '0;
            endcase
        end else begin
            ahb.hrdata = '0;
        end
    end


endmodule: ahb_slave_3