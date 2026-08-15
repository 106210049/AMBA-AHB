package ahb_slave_pkg;
    typedef enum logic [2:0]    {
        IDLE                = 3'b000,
        WR_READY_PHASE      = 3'b001,
        RD_READY_PHASE      = 3'b010,
        WR_WAIT_PHASE       = 3'b011,
        RD_WAIT_PHASE       = 3'b100
    } state_t;

endpackage: ahb_slave_pkg