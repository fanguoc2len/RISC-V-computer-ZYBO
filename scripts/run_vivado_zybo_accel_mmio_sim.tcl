set script_dir [file normalize [file dirname [info script]]]
set repo_dir [file normalize [file join $script_dir ..]]
set build_dir [file join $repo_dir build]
set sim_log [file join $repo_dir build vivado_zybo risc_v_computer_zybo_z7_10.sim sim_1 behav xsim simulate.log]
set saved_log [file join $build_dir vivado_zybo_accel_mmio_sim.log]

file mkdir $build_dir

proc read_file_or_empty {path} {
    if {![file exists $path]} {
        return ""
    }

    set fh [open $path r]
    set contents [read $fh]
    close $fh
    return $contents
}

source [file join $script_dir create_vivado_zybo_project.tcl]

set_property top accel_mmio_regs_tb [get_filesets sim_1]
update_compile_order -fileset sim_1

launch_simulation -simset sim_1 -mode behavioral
restart
run all

if {![file exists $sim_log]} {
    error "Simulation log not found: $sim_log"
}

file copy -force $sim_log $saved_log
set contents [read_file_or_empty $saved_log]

if {[string first "PASS: accel mmio regression completed." $contents] < 0} {
    error "PASS marker 'PASS: accel mmio regression completed.' was not found in $saved_log"
}

puts "Zybo accel MMIO simulation PASSED."
puts "Log:"
puts "  $saved_log"
