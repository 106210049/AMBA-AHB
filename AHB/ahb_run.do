#vlog -sv -f ./RTL/rtl.f ./TB/single_test.sv
vlog -sv -f ./RTL/rtl.f ./TB/incr_burst_test.sv
vsim -voptargs=+acc -debugDB work.ahb_top_tb