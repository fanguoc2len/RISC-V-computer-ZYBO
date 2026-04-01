set script_dir [file normalize [file dirname [info script]]]
set repo_dir [file normalize [file join $script_dir ..]]
set build_dir [file join $repo_dir build]
set vivado_build_dir [file join $repo_dir build vivado_zybo]
set hw_dir [file join $build_dir hw]
set project_name riscv_computer_zybo_z7_10
set summary_file [file join $build_dir zybo_ps_xsa_status.txt]
set xsa_file [file join $hw_dir zybo_z7_10_ps_pl.xsa]

proc timing_slack_or_na {args} {
    set paths [get_timing_paths {*}$args]
    if {[llength $paths] == 0} {
        return "NA"
    }

    return [format "%.3f" [get_property SLACK [lindex $paths 0]]]
}

proc apply_run_strategy {run_name strategy_name} {
    set run_obj [get_runs $run_name]
    if {[llength $run_obj] == 0} {
        puts "WARNING: Run $run_name not found."
        return
    }

    set available_strategies [list_property_value strategy $run_obj]
    if {[lsearch -exact $available_strategies $strategy_name] >= 0} {
        set_property strategy $strategy_name $run_obj
        puts "Using strategy $strategy_name for $run_name"
    } else {
        puts "WARNING: Strategy $strategy_name is not available for $run_name."
    }
}

cd $repo_dir
file mkdir $build_dir
file mkdir $hw_dir

source [file join $script_dir create_vivado_zybo_ps_project.tcl]

reset_run synth_1
reset_run impl_1
apply_run_strategy synth_1 Flow_PerfOptimized_high
apply_run_strategy impl_1 Performance_ExplorePostRoutePhysOpt

launch_runs synth_1 -jobs 4
wait_on_run synth_1

launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1

open_run impl_1

set top_name [get_property top [get_filesets sources_1]]
set bitfile [file join $vivado_build_dir ${project_name}.runs impl_1 ${top_name}.bit]
set synth_status [get_property STATUS [get_runs synth_1]]
set impl_status [get_property STATUS [get_runs impl_1]]
set synth_strategy [get_property STRATEGY [get_runs synth_1]]
set impl_strategy [get_property STRATEGY [get_runs impl_1]]
set setup_slack [timing_slack_or_na -setup -nworst 1 -max_paths 1]
set hold_slack [timing_slack_or_na -hold -nworst 1 -max_paths 1]
set include_bit 1

if {[llength [info commands write_hw_platform]] == 0} {
    error "write_hw_platform command is not available in this Vivado session."
}

if {[catch {write_hw_platform -fixed -include_bit -force -file $xsa_file} hw_err]} {
    puts "WARNING: write_hw_platform with -include_bit failed:"
    puts "  $hw_err"
    puts "Retrying without -include_bit."
    set include_bit 0
    write_hw_platform -fixed -force -file $xsa_file
}

set summary_fh [open $summary_file w]
puts $summary_fh "synth_status=$synth_status"
puts $summary_fh "impl_status=$impl_status"
puts $summary_fh "synth_strategy=$synth_strategy"
puts $summary_fh "impl_strategy=$impl_strategy"
puts $summary_fh "worst_setup_slack_ns=$setup_slack"
puts $summary_fh "worst_hold_slack_ns=$hold_slack"
puts $summary_fh "top_name=$top_name"
puts $summary_fh "bitfile=$bitfile"
puts $summary_fh "bitfile_exists=[expr {[file exists $bitfile] ? 1 : 0}]"
puts $summary_fh "xsa_file=$xsa_file"
puts $summary_fh "xsa_exists=[expr {[file exists $xsa_file] ? 1 : 0}]"
puts $summary_fh "xsa_include_bit=$include_bit"
close $summary_fh

puts "ZYBO PS XSA EXPORT SUMMARY"
puts "  synth_status=$synth_status"
puts "  impl_status=$impl_status"
puts "  synth_strategy=$synth_strategy"
puts "  impl_strategy=$impl_strategy"
puts "  worst_setup_slack_ns=$setup_slack"
puts "  worst_hold_slack_ns=$hold_slack"
puts "  top_name=$top_name"
puts "  bitfile=$bitfile"
puts "  xsa_file=$xsa_file"
puts "  xsa_include_bit=$include_bit"

if {![file exists $xsa_file]} {
    puts "ERROR: XSA export was not generated."
    close_project
    exit 1
}

close_project
exit
