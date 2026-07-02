set script_dir [file normalize [file dirname [info script]]]
set repo_dir [file normalize [file join $script_dir ..]]
set project_name riscv_computer_zybo_z7_10
set top_name zybo_z7_10_accel_shell
set bitfile [file join $repo_dir build vivado_zybo ${project_name}.runs impl_1 ${top_name}.bit]

if {![file exists $bitfile]} {
    puts "ERROR: Bitstream not found: $bitfile"
    exit 1
}

open_hw_manager
connect_hw_server
open_hw_target

set devices [get_hw_devices]
if {[llength $devices] == 0} {
    puts "ERROR: No hardware device detected."
    close_hw_manager
    exit 1
}

current_hw_device [lindex $devices 0]
refresh_hw_device [current_hw_device]
set_property PROGRAM.FILE $bitfile [current_hw_device]
program_hw_devices [current_hw_device]

close_hw_manager
exit
