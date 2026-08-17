vlog -sv -f ./RTL/rtl.f ./TB/single_test.sv
#vlog -sv -f ./RTL/rtl.f ./TB/incr_burst_test.sv
#vlog -sv -f ./RTL/rtl.f ./TB/test_wait_state.sv
vsim -voptargs=+acc -debugDB work.ahb_top_tb