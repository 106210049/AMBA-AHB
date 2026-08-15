import ahb_master_pkg::*;
import ahb_pkg::*;
module ahb_master #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
)(
    ahb_if.master ahb,

    input logic                     i_enb,
    input logic [DATA_WIDTH-1:0]    i_data,
    input logic                     i_write,
    input logic [ADDR_WIDTH-1:0]    i_addr,
    input logic                     i_wrap_en,
    input burst_t                   i_burst_type,
    input hsize_t                   i_data_size,
    input                           i_busy
);

    // internal signals
    logic [ADDR_WIDTH-1:0]  internal_address      ;
    logic [ADDR_WIDTH-1:0]  internal_address_reg  ;
    logic [4:0]             count                 ;
    logic [4:0]             count_reg             ;
    logic [7:0]             size_bytes            ;
    logic [4:0]             beat_length           ; 
    logic [4:0]             burst_length          ;
    // logic [DATA_WIDTH-1:0]  internal_read_data    ;
    logic [ADDR_WIDTH-1:0]  wrap_base             ;
    logic [ADDR_WIDTH-1:0]  wrap_boundary         ;
    // logic [ADDR_WIDTH-1:0]  previous_address      ;
    logic [ADDR_WIDTH-1:0]  haddr_reg             ;
    logic [DATA_WIDTH-1:0]  hwdata_reg            ;
    logic                   hwrite_reg            ;
    logic [2:0]             hsize_reg             ;
    logic [1:0]             htrans_reg            ;
    logic [2:0]             hburst_reg            ;

    state_t current_state, next_state;
    logic load_addr;    // Control Signal for load Address
    logic busy_flag;    // Control Signal for busy flag
    always_comb begin
        case(i_data_size)
            HSIZE_BYTE:     size_bytes = 8'd1;
            HSIZE_HWORD:    size_bytes = 8'd2;
            HSIZE_WORD:     size_bytes = 8'd4;
            HSIZE_DWORD:    size_bytes = 8'd8;
            HSIZE_128BIT:   size_bytes = 8'd16;
            default:        size_bytes = 8'd1;
        endcase
    end

    // -------------------------------------------------------------------------
    // Current state register
    // -------------------------------------------------------------------------
    always_ff @(posedge ahb.hclk or negedge ahb.hreset_n) begin
        if(!ahb.hreset_n)
            current_state <= ahb_master_pkg::IDLE;
        else
            current_state <= next_state;
    end

    always_ff @(posedge ahb.hclk or negedge ahb.hreset_n)   begin
        if(!ahb.hreset_n)   begin
            count                <= 'b0 ;
            internal_address     <= 'b0 ;
            internal_address_reg <= 'b0 ;
            wrap_base            <= 'b0 ;
            wrap_boundary        <= 'b0 ;
            haddr_reg            <= 'b0 ;
            hwdata_reg           <= 'b0 ;
            hwrite_reg           <= 'b0 ;
            hsize_reg            <= 'b0 ;
            htrans_reg           <= 'b0 ;
            hburst_reg           <= 'b0 ;
        end
        else if (ahb.hready && !busy_flag) begin
            haddr_reg  <= ahb.haddr  ;
            hwdata_reg <= ahb.hwdata ;
            hwrite_reg <= ahb.hwrite ;
            hsize_reg  <= ahb.hsize  ;
            htrans_reg <= ahb.htrans ;
            hburst_reg <= ahb.hburst ;
            count_reg  <= count      ;
        end
    end

    always_comb begin
        if(!i_wrap_en)  begin
            case(i_burst_type)
                SINGLE:         burst_length = 5'd0;
                INCR:           burst_length = 5'd1;   
                INCR4:          burst_length = 5'd4;
                INCR8:          burst_length = 5'd8;
                INCR16:         burst_length = 5'd16;
                default:        burst_length = 5'd0;
            endcase
        end
        else    begin
            case(i_burst_type)
                WRAP4:          burst_length = 5'd4;
                WRAP8:          burst_length = 5'd8;
                WRAP16:         burst_length = 5'd16;
                default:        burst_length = 5'd4;
            endcase
        end
    end

    always_comb begin
        case(i_data_size)
            HSIZE_BYTE:            beat_length = 5'd1;
            HSIZE_HWORD:           beat_length = 5'd2;
            HSIZE_WORD:            beat_length = 5'd4;
            HSIZE_DWORD:           beat_length = 5'd8;
            HSIZE_128BIT:          beat_length = 5'd16;
            default:               beat_length = 5'd4;
        endcase
    end

    always_ff @(posedge ahb.hclk or negedge ahb.hreset_n) begin
        if(!ahb.hreset_n)   begin
            count <= '0;
            internal_address <= '0;
        end
        else begin  
            if(load_addr)   begin
                internal_address <= i_addr;
                count <= '0;
            end
            else if(ahb.hready && !i_wrap_en && i_burst_type != ahb_pkg::SINGLE)  begin
                internal_address <= internal_address + beat_length;
                count <= count + 1'b1;
            end
        end
    end

    // -------------------------------------------------------------------------
    // Next-state logic (combinational)
    // -------------------------------------------------------------------------
    always_comb begin
        case(current_state)     
            ahb_master_pkg::IDLE:   begin
                if(i_enb && i_write && ahb.hready)
                    next_state = WR_ADDR_PHASE;
                else if(i_enb && !i_write && ahb.hready)
                    next_state = RD_ADDR_PHASE;
                else
                    next_state = ahb_master_pkg::IDLE;
            end

            WR_ADDR_PHASE:  begin
                next_state = WR_DATA_PHASE;
            end

            WR_DATA_PHASE:  begin
                if(i_busy)  
                    next_state = WAIT_PHASE;
                else if(i_burst_type == SINGLE && ahb.hready)   
                    next_state = ahb_master_pkg::IDLE;
                else if(i_burst_type == INCR4 || i_burst_type == INCR8 || i_burst_type == INCR16)   begin
                    if(count == burst_length)  
                        next_state = ahb_master_pkg::IDLE;
                    else 
                        next_state = WR_DATA_PHASE;
                end
                else if(!i_write && ahb.hready) 
                    next_state = RD_ADDR_PHASE;
                else
                    next_state = WR_DATA_PHASE;
            end

            RD_ADDR_PHASE:  begin
                next_state = RD_DATA_PHASE;
            end

            RD_DATA_PHASE:  begin
                if(i_busy)  
                    next_state = WAIT_PHASE;
                else if(i_burst_type == SINGLE && ahb.hready)   
                    next_state = ahb_master_pkg::IDLE;
                else if(i_burst_type == INCR || i_burst_type == INCR4 || i_burst_type == INCR8 || i_burst_type == INCR16)   begin
                    if(count == burst_length)  
                        next_state = ahb_master_pkg::IDLE;
                    else 
                        next_state = RD_DATA_PHASE;
                end
                else if(i_write && ahb.hready) 
                    next_state = WR_ADDR_PHASE;
                else
                    next_state = RD_DATA_PHASE;
            end

            WAIT_PHASE:     begin
                if(i_busy)  
                    next_state = WAIT_PHASE;
                else if (i_write)
                    next_state = WR_DATA_PHASE;
                else 
                    next_state = RD_DATA_PHASE;
            end

            default: next_state = ahb_master_pkg::IDLE;
        endcase
    end

    always_comb begin
        case(current_state)
            ahb_master_pkg::IDLE:   begin
                ahb.haddr  = '0                    ;
                ahb.hwdata = 'b0                   ;
                ahb.hwrite = 1'b0                  ;
                ahb.htrans = ahb_pkg::IDLE         ;   // IDLE
                ahb.hsize  = i_data_size           ;
                // Control signal for load address
                load_addr  = 1'b1                  ;
                busy_flag  = 1'b0                  ;
            end
            WR_ADDR_PHASE:  begin
                ahb.haddr  = ahb.hready ? i_addr : haddr_reg ;
                ahb.hwrite = 1'b1                  ;
                ahb.htrans = ahb_pkg::NONSEQ       ;   // NONSEQUENTIAL
                ahb.hsize  = i_data_size           ;
                ahb.hburst = i_burst_type          ;
                // Control signal for load address
                load_addr  = 1'b0                  ;
                busy_flag  = 1'b0                  ;
            end
            WR_DATA_PHASE:  begin
                ahb.hwrite = 1'b1         ;
                ahb.hsize  = i_data_size  ;
                // Control signal for load address
                load_addr  = 1'b0         ;
                busy_flag  = 1'b0         ;
                if(ahb.hburst == SINGLE)  begin
                    ahb.hwdata = i_data                               ;
                    ahb.haddr  = ahb.hready ? i_addr : haddr_reg      ;
                    ahb.htrans = ahb_pkg::NONSEQ                      ;             // NONSEQUENTIAL
                    ahb.hburst = i_burst_type                         ;
                end
                else    begin
                    ahb.hwdata = i_data                        ;
                    ahb.haddr  = internal_address              ;
                    ahb.htrans = ahb_pkg::SEQ                  ;             // SEQUENTIAL
                    ahb.hburst = i_burst_type                  ;
                end
            end
            RD_ADDR_PHASE:  begin
                ahb.haddr  = ahb.hready ? i_addr : haddr_reg ;
                ahb.hwrite = 1'b0                          ;
                ahb.htrans = ahb_pkg::NONSEQ               ;           // NONSEQUENTIAL
                ahb.hsize  = i_data_size                   ;
                ahb.hburst = i_burst_type                  ;
                // Control signal for load address
                load_addr  = 1'b0                          ;
                busy_flag  = 1'b0                          ;
            end
            RD_DATA_PHASE:  begin
                ahb.hwrite = 1'b0         ;
                ahb.hsize  = i_data_size  ;
                // Control signal for load address
                load_addr  = 1'b0         ;
                busy_flag  = 1'b0         ;
                if(ahb.hburst == SINGLE)    begin
                    ahb.haddr  = ahb.hready ? i_addr : haddr_reg  ;   
                    ahb.htrans = ahb_pkg::NONSEQ                  ;   // NONSEQUENTIAL
                    ahb.hburst = i_burst_type                     ;
                end
                else begin
                    ahb.haddr  = internal_address          ;
                    ahb.htrans = ahb_pkg::SEQ              ;   // SEQUENTIAL
                    ahb.hburst = i_burst_type              ;
                end
            end
            WAIT_PHASE: begin
                ahb.haddr  = haddr_reg               ;
                ahb.hwdata = hwdata_reg              ;
                ahb.hwrite = hwrite_reg              ;
                ahb.hsize  = hsize_reg               ;
                ahb.htrans = ahb_pkg::BUSY           ;   // BUSY
                ahb.hburst = hburst_reg              ;
                // Control signal for load address
                load_addr  = 1'b0                    ;
                busy_flag  = 1'b1                    ;
            end
            default:    begin
                ahb.haddr  = i_addr         ;
                ahb.hwdata = 'b0            ;
                ahb.hwrite = 1'b0           ;
                ahb.hsize  = i_data_size    ;
                ahb.htrans = ahb_pkg::IDLE  ;
                ahb.hburst = SINGLE         ;
                // Control signal for load address
                load_addr  = 1'b0           ;
                busy_flag  = 1'b0           ;
            end
        endcase
    end

endmodule: ahb_master