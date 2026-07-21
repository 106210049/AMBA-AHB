package testcase_pkg;

typedef enum logic [3:0] {
  FIXED_ADDR          = 4'b0000,
  RAND_ADDR           = 4'b0001,
  RAND_ADDR_INRANGE   = 4'b0010,
  TEST_BUSY           = 4'b0011,
  TEST_IDLE           = 4'b0100,
  TEST_SEQ            = 4'b0101,
  TEST_RAND_HSIZE     = 4'b0110,
  READ_WAIT_STATE     = 4'b0111,
  WRITE_WAIT_STATE    = 4'b1000,
  TEST_HRESP          = 4'b1001
} test_case;


endpackage: testcase_pkg