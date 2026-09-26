# regression_ahb.do

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

# Xóa coverage tổng hợp cũ
file delete -force ahb_all.ucdb

# Compile UVM package
vlog -sv +define+UVM_CMDLINE_NO_DPI +define+UVM_REGEX_NO_DPI +define+UVM_NO_DPI +incdir+$uvm_path \
     $uvm_path/uvm_pkg.sv

# Compile project (package, interface, RTL, testbench)
vlog +cover -sv -svinputport=relaxed +incdir+$uvm_path -f ./TB/tb/ahb_run.f

# Danh sách các test
set TESTS {
    ahb_master_slv1_test
    ahb_master_slv2_test
    ahb_master_slv3_test
    ahb_master_slv4_test
    ahb_master_single_test
    ahb_master_incr_test
    ahb_master_incr4_test
    ahb_master_incr8_test
    ahb_master_incr16_test
    ahb_master_wrap4_test
    ahb_master_wrap8_test
    ahb_master_wrap16_test
    ahb_master_hsize_byte_test
    ahb_master_hsize_hword_test
    ahb_master_hsize_word_test
    ahb_master_random_test
    ahb_master_random_30_test
    ahb_master_data_zero_test
    ahb_master_data_full_one_test
    ahb_master_high_boundary_address_test
    ahb_master_low_boundary_address_test
    ahb_master_driver_wait_state_test
}

# Chạy từng test
foreach t $TESTS {
    set wlf_file "$wlf_dir/${t}.wlf"
    set ucdb_file "$cov_dir/${t}.ucdb"
    set log_file "$log_dir/${t}.log"

    puts ">>> Running test: $t"

    vsim -c -coverage -wlf $wlf_file work.tb_ahb_top \
         "+SVSEED=random" \
         "+UVM_TESTNAME=$t" \
         "+UVM_VERBOSITY=UVM_FULL" \
         "+UVM_TR_RECORD" \
         -onfinish final \
         -do "transcript file $log_file; log -r /*; run -all; coverage save -onexit $ucdb_file; quit -sim;" \
         -debugDB
}
# Merge coverage
vcover merge ahb_all.ucdb $cov_dir/*.ucdb

# Report coverage
if {[file exists ahb_all.ucdb]} {
    # HTML report (bao gồm cả assertion coverage)
    exec vcover report -html -htmldir covhtmlreport ahb_all.ucdb

    # TXT report chi tiết, bao gồm code, functional và assertion coverage
    exec vcover report -detail -cvg -assert -comments -output ahb_cover_report.txt ahb_all.ucdb

    # Hiển thị nội dung TXT ngay trong transcript
    set fp [open "ahb_cover_report.txt" r]
    puts ">>> Nội dung coverage report:"
    puts [read $fp]
    close $fp
} else {
    puts "Không tìm thấy file ahb_all.ucdb để tạo báo cáo coverage!"
}

exit
