set script_dir [file normalize [file dirname [info script]]]
set repo_dir [file normalize [file join $script_dir ..]]
set build_dir [file join $repo_dir build vivado_zybo]

file mkdir $build_dir

create_project riscv_computer_zybo_z7_10 $build_dir -part xc7z010clg400-1 -force
set_property target_language Verilog [current_project]

set zybo_board_parts [get_board_parts -quiet *zybo*z7-10*]
if {[llength $zybo_board_parts] > 0} {
    set selected_board_part [lindex $zybo_board_parts 0]
    set_property board_part $selected_board_part [current_project]
    puts "Using board part: $selected_board_part"
} else {
    puts "WARN: Zybo Z7-10 board files were not found. The project will still be created by part number only."
}

add_files [file join $repo_dir third_party picorv32 picorv32.v]
add_files [glob -nocomplain [file join $repo_dir rtl memory *.v]]
add_files [glob -nocomplain [file join $repo_dir rtl peripherals *.v]]
add_files [glob -nocomplain [file join $repo_dir rtl soc *.v]]
add_files [glob -nocomplain [file join $repo_dir rtl video *.v]]
add_files [glob -nocomplain [file join $repo_dir rtl accel *.v]]
add_files [glob -nocomplain [file join $repo_dir rtl top *.v]]
add_files [file join $repo_dir bootrom.mem]
add_files -fileset constrs_1 [file join $repo_dir constraints zybo_z7_10_template.xdc]
add_files -fileset sim_1 [glob -nocomplain [file join $repo_dir tb *.v]]
add_files -fileset sim_1 [file join $repo_dir boot_image.hex]

set_property file_type {Memory Initialization Files} [get_files [file join $repo_dir bootrom.mem]]
set_property file_type {Memory Initialization Files} [get_files [file join $repo_dir boot_image.hex]]

set_property top zybo_z7_10_accel_shell [get_filesets sources_1]
set_property top monitor_shell_tb [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset constrs_1
update_compile_order -fileset sim_1

puts "Vivado Zybo project created at $build_dir"
puts "Synthesis top: zybo_z7_10_accel_shell"
puts "Simulation top: monitor_shell_tb"
puts "Next step: replace the constraint template with verified Zybo Z7-10 constraints or source scripts/create_vivado_zybo_ps_project.tcl for the PS/PL block design."
