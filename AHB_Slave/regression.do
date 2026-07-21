file mkdir logs
file delete -force all_tests.ucdb

# Initial compilation
vlog testbench.sv

set TESTS {FIXED_ADDR RAND_ADDR RAND_ADDR_INRANGE TEST_BUSY TEST_IDLE TEST_SEQ TEST_RAND_HSIZE READ_WAIT_STATE WRITE_WAIT_STATE TEST_HRESP}

foreach t $TESTS {
    transcript file logs/$t.log
    vsim -c -coverage -debugDB work.ahb_tb_top +TESTNAME=$t -do "run -all; coverage save logs/$t.ucdb;"
    transcript file ""
}

# merge all coverage
vcover merge all_tests.ucdb logs/*.ucdb

# generate HTML coverage report
vcover report -html -htmldir covhtmlreport all_tests.ucdb
