set script_dir [file normalize [file dirname [info script]]]
set repo_dir [file normalize [file join $script_dir ..]]
set build_dir [file join $repo_dir build vivado_cmdq_frontend]
file mkdir $build_dir

create_project zybo_cmdq_frontend $build_dir -part xc7z010clg400-1 -force
set_property target_language Verilog [current_project]

add_files [file join $repo_dir rtl accel accel_cmdq_frontend_stub.v]
add_files -fileset sim_1 [file join $repo_dir tb accel_cmdq_frontend_stub_tb.v]
set_property top accel_cmdq_frontend_stub_tb [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

launch_simulation -simset sim_1 -mode behavioral
restart
run all
