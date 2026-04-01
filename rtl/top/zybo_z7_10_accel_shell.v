module zybo_z7_10_accel_shell (
    input  wire       clk,
    input  wire       resetn,
    input  wire       uart_rx,
    output wire       uart_tx,
    input  wire       ps2_clk,
    input  wire       ps2_data,
    output wire       spi_cs_n,
    output wire       spi_sclk,
    output wire       spi_mosi,
    input  wire       spi_miso,
    output wire [3:0] led
);
    wire [31:0] gpio_out;
    wire [31:0] debug_timer_lo;
    wire [31:0] debug_boot_status;
    wire [7:0]  debug_ps2_data;
    wire        debug_ps2_valid;
    wire [7:0]  debug_uart_tx_char;
    wire        debug_uart_tx_valid;

    wire        npu_busy;
    wire        npu_done;
    wire [31:0] npu_status_word;
    wire [31:0] npu_logit0;
    wire [31:0] npu_logit1;
    wire [7:0]  npu_class_id;
    wire [31:0] npu_weight0_a;
    wire [31:0] npu_weight0_b;
    wire [31:0] npu_weight1_a;
    wire [31:0] npu_weight1_b;
    wire [31:0] npu_bias0;
    wire [31:0] npu_bias1;
    wire        gpu_busy;
    wire        gpu_frame_done;
    wire [31:0] gpu_triangles_drawn;
    wire [31:0] gpu_frame_counter;
    wire [31:0] gpu_raster_pixels;
    wire [31:0] gpu_last_area2;
    wire [31:0] gpu_last_bbox;
    wire [31:0] gpu_fb_row_data;

    // Legacy subsystem kept alive so we can reuse UART/SPI/PS2/boot regressions
    // while the real Zynq PS + AXI platform is being brought up.
    riscv_pc_soc #(
        .CLK_FREQ_HZ (100_000_000),
        .UART_BAUD   (115200),
        .BOOT_ROM_WORDS (4096),
        .SRAM_WORDS  (16384)
    ) legacy_soc_i (
        .clk      (clk),
        .resetn   (resetn),
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

    npu_v2_stub npu_v2_i (
        .clk         (clk),
        .resetn      (resetn),
        .start       (1'b0),
        .model_id    (8'h01),
        .seq_length  (16'd8),
        .input_vec0  (32'h04030201),
        .input_vec1  (32'h00000000),
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

    assign npu_weight0_a = 32'h01010101;
    assign npu_weight0_b = 32'hFFFFFFFF;
    assign npu_weight1_a = 32'hFFFFFFFF;
    assign npu_weight1_b = 32'h01010101;
    assign npu_bias0 = 32'h00000000;
    assign npu_bias1 = 32'h00000000;

    gpu3d_lite_stub gpu3d_i (
        .clk             (clk),
        .resetn          (resetn),
        .cmd_valid       (1'b0),
        .cmd_opcode      (8'h02),
        .vertex0_xy      (16'h0202),
        .vertex1_xy      (16'h020A),
        .vertex2_xy      (16'h0A02),
        .clear_value     (8'h00),
        .fb_row_select   (5'd0),
        .busy            (gpu_busy),
        .frame_done      (gpu_frame_done),
        .triangles_drawn (gpu_triangles_drawn),
        .frame_counter   (gpu_frame_counter),
        .raster_pixels   (gpu_raster_pixels),
        .last_area2      (gpu_last_area2),
        .last_bbox       (gpu_last_bbox),
        .fb_row_data     (gpu_fb_row_data)
    );

    assign led[0] = gpio_out[0];
    assign led[1] = debug_boot_status[0];
    assign led[2] = npu_busy;
    assign led[3] = gpu_busy;
endmodule
