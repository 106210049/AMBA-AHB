// ahb_pkg.sv
// Purpose: Common AHB types & helpers shared by TB.

package ahb_pkg;
    // -----------------------------
    // Transfer type in AHB (HTRANS)
    // -----------------------------
    typedef enum logic [1:0] {
    HTRANS_IDLE   = 2'b00,
    HTRANS_BUSY   = 2'b01,
    HTRANS_NONSEQ = 2'b10,
    HTRANS_SEQ    = 2'b11
    } htrans_e;

    // ------------------------------------
    // Transfer size in bytes (AHB HSIZE)
    // ------------------------------------
    typedef enum logic [2:0] {
    HSIZE_BYTE    = 3'b000, // 1B
    HSIZE_HWORD   = 3'b001, // 2B
    HSIZE_WORD    = 3'b010, // 4B
    HSIZE_DWORD   = 3'b011, // 8B
    HSIZE_128BIT  = 3'b100  // 16B
    } hsize_e;

  // ---------- Utils ----------
  // Convert HSIZE enum to number of bytes (1/2/4/8/16)
  function int hsize2bytes(hsize_e s);
    case (s)
      HSIZE_BYTE   : return 1;
      HSIZE_HWORD  : return 2;
      HSIZE_WORD   : return 4;
      HSIZE_DWORD  : return 8;
      HSIZE_128BIT : return 16;
      default      : return 1;
    endcase
  endfunction
  
  // Names for cleaner logs (enum -> string)
  function string htrans_name(htrans_e t);
    case (t)
      HTRANS_IDLE   : return "IDLE";
      HTRANS_BUSY   : return "BUSY";
      HTRANS_NONSEQ : return "NONSEQ";
      HTRANS_SEQ    : return "SEQ";
      default       : return "UNK";
    endcase
  endfunction

  function string hsize_name(hsize_e s);
    case (s)
      HSIZE_BYTE    : return "BYTE";
      HSIZE_HWORD   : return "HWORD";
      HSIZE_WORD    : return "WORD";
      HSIZE_DWORD   : return "DWORD";
      HSIZE_128BIT  : return "128BIT";
      default       : return "UNK";
    endcase
  endfunction

endpackage : ahb_pkg