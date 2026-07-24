# dọn dẹp logs cũ
if {[file exists logs]} {
    foreach f [glob -nocomplain -directory logs *] {
        file delete -force $f
    }
    file delete -force logs
}
file mkdir logs
file delete -force all_tests.ucdb
file delete -force ./*.ucdb
set TESTS {FIXED_ADDR RAND_ADDR RAND_ADDR_INRANGE TEST_BUSY TEST_IDLE TEST_SEQ TEST_RAND_HSIZE TEST_HRESP}

foreach t $TESTS {
    # Chọn file testbench theo tên test
    set tbfile "./TB/testbench.sv"
    # Compilation
    vlog +cover ./TB/taxi_ahbl_if.sv ./RTL/taxi_ahbl_ram.sv $tbfile

    # Transcript riêng cho từng test
    transcript file logs/$t.log
    vsim -c -coverage -debugDB -sv_seed random -voptargs=+acc work.ahb_tb_top +TESTNAME=$t -onfinish final -do "run -all; coverage save -onexit $t.ucdb; quit -sim;"
    transcript off
}

# merge all coverage
vcover merge all_tests.ucdb ./*.ucdb

# generate HTML coverage report
vcover report -html -htmldir covhtmlreport all_tests.ucdb

set WAIT_TRANSFER_TESTS {WRITE_WAIT_STATE READ_WAIT_STATE}

foreach t $WAIT_TRANSFER_TESTS {
    # Chọn file testbench theo tên test
    set tbfile "./TB/testbench.sv"
    if {$t eq "WRITE_WAIT_STATE"} {
        set tbfile "./TB/testbench_2.sv"
    } elseif {$t eq "READ_WAIT_STATE"} {
        set tbfile "./TB/testbench_3.sv"
    }
    # Compilation
    vlog +cover ./TB/taxi_ahbl_if.sv ./RTL/taxi_ahbl_ram.sv $tbfile

    # Transcript riêng cho từng test
    transcript file logs/$t.log
    vsim -c -coverage -debugDB -sv_seed random -voptargs=+acc work.ahb_tb_top +TESTNAME=$t -onfinish final -do "run -all; quit -sim;"
    transcript off
}

exit