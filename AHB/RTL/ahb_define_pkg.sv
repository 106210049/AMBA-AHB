package ahb_define_pkg;

  // Burst, HTRANS, HSIZE, Endian
  typedef enum logic [2:0] {
    SINGLE  = 3'b000, INCR = 3'b001, INCR4 = 3'b010, INCR8 = 3'b011,
    INCR16  = 3'b100, WRAP4 = 3'b101, WRAP8 = 3'b110, WRAP16 = 3'b111
  } burst_t;

  typedef enum logic [1:0] {
    IDLE = 2'b00, BUSY = 2'b01, NONSEQ = 2'b10, SEQ = 2'b11
  } htrans_t;

  typedef enum logic [2:0] {
    HSIZE_BYTE   = 3'b000,
    HSIZE_HWORD  = 3'b001,
    HSIZE_WORD   = 3'b010,
    HSIZE_DWORD  = 3'b011,
    HSIZE_128BIT = 3'b100
  } hsize_t;

  typedef enum bit { BIG_ENDIAN = 1'b0, LITTLE_ENDIAN = 1'b1 } endian_e;

  // Convert hsize to bytes
  function automatic int hsize2bytes(hsize_t s);
    case (s)
      HSIZE_BYTE  : hsize2bytes = 1;
      HSIZE_HWORD : hsize2bytes = 2;
      HSIZE_WORD  : hsize2bytes = 4;
      HSIZE_DWORD : hsize2bytes = 8;
      HSIZE_128BIT: hsize2bytes = 16;
      default     : hsize2bytes = 1;
    endcase
  endfunction

  // -------------------------
  // Physical-lane helpers
  // lane: 0..3 where 0 = MSB (bits[31:24]), 3 = LSB (bits[7:0])
  // -------------------------
  function automatic byte byte_at_lane(input bit [31:0] word, input int lane);
    byte_at_lane = word[(31 - lane*8) -: 8];
  endfunction

  function automatic bit [31:0] set_byte_at_lane(input bit [31:0] word, input int lane, input byte val);
    bit [31:0] tmp;
    tmp = word;
    tmp[(31 - lane*8) -: 8] = val;
    set_byte_at_lane = tmp;
  endfunction

  // -------------------------
  // Logical-byte helpers
  // i = 0..nbytes-1 (logical order inside the field)
  // logical_to_phys maps logical offset within field to physical lane in word
  // For BIG_ENDIAN: phys = base_byte_index + i
  // For LITTLE_ENDIAN: phys = 3 - (base_byte_index + i)
  // -------------------------
  function automatic int logical_to_phys(input int base_byte_index, input int i, input endian_e endian);
    int phys;
    if (endian == BIG_ENDIAN) phys = base_byte_index + i;
    else                      phys = 3 - (base_byte_index + i);
    logical_to_phys = phys;
  endfunction

  function automatic byte get_logical_byte_from_word_32(input bit [31:0] word,
                                                        input int base_byte_index,
                                                        input int i,
                                                        input endian_e endian);
    int phys;
    phys = logical_to_phys(base_byte_index, i, endian);
    get_logical_byte_from_word_32 = byte_at_lane(word, phys);
  endfunction

  function automatic bit [31:0] build_word_from_logical_bytes_32(input byte bytes[4],
                                                                 input int nbytes,
                                                                 input int base_byte_index,
                                                                 input endian_e endian);
    bit [31:0] w;
    int i;
    w = '0;
    for (i = 0; i < nbytes; i = i + 1) begin
      int phys = logical_to_phys(base_byte_index, i, endian);
      w = set_byte_at_lane(w, phys, bytes[i]);
    end
    build_word_from_logical_bytes_32 = w;
  endfunction

  // -------------------------
  // Mask helpers (32-bit)
  // - MSB base (HWORD -> 0xFFFF0000)
  // - LSB base (HWORD -> 0x0000FFFF)
  // - build_mask_shifted(size, byte_index, endian) returns mask placed at correct lanes
  //   byte_index = addr & 3 (0..3) is offset within the 32-bit word
  // -------------------------
  function automatic bit [31:0] build_mask_32_msb(hsize_t size);
    int nbytes = hsize2bytes(size);
    int bits = nbytes * 8;
    bit [31:0] full = 32'hFFFF_FFFF;
    if (bits >= 32) build_mask_32_msb = full;
    else build_mask_32_msb = (full >> (32 - bits)) << (32 - bits);
  endfunction

  function automatic bit [31:0] build_mask_32_lsb(hsize_t size);
    int nbytes = hsize2bytes(size);
    int bits = nbytes * 8;
    if (bits >= 32) build_mask_32_lsb = 32'hFFFF_FFFF;
    else build_mask_32_lsb = ((32'h1 << bits) - 1);
  endfunction

  // Corrected build_mask_shifted
  function automatic bit [31:0] build_mask_shifted(hsize_t size, int byte_index, endian_e endian);
    bit [31:0] base_msb;
    bit [31:0] base_lsb;
    base_msb = build_mask_32_msb(size);
    base_lsb = build_mask_32_lsb(size);

    if (endian == BIG_ENDIAN) begin
      // MSB base, dịch phải theo byte_index (byte_index=0 -> MSB lane)
      build_mask_shifted = (base_msb >> (byte_index * 8));
    end else begin
      // LITTLE_ENDIAN: LSB base, dịch trái theo byte_index (byte_index=0 -> LSB lane)
      build_mask_shifted = (base_lsb << (byte_index * 8));
    end
  endfunction

  // Optional helper: mask always MSB-shifted (useful if you always compare MSB-justified expected)
  function automatic bit [31:0] build_mask_msb_shifted(hsize_t size, int byte_index);
    build_mask_msb_shifted = (build_mask_32_msb(size) >> (byte_index * 8));
  endfunction

endpackage : ahb_define_pkg
