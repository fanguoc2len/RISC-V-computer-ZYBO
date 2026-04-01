set script_dir [file normalize [file dirname [info script]]]
set repo_dir [file normalize [file join $script_dir ..]]
set build_dir [file join $repo_dir build vivado_zybo]
set bd_name zybo_z7_10_ps
set project_name riscv_computer_zybo_z7_10

source [file join $script_dir create_vivado_zybo_project.tcl]

if {[llength [get_bd_designs -quiet $bd_name]] > 0} {
    close_bd_design [get_bd_designs $bd_name]
    remove_files [get_files -quiet */$bd_name.bd]
}

create_bd_design $bd_name
current_bd_design $bd_name

create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7 processing_system7_0

set board_part_name [get_property board_part [current_project]]
if {[string length $board_part_name] > 0} {
    apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config {make_external "FIXED_IO, DDR" apply_board_preset "1"} [get_bd_cells /processing_system7_0]
} else {
    make_bd_intf_pins_external [get_bd_intf_pins /processing_system7_0/DDR]
    make_bd_intf_pins_external [get_bd_intf_pins /processing_system7_0/FIXED_IO]
}

set_property -dict [list \
    CONFIG.PCW_USE_M_AXI_GP0 {1} \
    CONFIG.PCW_USE_S_AXI_HP0 {1} \
    CONFIG.PCW_USE_FABRIC_INTERRUPT {1} \
    CONFIG.PCW_EN_CLK0_PORT {1} \
    CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {100.0} \
] [get_bd_cells /processing_system7_0]

create_bd_cell -type module -reference zybo_z7_10_ps_pl_top zybo_z7_10_ps_pl_top_0
create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect smartconnect_umem_0
set_property -dict [list \
    CONFIG.NUM_SI {1} \
    CONFIG.NUM_MI {1} \
] [get_bd_cells /smartconnect_umem_0]
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat xlconcat_irq_f2p_0
set_property -dict [list \
    CONFIG.NUM_PORTS {2} \
    CONFIG.IN0_WIDTH {1} \
    CONFIG.IN1_WIDTH {15} \
] [get_bd_cells /xlconcat_irq_f2p_0]
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant xlconstant_irq_pad_0
set_property -dict [list \
    CONFIG.CONST_WIDTH {15} \
    CONFIG.CONST_VAL {0} \
] [get_bd_cells /xlconstant_irq_pad_0]

connect_bd_intf_net [get_bd_intf_pins /processing_system7_0/M_AXI_GP0] [get_bd_intf_pins /zybo_z7_10_ps_pl_top_0/S_AXI_CTRL]
connect_bd_intf_net [get_bd_intf_pins /zybo_z7_10_ps_pl_top_0/M_AXI_UMEM] [get_bd_intf_pins /smartconnect_umem_0/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins /smartconnect_umem_0/M00_AXI] [get_bd_intf_pins /processing_system7_0/S_AXI_HP0]
connect_bd_net [get_bd_pins /processing_system7_0/FCLK_CLK0] [get_bd_pins /processing_system7_0/M_AXI_GP0_ACLK]
connect_bd_net [get_bd_pins /processing_system7_0/FCLK_CLK0] [get_bd_pins /zybo_z7_10_ps_pl_top_0/pl_clk0]
connect_bd_net [get_bd_pins /processing_system7_0/FCLK_CLK0] [get_bd_pins /processing_system7_0/S_AXI_HP0_ACLK]
connect_bd_net [get_bd_pins /processing_system7_0/FCLK_CLK0] [get_bd_pins /smartconnect_umem_0/aclk]
connect_bd_net [get_bd_pins /processing_system7_0/FCLK_CLK0] [get_bd_pins /smartconnect_umem_0/S00_AXI_ACLK]
connect_bd_net [get_bd_pins /processing_system7_0/FCLK_CLK0] [get_bd_pins /smartconnect_umem_0/M00_AXI_ACLK]
connect_bd_net [get_bd_pins /processing_system7_0/FCLK_RESET0_N] [get_bd_pins /zybo_z7_10_ps_pl_top_0/pl_resetn0]
connect_bd_net [get_bd_pins /processing_system7_0/FCLK_RESET0_N] [get_bd_pins /smartconnect_umem_0/aresetn]
connect_bd_net [get_bd_pins /processing_system7_0/FCLK_RESET0_N] [get_bd_pins /smartconnect_umem_0/S00_AXI_ARESETN]
connect_bd_net [get_bd_pins /processing_system7_0/FCLK_RESET0_N] [get_bd_pins /smartconnect_umem_0/M00_AXI_ARESETN]
connect_bd_net [get_bd_pins /zybo_z7_10_ps_pl_top_0/irq_f2p] [get_bd_pins /xlconcat_irq_f2p_0/In0]
connect_bd_net [get_bd_pins /xlconstant_irq_pad_0/dout] [get_bd_pins /xlconcat_irq_f2p_0/In1]
connect_bd_net [get_bd_pins /xlconcat_irq_f2p_0/dout] [get_bd_pins /processing_system7_0/IRQ_F2P]

foreach pin_name {uart_rx uart_tx ps2_clk ps2_data spi_cs_n spi_sclk spi_mosi spi_miso led} {
    make_bd_pins_external [get_bd_pins /zybo_z7_10_ps_pl_top_0/$pin_name]
}

set_property name uart_rx [get_bd_ports uart_rx_0]
set_property name uart_tx [get_bd_ports uart_tx_0]
set_property name ps2_clk [get_bd_ports ps2_clk_0]
set_property name ps2_data [get_bd_ports ps2_data_0]
set_property name spi_cs_n [get_bd_ports spi_cs_n_0]
set_property name spi_sclk [get_bd_ports spi_sclk_0]
set_property name spi_mosi [get_bd_ports spi_mosi_0]
set_property name spi_miso [get_bd_ports spi_miso_0]
set_property name led [get_bd_ports led_0]

regenerate_bd_layout
save_bd_design
validate_bd_design

set bd_files [get_files -quiet */$bd_name.bd]
if {[llength $bd_files] > 0} {
    generate_target all $bd_files
    make_wrapper -files $bd_files -top

    set wrapper_file [file join $build_dir ${project_name}.gen sources_1 bd $bd_name hdl ${bd_name}_wrapper.v]
    if {[file exists $wrapper_file]} {
        add_files -norecurse $wrapper_file
        set_property top ${bd_name}_wrapper [get_filesets sources_1]
        update_compile_order -fileset sources_1
        puts "Wrapper generated and set as synthesis top:"
        puts "  $wrapper_file"
    } else {
        puts "WARN: Block design wrapper was not found at the expected path."
    }
}

puts "Created Zybo PS/PL block design: $bd_name"
puts "Fabric IRQ path: zybo_z7_10_ps_pl_top.irq_f2p -> xlconcat -> processing_system7_0/IRQ_F2P"
puts "Unified-memory AXI path: zybo_z7_10_ps_pl_top.M_AXI_UMEM -> smartconnect_umem_0 -> processing_system7_0/S_AXI_HP0"
puts "Next step inside Vivado: review PS DDR/MIO config, then synthesize the full PS+PL platform."
