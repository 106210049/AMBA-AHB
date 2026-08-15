package ahb_pkg;
    typedef enum logic [2:0]    {
        SINGLE              = 3'b000,
        INCR                = 3'b001,
        INCR4               = 3'b010,
        INCR8               = 3'b011,
        INCR16              = 3'b100,
        WRAP4               = 3'b101,
        WRAP8               = 3'b110,
        WRAP16              = 3'b111
    } burst_t;

    typedef enum logic [1:0]    {
        IDLE                = 2'b00,
        BUSY                = 2'b01,
        NONSEQ              = 2'b10,
        SEQ                 = 2'b11
    }htrans_t;

    typedef enum logic [2:0]    {
        HSIZE_BYTE          = 3'b000,
        HSIZE_HWORD         = 3'b001,
        HSIZE_WORD          = 3'b010,
        HSIZE_DWORD         = 3'b011,
        HSIZE_128BIT        = 3'b100
    }hsize_t;
endpackage: ahb_pkg