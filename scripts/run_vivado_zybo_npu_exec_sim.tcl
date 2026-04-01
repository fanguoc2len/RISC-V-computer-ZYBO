set script_dir [file normalize [file dirname [info script]]]
set repo_dir [file normalize [file join $script_dir ..]]
set build_dir [file join $repo_dir build]
set sim_log [file join $repo_dir build vivado_zybo risc_v_computer_zybo_z7_10.sim sim_1 behav xsim simulate.log]
set saved_log [file join $build_dir vivado_zybo_npu_exec_stub.log]

cd $repo_dir
source [file join $script_dir create_vivado_zybo_project.tcl]

catch {close_sim}
set_property top accel_npu_cmd_exec_stub_tb [get_filesets sim_1]
update_compile_order -fileset sim_1

puts "Starting NPU command execution stub simulation..."
launch_simulation -simset sim_1 -mode behavioral
restart
run all

if {![file exists $sim_log]} {
    error "Simulation log not found: $sim_log"
}

file copy -force $sim_log $saved_log
set fh [open $saved_log r]
set contents [read $fh]
close $fh

if {[string first "PASS: NPU command execution stub regression completed." $contents] < 0} {
    error "PASS marker was not found in $saved_log"
}

puts "Verified NPU command execution stub."
puts "  log: $saved_log"
