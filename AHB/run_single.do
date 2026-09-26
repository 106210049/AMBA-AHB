# run_single.do

# Setup paths
set uvm_path C:/questasim64_10.7c/verilog_src/uvm-1.1d/src
set wlf_dir ./wlf_out
set cov_dir ./cov_out
set log_dir ./logs

# Dọn dẹp thư mục cũ
foreach dir [list $wlf_dir $cov_dir $log_dir] {
    if {[file exists $dir]} {
        foreach f [glob -nocomplain -directory $dir *] {
            file delete -force $f
        }
        file delete -force $dir
    }
    file mkdir $dir
}

# Compile UVM package
vlog -sv +define+UVM_CMDLINE_NO_DPI +define+UVM_REGEX_NO_DPI +define+UVM_NO_DPI +incdir+$uvm_path \
     $uvm_path/uvm_pkg.sv

# Compile project (package, interface, RTL, testbench)
vlog +cover -sv -svinputport=relaxed +incdir+$uvm_path -f ./TB/tb/ahb_run.f

# Lấy tên test từ tham số
if {$argc == 0} {
    puts ">>> Bạn phải truyền tên test, ví dụ: do run_single.do ahb_master_single_test"
    quit -f
}
set TESTNAME [lindex $argv 0]

# File output
set wlf_file "$wlf_dir/${TESTNAME}.wlf"
set ucdb_file "$cov_dir/${TESTNAME}.ucdb"
set log_file "$log_dir/${TESTNAME}.log"

puts ">>> Running single test: $TESTNAME"

# Chạy simulation
vsim -c -coverage -wlf $wlf_file work.tb_ahb_top \
     "+SVSEED=random" \
     "+UVM_TESTNAME=$TESTNAME" \
     "+UVM_VERBOSITY=UVM_FULL" \
     "+UVM_TR_RECORD" \
     -onfinish final \
     -do "transcript file $log_file; log -r /*; run -all; coverage save -onexit $ucdb_file; quit -sim;" \
     -debugDB

# Báo cáo coverage nếu có file .ucdb
if {[file exists $ucdb_file]} {
    exec vcover report -html -htmldir covhtml_${TESTNAME} $ucdb_file
    exec vcover report -detail -cvg -assert -comments -output ${TESTNAME}_cover_report.txt $ucdb_file

    set fp [open "${TESTNAME}_cover_report.txt" r]
    puts ">>> Nội dung coverage report cho $TESTNAME:"
    puts [read $fp]
    close $fp
} else {
    puts ">>> Không tạo được file coverage cho test $TESTNAME"
}

exit
