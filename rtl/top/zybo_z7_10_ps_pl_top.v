module zybo_z7_10_ps_pl_top (
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 pl_clk0 CLK" *)
    (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME pl_clk0, ASSOCIATED_BUSIF S_AXI_CTRL:M_AXI_UMEM, ASSOCIATED_RESET pl_resetn0, FREQ_HZ 100000000" *)
    input  wire        pl_clk0,
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 pl_resetn0 RST" *)
    (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME pl_resetn0, POLARITY ACTIVE_LOW" *)
    input  wire        pl_resetn0,

    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_CTRL AWADDR" *)
    (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME S_AXI_CTRL, PROTOCOL AXI4LITE, ADDR_WIDTH 8, DATA_WIDTH 32, FREQ_HZ 100000000, HAS_BRESP 1, HAS_RRESP 1, MAX_BURST_LENGTH 1, NUM_READ_OUTSTANDING 1, NUM_WRITE_OUTSTANDING 1, SUPPORTS_NARROW_BURST 0" *)
    input  wire [7:0]  s_axi_ctrl_awaddr,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_CTRL AWVALID" *)
    input  wire        s_axi_ctrl_awvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_CTRL AWREADY" *)
    output wire        s_axi_ctrl_awready,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_CTRL WDATA" *)
    input  wire [31:0] s_axi_ctrl_wdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_CTRL WSTRB" *)
    input  wire [3:0]  s_axi_ctrl_wstrb,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_CTRL WVALID" *)
    input  wire        s_axi_ctrl_wvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_CTRL WREADY" *)
    output wire        s_axi_ctrl_wready,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_CTRL BRESP" *)
    output wire [1:0]  s_axi_ctrl_bresp,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_CTRL BVALID" *)
    output wire        s_axi_ctrl_bvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_CTRL BREADY" *)
    input  wire        s_axi_ctrl_bready,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_CTRL ARADDR" *)
    input  wire [7:0]  s_axi_ctrl_araddr,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_CTRL ARVALID" *)
    input  wire        s_axi_ctrl_arvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_CTRL ARREADY" *)
    output wire        s_axi_ctrl_arready,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_CTRL RDATA" *)
    output wire [31:0] s_axi_ctrl_rdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_CTRL RRESP" *)
    output wire [1:0]  s_axi_ctrl_rresp,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_CTRL RVALID" *)
    output wire        s_axi_ctrl_rvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_CTRL RREADY" *)
    input  wire        s_axi_ctrl_rready,

    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_UMEM AWADDR" *)
    (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME M_AXI_UMEM, PROTOCOL AXI4, ADDR_WIDTH 32, DATA_WIDTH 32, FREQ_HZ 100000000, HAS_BRESP 1, HAS_RRESP 1, MAX_BURST_LENGTH 8, NUM_READ_OUTSTANDING 1, NUM_WRITE_OUTSTANDING 1, SUPPORTS_NARROW_BURST 0" *)
    output wire [31:0] m_axi_umem_awaddr,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_UMEM AWLEN" *)
    output wire [7:0]  m_axi_umem_awlen,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_UMEM AWSIZE" *)
    output wire [2:0]  m_axi_umem_awsize,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_UMEM AWBURST" *)
    output wire [1:0]  m_axi_umem_awburst,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_UMEM AWPROT" *)
    output wire [2:0]  m_axi_umem_awprot,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_UMEM AWCACHE" *)
    output wire [3:0]  m_axi_umem_awcache,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_UMEM AWLOCK" *)
    output wire        m_axi_umem_awlock,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_UMEM AWVALID" *)
    output wire        m_axi_umem_awvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_UMEM AWREADY" *)
    input  wire        m_axi_umem_awready,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_UMEM WDATA" *)
    output wire [31:0] m_axi_umem_wdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_UMEM WSTRB" *)
    output wire [3:0]  m_axi_umem_wstrb,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_UMEM WLAST" *)
    output wire        m_axi_umem_wlast,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_UMEM WVALID" *)
    output wire        m_axi_umem_wvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_UMEM WREADY" *)
    input  wire        m_axi_umem_wready,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_UMEM BRESP" *)
    input  wire [1:0]  m_axi_umem_bresp,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_UMEM BVALID" *)
    input  wire        m_axi_umem_bvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_UMEM BREADY" *)
    output wire        m_axi_umem_bready,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_UMEM ARADDR" *)
    output wire [31:0] m_axi_umem_araddr,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_UMEM ARLEN" *)
    output wire [7:0]  m_axi_umem_arlen,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_UMEM ARSIZE" *)
    output wire [2:0]  m_axi_umem_arsize,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_UMEM ARBURST" *)
    output wire [1:0]  m_axi_umem_arburst,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_UMEM ARPROT" *)
    output wire [2:0]  m_axi_umem_arprot,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_UMEM ARCACHE" *)
    output wire [3:0]  m_axi_umem_arcache,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_UMEM ARLOCK" *)
    output wire        m_axi_umem_arlock,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_UMEM ARVALID" *)
    output wire        m_axi_umem_arvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_UMEM ARREADY" *)
    input  wire        m_axi_umem_arready,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_UMEM RDATA" *)
    input  wire [31:0] m_axi_umem_rdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_UMEM RRESP" *)
    input  wire [1:0]  m_axi_umem_rresp,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_UMEM RLAST" *)
    input  wire        m_axi_umem_rlast,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_UMEM RVALID" *)
    input  wire        m_axi_umem_rvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_UMEM RREADY" *)
    output wire        m_axi_umem_rready,

    input  wire        uart_rx,
    output wire        uart_tx,
    input  wire        ps2_clk,
    input  wire        ps2_data,
    output wire        spi_cs_n,
    output wire        spi_sclk,
    output wire        spi_mosi,
    input  wire        spi_miso,
    output wire        irq_f2p,
    output wire [3:0]  led
);
    wire [31:0] gpio_out;
    wire [31:0] debug_timer_lo;
    wire [31:0] debug_boot_status;
    wire [7:0]  debug_ps2_data;
    wire        debug_ps2_valid;
    wire [7:0]  debug_uart_tx_char;
    wire        debug_uart_tx_valid;

    wire        npu_start_pulse;
    wire [7:0]  npu_model_id;
    wire [15:0] npu_seq_length;
    wire [31:0] npu_input_vec0;
    wire [31:0] npu_input_vec1;
    wire [31:0] npu_weight0_a;
    wire [31:0] npu_weight0_b;
    wire [31:0] npu_weight1_a;
    wire [31:0] npu_weight1_b;
    wire [31:0] npu_bias0;
    wire [31:0] npu_bias1;
    wire [31:0] umem_ctrl;
    wire [31:0] umem_base_addr;
    wire [31:0] umem_size_bytes;
    wire [31:0] umem_npu_input_offset;
    wire [31:0] umem_npu_weight_offset;
    wire [31:0] umem_npu_output_offset;
    wire [31:0] umem_gpu_fb_offset;
    wire [31:0] umem_gpu_fb_pitch;
    wire [31:0] umem_cmdq_base_offset;
    wire [31:0] umem_cmdq_size_bytes;
    wire [31:0] umem_cmdq_head;
    wire [31:0] umem_cmdq_tail;
    wire [31:0] umem_cmdq_doorbell;
    wire [31:0] cmdq_tail_shadow;
    wire [31:0] cmdq_status_shadow;
    wire        cmdq_fetch_valid;
    wire [15:0] cmdq_fetch_slot;
    wire [31:0] cmdq_fetch_offset;
    wire [31:0] cmdq_fetch_sequence;
    wire        cmdq_fetch_ready;
    wire        cmdq_desc_done;
    wire        cmdq_desc_error;
    wire [31:0] umem_fetch_status;
    wire [31:0] umem_fetch_last_araddr;
    wire [31:0] umem_fetch_last_sequence;
    wire [3:0]  umem_fetch_beat_count;
    wire [255:0] umem_fetch_desc_flat;
    wire [31:0] umem_fetch_desc_word0 = umem_fetch_desc_flat[31:0];
    wire        cmdq_decode_valid;
    wire [31:0] cmdq_decode_opcode;
    wire [31:0] cmdq_decode_flags;
    wire [31:0] cmdq_decode_src0;
    wire [31:0] cmdq_decode_src1;
    wire [31:0] cmdq_decode_src2;
    wire [31:0] cmdq_decode_dst0;
    wire [31:0] cmdq_decode_arg0;
    wire [31:0] cmdq_decode_arg1;
    wire [7:0]  cmdq_decode_model_id;
    wire [15:0] cmdq_decode_seq_length;
    wire [15:0] cmdq_decode_vertex0_xy;
    wire [15:0] cmdq_decode_vertex1_xy;
    wire [15:0] cmdq_decode_vertex2_xy;
    wire [7:0]  cmdq_decode_clear_value;
    wire [31:0] cmdq_decode_count;
    wire [31:0] cmdq_decode_error_count;
    wire        cmdq_npu_dispatch_pulse;
    wire [7:0]  cmdq_npu_model_id;
    wire [15:0] cmdq_npu_seq_length;
    wire [31:0] cmdq_npu_input_offset;
    wire [31:0] cmdq_npu_weight_offset;
    wire [31:0] cmdq_npu_output_offset;
    wire        cmdq_gpu_dispatch_pulse;
    wire [7:0]  cmdq_gpu_cmd_opcode;
    wire [15:0] cmdq_gpu_vertex0_xy;
    wire [15:0] cmdq_gpu_vertex1_xy;
    wire [15:0] cmdq_gpu_vertex2_xy;
    wire [7:0]  cmdq_gpu_clear_value;
    wire [31:0] cmdq_dispatch_status;
    wire [31:0] cmdq_dispatch_opcode;
    wire [31:0] cmdq_dispatch_npu_count;
    wire [31:0] cmdq_dispatch_gpu_count;
    wire [31:0] cmdq_dispatch_error_count;
    wire        npu_start_mux;
    wire [7:0]  npu_model_id_mux;
    wire [15:0] npu_seq_length_mux;
    wire        npu_cmd_exec_start_pulse;
    wire [7:0]  npu_cmd_exec_model_id;
    wire [15:0] npu_cmd_exec_seq_length;
    wire [31:0] npu_cmd_exec_status;
    wire [31:0] npu_cmd_exec_input_offset;
    wire [31:0] npu_cmd_exec_weight_offset;
    wire [31:0] npu_cmd_exec_output_offset;
    wire        gpu_cmd_valid_mux;
    wire [7:0]  gpu_cmd_opcode_mux;
    wire [15:0] gpu_vertex0_xy_mux;
    wire [15:0] gpu_vertex1_xy_mux;
    wire [15:0] gpu_vertex2_xy_mux;
    wire [7:0]  gpu_clear_value_mux;
    wire [31:0] umem_axi_araddr_int;
    wire [7:0]  umem_axi_arlen_int;
    wire [2:0]  umem_axi_arsize_int;
    wire [1:0]  umem_axi_arburst_int;
    wire        umem_axi_arvalid_int;
    wire        umem_axi_rready_int;
    wire        npu_busy;
    wire        npu_done;
    wire [31:0] npu_status_word;
    wire [31:0] npu_logit0;
    wire [31:0] npu_logit1;
    wire [7:0]  npu_class_id;

    wire        gpu_cmd_pulse;
    wire [7:0]  gpu_cmd_opcode;
    wire [15:0] gpu_vertex0_xy;
    wire [15:0] gpu_vertex1_xy;
    wire [15:0] gpu_vertex2_xy;
    wire [7:0]  gpu_clear_value;
    wire [4:0]  gpu_fb_row_select;
    wire        gpu_busy;
    wire        gpu_frame_done;
    wire [31:0] gpu_triangles_drawn;
    wire [31:0] gpu_frame_counter;
    wire [31:0] gpu_raster_pixels;
    wire [31:0] gpu_last_area2;
    wire [31:0] gpu_last_bbox;
    wire [31:0] gpu_fb_row_data;

    riscv_pc_soc #(
        .CLK_FREQ_HZ (100_000_000),
        .UART_BAUD   (115200),
        .BOOT_ROM_WORDS (4096),
        .SRAM_WORDS  (16384)
    ) legacy_soc_i (
        .clk      (pl_clk0),
        .resetn   (pl_resetn0),
        .uart_rx  (uart_rx),
        .uart_tx  (uart_tx),
        .ps2_clk  (ps2_clk),
        .ps2_data (ps2_data),
        .spi_cs_n (spi_cs_n),
        .spi_sclk (spi_sclk),
        .spi_mosi (spi_mosi),
        .spi_miso (spi_miso),
        .gpio_out (gpio_out),
        .debug_timer_lo (debug_timer_lo),
        .debug_boot_status (debug_boot_status),
        .debug_ps2_data (debug_ps2_data),
        .debug_ps2_valid (debug_ps2_valid),
        .debug_uart_tx_char (debug_uart_tx_char),
        .debug_uart_tx_valid (debug_uart_tx_valid)
    );

    accel_mmio_regs accel_mmio_i (
        .clk                (pl_clk0),
        .resetn             (pl_resetn0),
        .s_axi_awaddr       (s_axi_ctrl_awaddr),
        .s_axi_awvalid      (s_axi_ctrl_awvalid),
        .s_axi_awready      (s_axi_ctrl_awready),
        .s_axi_wdata        (s_axi_ctrl_wdata),
        .s_axi_wstrb        (s_axi_ctrl_wstrb),
        .s_axi_wvalid       (s_axi_ctrl_wvalid),
        .s_axi_wready       (s_axi_ctrl_wready),
        .s_axi_bresp        (s_axi_ctrl_bresp),
        .s_axi_bvalid       (s_axi_ctrl_bvalid),
        .s_axi_bready       (s_axi_ctrl_bready),
        .s_axi_araddr       (s_axi_ctrl_araddr),
        .s_axi_arvalid      (s_axi_ctrl_arvalid),
        .s_axi_arready      (s_axi_ctrl_arready),
        .s_axi_rdata        (s_axi_ctrl_rdata),
        .s_axi_rresp        (s_axi_ctrl_rresp),
        .s_axi_rvalid       (s_axi_ctrl_rvalid),
        .s_axi_rready       (s_axi_ctrl_rready),
        .npu_start_pulse    (npu_start_pulse),
        .npu_model_id       (npu_model_id),
        .npu_seq_length     (npu_seq_length),
        .npu_input_vec0     (npu_input_vec0),
        .npu_input_vec1     (npu_input_vec1),
        .npu_weight0_a      (npu_weight0_a),
        .npu_weight0_b      (npu_weight0_b),
        .npu_weight1_a      (npu_weight1_a),
        .npu_weight1_b      (npu_weight1_b),
        .npu_bias0          (npu_bias0),
        .npu_bias1          (npu_bias1),
        .umem_ctrl          (umem_ctrl),
        .umem_base_addr     (umem_base_addr),
        .umem_size_bytes    (umem_size_bytes),
        .umem_npu_input_offset (umem_npu_input_offset),
        .umem_npu_weight_offset (umem_npu_weight_offset),
        .umem_npu_output_offset (umem_npu_output_offset),
        .umem_gpu_fb_offset (umem_gpu_fb_offset),
        .umem_gpu_fb_pitch  (umem_gpu_fb_pitch),
        .umem_cmdq_base_offset (umem_cmdq_base_offset),
        .umem_cmdq_size_bytes  (umem_cmdq_size_bytes),
        .umem_cmdq_head        (umem_cmdq_head),
        .umem_cmdq_tail        (umem_cmdq_tail),
        .umem_cmdq_doorbell    (umem_cmdq_doorbell),
        .cmdq_tail_shadow_dbg  (cmdq_tail_shadow),
        .cmdq_status_shadow_dbg(cmdq_status_shadow),
        .cmdq_fetch_offset_dbg (cmdq_fetch_offset),
        .cmdq_fetch_sequence_dbg(cmdq_fetch_sequence),
        .cmdq_fetch_slot_dbg   (cmdq_fetch_slot),
        .umem_fetch_status_dbg (umem_fetch_status),
        .umem_fetch_last_araddr_dbg (umem_fetch_last_araddr),
        .umem_fetch_last_sequence_dbg (umem_fetch_last_sequence),
        .umem_fetch_beat_count_dbg (umem_fetch_beat_count),
        .umem_fetch_desc_word0_dbg (umem_fetch_desc_word0),
        .cmdq_dispatch_status_dbg (cmdq_dispatch_status),
        .cmdq_dispatch_opcode_dbg (cmdq_dispatch_opcode),
        .cmdq_dispatch_npu_count_dbg (cmdq_dispatch_npu_count),
        .cmdq_dispatch_gpu_count_dbg (cmdq_dispatch_gpu_count),
        .cmdq_dispatch_error_count_dbg (cmdq_dispatch_error_count),
        .npu_cmd_exec_status_dbg (npu_cmd_exec_status),
        .npu_cmd_exec_input_offset_dbg (npu_cmd_exec_input_offset),
        .npu_cmd_exec_output_offset_dbg (npu_cmd_exec_output_offset),
        .npu_busy           (npu_busy),
        .npu_done           (npu_done),
        .npu_status_word    (npu_status_word),
        .npu_logit0         (npu_logit0),
        .npu_logit1         (npu_logit1),
        .npu_class_id       (npu_class_id),
        .irq                (irq_f2p),
        .gpu_cmd_pulse      (gpu_cmd_pulse),
        .gpu_cmd_opcode     (gpu_cmd_opcode),
        .gpu_vertex0_xy     (gpu_vertex0_xy),
        .gpu_vertex1_xy     (gpu_vertex1_xy),
        .gpu_vertex2_xy     (gpu_vertex2_xy),
        .gpu_clear_value    (gpu_clear_value),
        .gpu_fb_row_select  (gpu_fb_row_select),
        .gpu_busy           (gpu_busy),
        .gpu_frame_done     (gpu_frame_done),
        .gpu_triangles_drawn(gpu_triangles_drawn),
        .gpu_frame_counter  (gpu_frame_counter),
        .gpu_raster_pixels  (gpu_raster_pixels),
        .gpu_last_area2     (gpu_last_area2),
        .gpu_last_bbox      (gpu_last_bbox),
        .gpu_fb_row_data    (gpu_fb_row_data),
        .legacy_boot_status (debug_boot_status),
        .legacy_gpio_out    (gpio_out)
    );

    npu_v2_stub npu_v2_i (
        .clk         (pl_clk0),
        .resetn      (pl_resetn0),
        .start       (npu_start_mux),
        .model_id    (npu_model_id_mux),
        .seq_length  (npu_seq_length_mux),
        .input_vec0  (npu_input_vec0),
        .input_vec1  (npu_input_vec1),
        .runtime_weight0_a (npu_weight0_a),
        .runtime_weight0_b (npu_weight0_b),
        .runtime_weight1_a (npu_weight1_a),
        .runtime_weight1_b (npu_weight1_b),
        .runtime_bias0 (npu_bias0),
        .runtime_bias1 (npu_bias1),
        .busy        (npu_busy),
        .done        (npu_done),
        .status_word (npu_status_word),
        .logit0      (npu_logit0),
        .logit1      (npu_logit1),
        .class_id    (npu_class_id)
    );

    gpu3d_lite_stub gpu3d_i (
        .clk             (pl_clk0),
        .resetn          (pl_resetn0),
        .cmd_valid       (gpu_cmd_valid_mux),
        .cmd_opcode      (gpu_cmd_opcode_mux),
        .vertex0_xy      (gpu_vertex0_xy_mux),
        .vertex1_xy      (gpu_vertex1_xy_mux),
        .vertex2_xy      (gpu_vertex2_xy_mux),
        .clear_value     (gpu_clear_value_mux),
        .fb_row_select   (gpu_fb_row_select),
        .busy            (gpu_busy),
        .frame_done      (gpu_frame_done),
        .triangles_drawn (gpu_triangles_drawn),
        .frame_counter   (gpu_frame_counter),
        .raster_pixels   (gpu_raster_pixels),
        .last_area2      (gpu_last_area2),
        .last_bbox       (gpu_last_bbox),
        .fb_row_data     (gpu_fb_row_data)
    );

    accel_cmdq_frontend_stub cmdq_frontend_i (
        .clk             (pl_clk0),
        .resetn          (pl_resetn0),
        .enable          (umem_ctrl[3]),
        .cmdq_base_offset(umem_cmdq_base_offset),
        .cmdq_size_bytes (umem_cmdq_size_bytes),
        .cmdq_head       (umem_cmdq_head),
        .cmdq_tail_seed  (umem_cmdq_tail),
        .cmdq_doorbell   (umem_cmdq_doorbell),
        .cmdq_tail_shadow(cmdq_tail_shadow),
        .cmdq_status     (cmdq_status_shadow),
        .fetch_valid     (cmdq_fetch_valid),
        .fetch_slot      (cmdq_fetch_slot),
        .fetch_offset    (cmdq_fetch_offset),
        .fetch_sequence  (cmdq_fetch_sequence),
        .fetch_ready     (cmdq_fetch_ready),
        .desc_done       (cmdq_desc_done),
        .desc_error      (cmdq_desc_error)
    );

    accel_umem_axi_fetch_stub umem_axi_fetch_i (
        .clk            (pl_clk0),
        .resetn         (pl_resetn0),
        .enable         (umem_ctrl[3]),
        .umem_base_addr (umem_base_addr),
        .fetch_valid    (cmdq_fetch_valid),
        .fetch_offset   (cmdq_fetch_offset),
        .fetch_sequence (cmdq_fetch_sequence),
        .fetch_ready    (cmdq_fetch_ready),
        .desc_done      (cmdq_desc_done),
        .desc_error     (cmdq_desc_error),
        .desc_status    (umem_fetch_status),
        .last_araddr    (umem_fetch_last_araddr),
        .last_sequence  (umem_fetch_last_sequence),
        .beat_count     (umem_fetch_beat_count),
        .desc_data_flat (umem_fetch_desc_flat),
        .m_axi_araddr   (umem_axi_araddr_int),
        .m_axi_arlen    (umem_axi_arlen_int),
        .m_axi_arsize   (umem_axi_arsize_int),
        .m_axi_arburst  (umem_axi_arburst_int),
        .m_axi_arvalid  (umem_axi_arvalid_int),
        .m_axi_arready  (m_axi_umem_arready),
        .m_axi_rdata    (m_axi_umem_rdata),
        .m_axi_rresp    (m_axi_umem_rresp),
        .m_axi_rlast    (m_axi_umem_rlast),
        .m_axi_rvalid   (m_axi_umem_rvalid),
        .m_axi_rready   (umem_axi_rready_int)
    );

    accel_cmdq_desc_decode_stub cmdq_decode_i (
        .clk            (pl_clk0),
        .resetn         (pl_resetn0),
        .enable         (umem_ctrl[3]),
        .desc_valid     (cmdq_desc_done),
        .desc_error     (cmdq_desc_error),
        .desc_data_flat (umem_fetch_desc_flat),
        .decode_valid   (cmdq_decode_valid),
        .desc_opcode    (cmdq_decode_opcode),
        .desc_flags     (cmdq_decode_flags),
        .desc_src0      (cmdq_decode_src0),
        .desc_src1      (cmdq_decode_src1),
        .desc_src2      (cmdq_decode_src2),
        .desc_dst0      (cmdq_decode_dst0),
        .desc_arg0      (cmdq_decode_arg0),
        .desc_arg1      (cmdq_decode_arg1),
        .npu_model_id   (cmdq_decode_model_id),
        .npu_seq_length (cmdq_decode_seq_length),
        .gpu_vertex0_xy (cmdq_decode_vertex0_xy),
        .gpu_vertex1_xy (cmdq_decode_vertex1_xy),
        .gpu_vertex2_xy (cmdq_decode_vertex2_xy),
        .gpu_clear_value(cmdq_decode_clear_value),
        .decode_count   (cmdq_decode_count),
        .error_count    (cmdq_decode_error_count)
    );

    accel_cmdq_dispatch_stub cmdq_dispatch_i (
        .clk              (pl_clk0),
        .resetn           (pl_resetn0),
        .enable           (umem_ctrl[3]),
        .decode_valid     (cmdq_decode_valid),
        .desc_opcode      (cmdq_decode_opcode),
        .desc_flags       (cmdq_decode_flags),
        .desc_src0        (cmdq_decode_src0),
        .desc_src1        (cmdq_decode_src1),
        .desc_dst0        (cmdq_decode_dst0),
        .desc_arg0        (cmdq_decode_arg0),
        .npu_model_id_in  (cmdq_decode_model_id),
        .npu_seq_length_in(cmdq_decode_seq_length),
        .gpu_vertex0_xy_in(cmdq_decode_vertex0_xy),
        .gpu_vertex1_xy_in(cmdq_decode_vertex1_xy),
        .gpu_vertex2_xy_in(cmdq_decode_vertex2_xy),
        .gpu_clear_value_in(cmdq_decode_clear_value),
        .npu_dispatch_pulse(cmdq_npu_dispatch_pulse),
        .npu_model_id_out (cmdq_npu_model_id),
        .npu_seq_length_out(cmdq_npu_seq_length),
        .npu_input_offset_out(cmdq_npu_input_offset),
        .npu_weight_offset_out(cmdq_npu_weight_offset),
        .npu_output_offset_out(cmdq_npu_output_offset),
        .gpu_dispatch_pulse(cmdq_gpu_dispatch_pulse),
        .gpu_cmd_opcode_out(cmdq_gpu_cmd_opcode),
        .gpu_vertex0_xy_out(cmdq_gpu_vertex0_xy),
        .gpu_vertex1_xy_out(cmdq_gpu_vertex1_xy),
        .gpu_vertex2_xy_out(cmdq_gpu_vertex2_xy),
        .gpu_clear_value_out(cmdq_gpu_clear_value),
        .dispatch_status  (cmdq_dispatch_status),
        .last_opcode      (cmdq_dispatch_opcode),
        .npu_dispatch_count(cmdq_dispatch_npu_count),
        .gpu_dispatch_count(cmdq_dispatch_gpu_count),
        .dispatch_error_count(cmdq_dispatch_error_count)
    );

    accel_npu_cmd_exec_stub npu_cmd_exec_i (
        .clk              (pl_clk0),
        .resetn           (pl_resetn0),
        .enable           (umem_ctrl[3]),
        .dispatch_valid   (cmdq_npu_dispatch_pulse),
        .model_id_in      (cmdq_npu_model_id),
        .seq_length_in    (cmdq_npu_seq_length),
        .input_offset_in  (cmdq_npu_input_offset),
        .weight_offset_in (cmdq_npu_weight_offset),
        .output_offset_in (cmdq_npu_output_offset),
        .npu_busy         (npu_busy),
        .npu_done         (npu_done),
        .npu_start_pulse  (npu_cmd_exec_start_pulse),
        .npu_model_id_out (npu_cmd_exec_model_id),
        .npu_seq_length_out(npu_cmd_exec_seq_length),
        .exec_status      (npu_cmd_exec_status),
        .last_input_offset(npu_cmd_exec_input_offset),
        .last_weight_offset(npu_cmd_exec_weight_offset),
        .last_output_offset(npu_cmd_exec_output_offset)
    );

    assign npu_start_mux = npu_start_pulse | npu_cmd_exec_start_pulse;
    assign npu_model_id_mux = npu_cmd_exec_start_pulse ? npu_cmd_exec_model_id : npu_model_id;
    assign npu_seq_length_mux = npu_cmd_exec_start_pulse ? npu_cmd_exec_seq_length : npu_seq_length;
    assign gpu_cmd_valid_mux = gpu_cmd_pulse | cmdq_gpu_dispatch_pulse;
    assign gpu_cmd_opcode_mux = cmdq_gpu_dispatch_pulse ? cmdq_gpu_cmd_opcode : gpu_cmd_opcode;
    assign gpu_vertex0_xy_mux = cmdq_gpu_dispatch_pulse ? cmdq_gpu_vertex0_xy : gpu_vertex0_xy;
    assign gpu_vertex1_xy_mux = cmdq_gpu_dispatch_pulse ? cmdq_gpu_vertex1_xy : gpu_vertex1_xy;
    assign gpu_vertex2_xy_mux = cmdq_gpu_dispatch_pulse ? cmdq_gpu_vertex2_xy : gpu_vertex2_xy;
    assign gpu_clear_value_mux = cmdq_gpu_dispatch_pulse ? cmdq_gpu_clear_value : gpu_clear_value;

    assign m_axi_umem_awaddr = 32'h0000_0000;
    assign m_axi_umem_awlen = 8'h00;
    assign m_axi_umem_awsize = 3'b010;
    assign m_axi_umem_awburst = 2'b01;
    assign m_axi_umem_awprot = 3'b000;
    assign m_axi_umem_awcache = 4'b0011;
    assign m_axi_umem_awlock = 1'b0;
    assign m_axi_umem_awvalid = 1'b0;
    assign m_axi_umem_wdata = 32'h0000_0000;
    assign m_axi_umem_wstrb = 4'h0;
    assign m_axi_umem_wlast = 1'b1;
    assign m_axi_umem_wvalid = 1'b0;
    assign m_axi_umem_bready = 1'b1;
    assign m_axi_umem_araddr = umem_axi_araddr_int;
    assign m_axi_umem_arlen = umem_axi_arlen_int;
    assign m_axi_umem_arsize = umem_axi_arsize_int;
    assign m_axi_umem_arburst = umem_axi_arburst_int;
    assign m_axi_umem_arprot = 3'b000;
    assign m_axi_umem_arcache = 4'b0011;
    assign m_axi_umem_arlock = 1'b0;
    assign m_axi_umem_arvalid = umem_axi_arvalid_int;
    assign m_axi_umem_rready = umem_axi_rready_int;

    assign led[0] = gpio_out[0];
    assign led[1] = debug_boot_status[0];
    assign led[2] = npu_busy;
    assign led[3] = gpu_busy;
endmodule
