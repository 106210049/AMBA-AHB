package ahb_master_pkg;

    typedef enum logic [2:0]    {
        IDLE                = 3'b000,
        WR_ADDR_PHASE       = 3'b001,
        WR_DATA_PHASE       = 3'b010,
        RD_ADDR_PHASE       = 3'b011,
        RD_DATA_PHASE       = 3'b100,
        WAIT_PHASE          = 3'b101
    } state_t;

endpackage: ahb_master_pkg