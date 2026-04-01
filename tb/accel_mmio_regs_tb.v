`timescale 1ns / 1ps

module accel_mmio_regs_tb;
    localparam [7:0] REG_ID_VERSION      = 8'h00;
    localparam [7:0] REG_CONTROL         = 8'h04;
    localparam [7:0] REG_STATUS          = 8'h08;
    localparam [7:0] REG_NPU_CFG0        = 8'h0C;
    localparam [7:0] REG_NPU_STATUS_WORD = 8'h10;
    localparam [7:0] REG_NPU_INPUT0      = 8'h14;
    localparam [7:0] REG_NPU_INPUT1      = 8'h18;
    localparam [7:0] REG_NPU_LOGIT0      = 8'h1C;
    localparam [7:0] REG_NPU_LOGIT1      = 8'h20;
    localparam [7:0] REG_NPU_CLASS       = 8'h24;
    localparam [7:0] REG_GPU_CMD         = 8'h28;
    localparam [7:0] REG_GPU_TRIANGLES   = 8'h2C;
    localparam [7:0] REG_LEGACY_BOOT     = 8'h30;
    localparam [7:0] REG_LEGACY_GPIO     = 8'h34;
    localparam [7:0] REG_IRQ_ENABLE      = 8'h38;
    localparam [7:0] REG_IRQ_STATUS      = 8'h3C;
    localparam [7:0] REG_GPU_VERTEX0     = 8'h40;
    localparam [7:0] REG_GPU_VERTEX1     = 8'h44;
    localparam [7:0] REG_GPU_VERTEX2     = 8'h48;
    localparam [7:0] REG_GPU_CLEAR_VALUE = 8'h4C;
    localparam [7:0] REG_GPU_FRAME_COUNT = 8'h50;
    localparam [7:0] REG_GPU_RASTER_PIXELS = 8'h54;
    localparam [7:0] REG_GPU_LAST_AREA2  = 8'h58;
    localparam [7:0] REG_GPU_LAST_BBOX   = 8'h5C;
    localparam [7:0] REG_GPU_FB_ROWSEL   = 8'h60;
    localparam [7:0] REG_GPU_FB_ROWDATA  = 8'h64;
    localparam [7:0] REG_NPU_WEIGHT0_A   = 8'h68;
    localparam [7:0] REG_NPU_WEIGHT0_B   = 8'h6C;
    localparam [7:0] REG_NPU_WEIGHT1_A   = 8'h70;
    localparam [7:0] REG_NPU_WEIGHT1_B   = 8'h74;
    localparam [7:0] REG_NPU_BIAS0       = 8'h78;
    localparam [7:0] REG_NPU_BIAS1       = 8'h7C;
    localparam [7:0] REG_UMEM_CTRL       = 8'h80;
    localparam [7:0] REG_UMEM_BASE       = 8'h84;
    localparam [7:0] REG_UMEM_SIZE       = 8'h88;
    localparam [7:0] REG_UMEM_NPU_INPUT  = 8'h8C;
    localparam [7:0] REG_UMEM_NPU_WEIGHT = 8'h90;
    localparam [7:0] REG_UMEM_NPU_OUTPUT = 8'h94;
    localparam [7:0] REG_UMEM_GPU_FB     = 8'h98;
    localparam [7:0] REG_UMEM_GPU_PITCH  = 8'h9C;
    localparam [7:0] REG_UMEM_CMDQ_BASE  = 8'hA0;
    localparam [7:0] REG_UMEM_CMDQ_SIZE  = 8'hA4;
    localparam [7:0] REG_UMEM_CMDQ_HEAD  = 8'hA8;
    localparam [7:0] REG_UMEM_CMDQ_TAIL  = 8'hAC;
    localparam [7:0] REG_UMEM_CMDQ_DOORBELL = 8'hB0;
    localparam [7:0] REG_UMEM_CMDQ_STATUS = 8'hB4;
    localparam [7:0] REG_CMDQ_TAIL_SHADOW = 8'hB8;
    localparam [7:0] REG_CMDQ_STATUS_SHADOW = 8'hBC;
    localparam [7:0] REG_CMDQ_FETCH_OFFSET = 8'hC0;
    localparam [7:0] REG_CMDQ_FETCH_SEQUENCE = 8'hC4;
    localparam [7:0] REG_CMDQ_FETCH_SLOT = 8'hC8;
    localparam [7:0] REG_UMEM_FETCH_STATUS = 8'hCC;
    localparam [7:0] REG_UMEM_FETCH_LAST_ARADDR = 8'hD0;
    localparam [7:0] REG_UMEM_FETCH_LAST_SEQUENCE = 8'hD4;
    localparam [7:0] REG_UMEM_FETCH_BEAT_COUNT = 8'hD8;
    localparam [7:0] REG_UMEM_FETCH_DESC_WORD0 = 8'hDC;
    localparam [7:0] REG_CMDQ_DISPATCH_STATUS = 8'hE0;
    localparam [7:0] REG_CMDQ_DISPATCH_OPCODE = 8'hE4;
    localparam [7:0] REG_CMDQ_DISPATCH_NPU_COUNT = 8'hE8;
    localparam [7:0] REG_CMDQ_DISPATCH_GPU_COUNT = 8'hEC;
    localparam [7:0] REG_CMDQ_DISPATCH_ERROR_COUNT = 8'hF0;
    localparam [7:0] REG_NPU_CMD_EXEC_STATUS = 8'hF4;
    localparam [7:0] REG_NPU_CMD_EXEC_INPUT_OFFSET = 8'hF8;
    localparam [7:0] REG_NPU_CMD_EXEC_OUTPUT_OFFSET = 8'hFC;

    localparam [31:0] EXPECT_ID_VERSION   = 32'h5A37_100A;
    localparam [31:0] EXPECT_DEFAULT_CFG0 = 32'h0008_0001;
    localparam [31:0] EXPECT_DEFAULT_IN0  = 32'h0403_0201;
    localparam [31:0] EXPECT_DEFAULT_IN1  = 32'h0000_0000;
    localparam [31:0] EXPECT_DEFAULT_W0A  = 32'h0101_0101;
    localparam [31:0] EXPECT_DEFAULT_W0B  = 32'hFFFF_FFFF;
    localparam [31:0] EXPECT_DEFAULT_W1A  = 32'hFFFF_FFFF;
    localparam [31:0] EXPECT_DEFAULT_W1B  = 32'h0101_0101;
    localparam [31:0] EXPECT_DEFAULT_GPU  = 32'h0000_0002;
    localparam [31:0] EXPECT_DEFAULT_V0   = 32'h0000_0202;
    localparam [31:0] EXPECT_DEFAULT_V1   = 32'h0000_020A;
    localparam [31:0] EXPECT_DEFAULT_V2   = 32'h0000_0A02;
    localparam [31:0] EXPECT_NPU_STATUS0  = 32'h4E00_0108;
    localparam [31:0] EXPECT_NPU_STATUS1  = 32'h4E01_0108;
    localparam [31:0] EXPECT_RT_STATUS0   = 32'h4E00_8008;
    localparam [31:0] EXPECT_RT_STATUS1   = 32'h4E01_8008;
    localparam [31:0] EXPECT_LOGIT_POS10  = 32'h0000_000A;
    localparam [31:0] EXPECT_LOGIT_NEG10  = 32'hFFFF_FFF6;
    localparam [31:0] EXPECT_LOGIT_POS20  = 32'h0000_0014;
    localparam [31:0] EXPECT_RUNTIME_W0   = 32'h0002_0002;
    localparam [31:0] EXPECT_RUNTIME_W1   = 32'h0200_0200;
    localparam [31:0] EXPECT_UMEM_BASE    = 32'h1000_0000;
    localparam [31:0] EXPECT_UMEM_SIZE    = 32'h0001_0000;
    localparam [31:0] EXPECT_UMEM_NPU_IN  = 32'h0000_0000;
    localparam [31:0] EXPECT_UMEM_NPU_W   = 32'h0000_0100;
    localparam [31:0] EXPECT_UMEM_NPU_OUT = 32'h0000_0200;
    localparam [31:0] EXPECT_UMEM_GPU_FB  = 32'h0000_1000;
    localparam [31:0] EXPECT_UMEM_PITCH   = 32'h0000_0004;
    localparam [31:0] EXPECT_UMEM_CMDQ_BASE = 32'h0000_2000;
    localparam [31:0] EXPECT_UMEM_CMDQ_SIZE = 32'h0000_0100;
    localparam [31:0] EXPECT_UMEM_CMDQ_STATUS_EMPTY = 32'h0000_0004;
    localparam [31:0] EXPECT_LEGACY_BOOT  = 32'h0000_0001;
    localparam [31:0] EXPECT_LEGACY_GPIO  = 32'hA5A5_0001;
    localparam [31:0] EXPECT_IRQ_ENABLE   = 32'h0000_0003;
    localparam [31:0] EXPECT_IRQ_NPU      = 32'h0000_0005;
    localparam [31:0] EXPECT_IRQ_GPU      = 32'h0000_0006;
    localparam [31:0] EXPECT_GPU_AREA2    = 32'h0000_0040;
    localparam [31:0] EXPECT_GPU_BBOX     = 32'h0A0A_0202;
    localparam [31:0] EXPECT_GPU_PIXELS   = 32'd45;
    localparam [31:0] EXPECT_GPU_ROW2     = 32'h0000_07FC;
    localparam [31:0] EXPECT_GPU_ROW3     = 32'h0000_03FC;
    localparam [31:0] EXPECT_GPU_ROW10    = 32'h0000_0004;

    reg clk;
    reg resetn;

    reg [7:0]  s_axi_awaddr;
    reg        s_axi_awvalid;
    wire       s_axi_awready;
    reg [31:0] s_axi_wdata;
    reg [3:0]  s_axi_wstrb;
    reg        s_axi_wvalid;
    wire       s_axi_wready;
    wire [1:0] s_axi_bresp;
    wire       s_axi_bvalid;
    reg        s_axi_bready;
    reg [7:0]  s_axi_araddr;
    reg        s_axi_arvalid;
    wire       s_axi_arready;
    wire [31:0] s_axi_rdata;
    wire [1:0]  s_axi_rresp;
    wire        s_axi_rvalid;
    reg         s_axi_rready;

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
    reg [31:0] cmdq_tail_shadow_dbg;
    reg [31:0] cmdq_status_shadow_dbg;
    reg [31:0] cmdq_fetch_offset_dbg;
    reg [31:0] cmdq_fetch_sequence_dbg;
    reg [15:0] cmdq_fetch_slot_dbg;
    reg [31:0] umem_fetch_status_dbg;
    reg [31:0] umem_fetch_last_araddr_dbg;
    reg [31:0] umem_fetch_last_sequence_dbg;
    reg [3:0]  umem_fetch_beat_count_dbg;
    reg [31:0] umem_fetch_desc_word0_dbg;
    reg [31:0] cmdq_dispatch_status_dbg;
    reg [31:0] cmdq_dispatch_opcode_dbg;
    reg [31:0] cmdq_dispatch_npu_count_dbg;
    reg [31:0] cmdq_dispatch_gpu_count_dbg;
    reg [31:0] cmdq_dispatch_error_count_dbg;
    reg [31:0] npu_cmd_exec_status_dbg;
    reg [31:0] npu_cmd_exec_input_offset_dbg;
    reg [31:0] npu_cmd_exec_output_offset_dbg;
    wire        npu_busy;
    wire        npu_done;
    wire [31:0] npu_status_word;
    wire [31:0] npu_logit0;
    wire [31:0] npu_logit1;
    wire [7:0]  npu_class_id;
    wire        irq;
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

    reg [31:0] read_data;

    accel_mmio_regs dut (
        .clk                (clk),
        .resetn             (resetn),
        .s_axi_awaddr       (s_axi_awaddr),
        .s_axi_awvalid      (s_axi_awvalid),
        .s_axi_awready      (s_axi_awready),
        .s_axi_wdata        (s_axi_wdata),
        .s_axi_wstrb        (s_axi_wstrb),
        .s_axi_wvalid       (s_axi_wvalid),
        .s_axi_wready       (s_axi_wready),
        .s_axi_bresp        (s_axi_bresp),
        .s_axi_bvalid       (s_axi_bvalid),
        .s_axi_bready       (s_axi_bready),
        .s_axi_araddr       (s_axi_araddr),
        .s_axi_arvalid      (s_axi_arvalid),
        .s_axi_arready      (s_axi_arready),
        .s_axi_rdata        (s_axi_rdata),
        .s_axi_rresp        (s_axi_rresp),
        .s_axi_rvalid       (s_axi_rvalid),
        .s_axi_rready       (s_axi_rready),
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
        .cmdq_tail_shadow_dbg  (cmdq_tail_shadow_dbg),
        .cmdq_status_shadow_dbg(cmdq_status_shadow_dbg),
        .cmdq_fetch_offset_dbg (cmdq_fetch_offset_dbg),
        .cmdq_fetch_sequence_dbg(cmdq_fetch_sequence_dbg),
        .cmdq_fetch_slot_dbg   (cmdq_fetch_slot_dbg),
        .umem_fetch_status_dbg (umem_fetch_status_dbg),
        .umem_fetch_last_araddr_dbg (umem_fetch_last_araddr_dbg),
        .umem_fetch_last_sequence_dbg (umem_fetch_last_sequence_dbg),
        .umem_fetch_beat_count_dbg (umem_fetch_beat_count_dbg),
        .umem_fetch_desc_word0_dbg (umem_fetch_desc_word0_dbg),
        .cmdq_dispatch_status_dbg (cmdq_dispatch_status_dbg),
        .cmdq_dispatch_opcode_dbg (cmdq_dispatch_opcode_dbg),
        .cmdq_dispatch_npu_count_dbg (cmdq_dispatch_npu_count_dbg),
        .cmdq_dispatch_gpu_count_dbg (cmdq_dispatch_gpu_count_dbg),
        .cmdq_dispatch_error_count_dbg (cmdq_dispatch_error_count_dbg),
        .npu_cmd_exec_status_dbg (npu_cmd_exec_status_dbg),
        .npu_cmd_exec_input_offset_dbg (npu_cmd_exec_input_offset_dbg),
        .npu_cmd_exec_output_offset_dbg (npu_cmd_exec_output_offset_dbg),
        .npu_busy           (npu_busy),
        .npu_done           (npu_done),
        .npu_status_word    (npu_status_word),
        .npu_logit0         (npu_logit0),
        .npu_logit1         (npu_logit1),
        .npu_class_id       (npu_class_id),
        .irq                (irq),
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
        .legacy_boot_status (32'h0000_0001),
        .legacy_gpio_out    (32'hA5A5_0001)
    );

    npu_v2_stub npu_v2_i (
        .clk         (clk),
        .resetn      (resetn),
        .start       (npu_start_pulse),
        .model_id    (npu_model_id),
        .seq_length  (npu_seq_length),
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
        .clk             (clk),
        .resetn          (resetn),
        .cmd_valid       (gpu_cmd_pulse),
        .cmd_opcode      (gpu_cmd_opcode),
        .vertex0_xy      (gpu_vertex0_xy),
        .vertex1_xy      (gpu_vertex1_xy),
        .vertex2_xy      (gpu_vertex2_xy),
        .clear_value     (gpu_clear_value),
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

    always #5 clk = ~clk;

    task automatic axi_write;
        input [7:0] addr;
        input [31:0] data;
        begin
            @(posedge clk);
            s_axi_awaddr <= addr;
            s_axi_awvalid <= 1'b1;
            s_axi_wdata <= data;
            s_axi_wstrb <= 4'hF;
            s_axi_wvalid <= 1'b1;
            s_axi_bready <= 1'b1;

            wait (s_axi_bvalid);
            @(posedge clk);
            s_axi_awvalid <= 1'b0;
            s_axi_wvalid <= 1'b0;
            s_axi_bready <= 1'b0;
        end
    endtask

    task automatic axi_read;
        input [7:0] addr;
        output [31:0] data;
        begin
            @(posedge clk);
            s_axi_araddr <= addr;
            s_axi_arvalid <= 1'b1;
            s_axi_rready <= 1'b1;

            wait (s_axi_rvalid);
            data = s_axi_rdata;
            @(posedge clk);
            s_axi_arvalid <= 1'b0;
            s_axi_rready <= 1'b0;
        end
    endtask

    task automatic expect_read;
        input [7:0] addr;
        input [31:0] expect;
        input [1023:0] label;
        begin
            axi_read(addr, read_data);
            if (read_data !== expect) begin
                $display("FAIL: %0s mismatch. got=%08x expect=%08x", label, read_data, expect);
                $finish;
            end
        end
    endtask

    initial begin
        clk = 1'b0;
        resetn = 1'b0;
        s_axi_awaddr = 8'h00;
        s_axi_awvalid = 1'b0;
        s_axi_wdata = 32'h0000_0000;
        s_axi_wstrb = 4'h0;
        s_axi_wvalid = 1'b0;
        s_axi_bready = 1'b0;
        s_axi_araddr = 8'h00;
        s_axi_arvalid = 1'b0;
        s_axi_rready = 1'b0;
        read_data = 32'h0000_0000;
        cmdq_tail_shadow_dbg = 32'h0000_0000;
        cmdq_status_shadow_dbg = 32'h0000_0004;
        cmdq_fetch_offset_dbg = 32'h0000_0000;
        cmdq_fetch_sequence_dbg = 32'h0000_0000;
        cmdq_fetch_slot_dbg = 16'h0000;
        umem_fetch_status_dbg = 32'h0000_0004;
        umem_fetch_last_araddr_dbg = 32'h0000_0000;
        umem_fetch_last_sequence_dbg = 32'h0000_0000;
        umem_fetch_beat_count_dbg = 4'h0;
        umem_fetch_desc_word0_dbg = 32'h0000_0000;
        cmdq_dispatch_status_dbg = 32'h0000_0004;
        cmdq_dispatch_opcode_dbg = 32'h0000_0000;
        cmdq_dispatch_npu_count_dbg = 32'h0000_0000;
        cmdq_dispatch_gpu_count_dbg = 32'h0000_0000;
        cmdq_dispatch_error_count_dbg = 32'h0000_0000;
        npu_cmd_exec_status_dbg = 32'h0000_0004;
        npu_cmd_exec_input_offset_dbg = 32'h0000_0000;
        npu_cmd_exec_output_offset_dbg = 32'h0000_0000;

        repeat (8) @(posedge clk);
        resetn = 1'b1;
        repeat (4) @(posedge clk);

        expect_read(REG_ID_VERSION, EXPECT_ID_VERSION, "ID/version");
        expect_read(REG_NPU_CFG0, EXPECT_DEFAULT_CFG0, "default NPU cfg");
        expect_read(REG_NPU_INPUT0, EXPECT_DEFAULT_IN0, "default NPU input0");
        expect_read(REG_NPU_INPUT1, EXPECT_DEFAULT_IN1, "default NPU input1");
        expect_read(REG_NPU_WEIGHT0_A, EXPECT_DEFAULT_W0A, "default NPU weight0_a");
        expect_read(REG_NPU_WEIGHT0_B, EXPECT_DEFAULT_W0B, "default NPU weight0_b");
        expect_read(REG_NPU_WEIGHT1_A, EXPECT_DEFAULT_W1A, "default NPU weight1_a");
        expect_read(REG_NPU_WEIGHT1_B, EXPECT_DEFAULT_W1B, "default NPU weight1_b");
        expect_read(REG_NPU_BIAS0, 32'h0000_0000, "default NPU bias0");
        expect_read(REG_NPU_BIAS1, 32'h0000_0000, "default NPU bias1");
        expect_read(REG_UMEM_CTRL, 32'h0000_0000, "default UMEM ctrl");
        expect_read(REG_UMEM_BASE, EXPECT_UMEM_BASE, "default UMEM base");
        expect_read(REG_UMEM_SIZE, EXPECT_UMEM_SIZE, "default UMEM size");
        expect_read(REG_UMEM_NPU_INPUT, EXPECT_UMEM_NPU_IN, "default UMEM NPU input offset");
        expect_read(REG_UMEM_NPU_WEIGHT, EXPECT_UMEM_NPU_W, "default UMEM NPU weight offset");
        expect_read(REG_UMEM_NPU_OUTPUT, EXPECT_UMEM_NPU_OUT, "default UMEM NPU output offset");
        expect_read(REG_UMEM_GPU_FB, EXPECT_UMEM_GPU_FB, "default UMEM GPU fb offset");
        expect_read(REG_UMEM_GPU_PITCH, EXPECT_UMEM_PITCH, "default UMEM GPU pitch");
        expect_read(REG_UMEM_CMDQ_BASE, EXPECT_UMEM_CMDQ_BASE, "default UMEM command queue base");
        expect_read(REG_UMEM_CMDQ_SIZE, EXPECT_UMEM_CMDQ_SIZE, "default UMEM command queue size");
        expect_read(REG_UMEM_CMDQ_HEAD, 32'h0000_0000, "default UMEM command queue head");
        expect_read(REG_UMEM_CMDQ_TAIL, 32'h0000_0000, "default UMEM command queue tail");
        expect_read(REG_UMEM_CMDQ_DOORBELL, 32'h0000_0000, "default UMEM command queue doorbell");
        expect_read(REG_UMEM_CMDQ_STATUS, EXPECT_UMEM_CMDQ_STATUS_EMPTY, "default UMEM command queue status");
        expect_read(REG_CMDQ_TAIL_SHADOW, 32'h0000_0000, "default command queue tail shadow");
        expect_read(REG_CMDQ_STATUS_SHADOW, 32'h0000_0004, "default command queue status shadow");
        expect_read(REG_CMDQ_FETCH_OFFSET, 32'h0000_0000, "default command queue fetch offset");
        expect_read(REG_CMDQ_FETCH_SEQUENCE, 32'h0000_0000, "default command queue fetch sequence");
        expect_read(REG_CMDQ_FETCH_SLOT, 32'h0000_0000, "default command queue fetch slot");
        expect_read(REG_UMEM_FETCH_STATUS, 32'h0000_0004, "default unified-memory fetch status");
        expect_read(REG_UMEM_FETCH_LAST_ARADDR, 32'h0000_0000, "default unified-memory fetch ARADDR");
        expect_read(REG_UMEM_FETCH_LAST_SEQUENCE, 32'h0000_0000, "default unified-memory fetch sequence");
        expect_read(REG_UMEM_FETCH_BEAT_COUNT, 32'h0000_0000, "default unified-memory fetch beat count");
        expect_read(REG_UMEM_FETCH_DESC_WORD0, 32'h0000_0000, "default unified-memory fetch desc word0");
        expect_read(REG_CMDQ_DISPATCH_STATUS, 32'h0000_0004, "default command queue dispatch status");
        expect_read(REG_CMDQ_DISPATCH_OPCODE, 32'h0000_0000, "default command queue dispatch opcode");
        expect_read(REG_CMDQ_DISPATCH_NPU_COUNT, 32'h0000_0000, "default command queue dispatch NPU count");
        expect_read(REG_CMDQ_DISPATCH_GPU_COUNT, 32'h0000_0000, "default command queue dispatch GPU count");
        expect_read(REG_CMDQ_DISPATCH_ERROR_COUNT, 32'h0000_0000, "default command queue dispatch error count");
        expect_read(REG_NPU_CMD_EXEC_STATUS, 32'h0000_0004, "default NPU command exec status");
        expect_read(REG_NPU_CMD_EXEC_INPUT_OFFSET, 32'h0000_0000, "default NPU command exec input offset");
        expect_read(REG_NPU_CMD_EXEC_OUTPUT_OFFSET, 32'h0000_0000, "default NPU command exec output offset");
        expect_read(REG_GPU_CMD, EXPECT_DEFAULT_GPU, "default GPU cmd");
        expect_read(REG_LEGACY_BOOT, EXPECT_LEGACY_BOOT, "legacy boot snapshot");
        expect_read(REG_LEGACY_GPIO, EXPECT_LEGACY_GPIO, "legacy gpio snapshot");
        expect_read(REG_IRQ_ENABLE, 32'h0000_0000, "default IRQ enable");
        expect_read(REG_IRQ_STATUS, 32'h0000_0000, "default IRQ status");
        expect_read(REG_GPU_VERTEX0, EXPECT_DEFAULT_V0, "default GPU vertex0");
        expect_read(REG_GPU_VERTEX1, EXPECT_DEFAULT_V1, "default GPU vertex1");
        expect_read(REG_GPU_VERTEX2, EXPECT_DEFAULT_V2, "default GPU vertex2");
        expect_read(REG_GPU_CLEAR_VALUE, 32'h0000_0000, "default GPU clear value");
        expect_read(REG_GPU_FRAME_COUNT, 32'h0000_0000, "default GPU frame count");
        expect_read(REG_GPU_RASTER_PIXELS, 32'h0000_0000, "default GPU pixel count");
        expect_read(REG_GPU_LAST_AREA2, 32'h0000_0000, "default GPU area2");
        expect_read(REG_GPU_LAST_BBOX, 32'h0000_0000, "default GPU bbox");
        expect_read(REG_GPU_FB_ROWSEL, 32'h0000_0000, "default GPU row select");
        expect_read(REG_GPU_FB_ROWDATA, 32'h0000_0000, "default GPU row data");

        axi_write(REG_IRQ_ENABLE, EXPECT_IRQ_ENABLE);
        expect_read(REG_IRQ_ENABLE, EXPECT_IRQ_ENABLE, "IRQ enable");

        axi_write(REG_NPU_CFG0, EXPECT_DEFAULT_CFG0);
        axi_write(REG_NPU_INPUT0, 32'h0403_0201);
        axi_write(REG_NPU_INPUT1, 32'h0000_0000);
        axi_write(REG_CONTROL, 32'h0000_0001);
        wait (npu_busy);
        wait (!npu_busy);

        axi_read(REG_STATUS, read_data);
        if ((read_data & 32'h0000_0002) == 0) begin
            $display("FAIL: NPU done sticky bit was not set. status=%08x", read_data);
            $finish;
        end

        if (!irq) begin
            $display("FAIL: IRQ line was not asserted for NPU sample0.");
            $finish;
        end

        expect_read(REG_IRQ_STATUS, EXPECT_IRQ_NPU, "IRQ status sample0");
        expect_read(REG_NPU_STATUS_WORD, EXPECT_NPU_STATUS0, "NPU status sample0");
        expect_read(REG_NPU_LOGIT0, EXPECT_LOGIT_POS10, "NPU logit0 sample0");
        expect_read(REG_NPU_LOGIT1, EXPECT_LOGIT_NEG10, "NPU logit1 sample0");
        expect_read(REG_NPU_CLASS, 32'h0000_0000, "NPU class sample0");

        axi_write(REG_STATUS, 32'h0000_0001);
        axi_read(REG_STATUS, read_data);
        if ((read_data & 32'h0000_0002) != 0) begin
            $display("FAIL: NPU done sticky bit did not clear after sample0. status=%08x", read_data);
            $finish;
        end

        if (irq) begin
            $display("FAIL: IRQ line did not deassert after clearing NPU sample0.");
            $finish;
        end

        expect_read(REG_IRQ_STATUS, 32'h0000_0000, "IRQ status clear after sample0");

        axi_write(REG_NPU_INPUT0, 32'h0000_0000);
        axi_write(REG_NPU_INPUT1, 32'h0403_0201);
        axi_write(REG_CONTROL, 32'h0000_0001);
        wait (npu_busy);
        wait (!npu_busy);

        axi_read(REG_STATUS, read_data);
        if ((read_data & 32'h0000_0002) == 0) begin
            $display("FAIL: NPU done sticky bit was not set for sample1. status=%08x", read_data);
            $finish;
        end

        if (!irq) begin
            $display("FAIL: IRQ line was not asserted for NPU sample1.");
            $finish;
        end

        expect_read(REG_IRQ_STATUS, EXPECT_IRQ_NPU, "IRQ status sample1");
        expect_read(REG_NPU_STATUS_WORD, EXPECT_NPU_STATUS1, "NPU status sample1");
        expect_read(REG_NPU_LOGIT0, EXPECT_LOGIT_NEG10, "NPU logit0 sample1");
        expect_read(REG_NPU_LOGIT1, EXPECT_LOGIT_POS10, "NPU logit1 sample1");
        expect_read(REG_NPU_CLASS, 32'h0000_0001, "NPU class sample1");

        axi_write(REG_STATUS, 32'h0000_0001);
        axi_read(REG_STATUS, read_data);
        if ((read_data & 32'h0000_0002) != 0) begin
            $display("FAIL: NPU done sticky bit did not clear after sample1. status=%08x", read_data);
            $finish;
        end

        if (irq) begin
            $display("FAIL: IRQ line did not deassert after clearing NPU sample1.");
            $finish;
        end

        expect_read(REG_IRQ_STATUS, 32'h0000_0000, "IRQ status clear after sample1");

        axi_write(REG_NPU_WEIGHT0_A, EXPECT_RUNTIME_W0);
        axi_write(REG_NPU_WEIGHT0_B, EXPECT_RUNTIME_W0);
        axi_write(REG_NPU_WEIGHT1_A, EXPECT_RUNTIME_W1);
        axi_write(REG_NPU_WEIGHT1_B, EXPECT_RUNTIME_W1);
        axi_write(REG_NPU_BIAS0, 32'h0000_0000);
        axi_write(REG_NPU_BIAS1, 32'h0000_0000);
        axi_write(REG_UMEM_CTRL, 32'h0000_0007);
        axi_write(REG_UMEM_BASE, 32'h2000_0000);
        axi_write(REG_UMEM_SIZE, 32'h0002_0000);
        axi_write(REG_UMEM_NPU_INPUT, 32'h0000_0040);
        axi_write(REG_UMEM_NPU_WEIGHT, 32'h0000_0080);
        axi_write(REG_UMEM_NPU_OUTPUT, 32'h0000_00C0);
        axi_write(REG_UMEM_GPU_FB, 32'h0000_2000);
        axi_write(REG_UMEM_GPU_PITCH, 32'h0000_0004);
        axi_write(REG_UMEM_CMDQ_BASE, 32'h0000_3000);
        axi_write(REG_UMEM_CMDQ_SIZE, 32'h0000_0200);
        axi_write(REG_UMEM_CMDQ_HEAD, 32'h0000_0003);
        axi_write(REG_UMEM_CMDQ_TAIL, 32'h0000_0001);
        axi_write(REG_UMEM_CMDQ_DOORBELL, 32'h0000_0002);
        expect_read(REG_NPU_WEIGHT0_A, EXPECT_RUNTIME_W0, "runtime weight0_a");
        expect_read(REG_NPU_WEIGHT0_B, EXPECT_RUNTIME_W0, "runtime weight0_b");
        expect_read(REG_NPU_WEIGHT1_A, EXPECT_RUNTIME_W1, "runtime weight1_a");
        expect_read(REG_NPU_WEIGHT1_B, EXPECT_RUNTIME_W1, "runtime weight1_b");
        expect_read(REG_NPU_BIAS0, 32'h0000_0000, "runtime bias0");
        expect_read(REG_NPU_BIAS1, 32'h0000_0000, "runtime bias1");
        expect_read(REG_UMEM_CTRL, 32'h0000_0007, "runtime UMEM ctrl");
        expect_read(REG_UMEM_BASE, 32'h2000_0000, "runtime UMEM base");
        expect_read(REG_UMEM_SIZE, 32'h0002_0000, "runtime UMEM size");
        expect_read(REG_UMEM_NPU_INPUT, 32'h0000_0040, "runtime UMEM NPU input offset");
        expect_read(REG_UMEM_NPU_WEIGHT, 32'h0000_0080, "runtime UMEM NPU weight offset");
        expect_read(REG_UMEM_NPU_OUTPUT, 32'h0000_00C0, "runtime UMEM NPU output offset");
        expect_read(REG_UMEM_GPU_FB, 32'h0000_2000, "runtime UMEM GPU fb offset");
        expect_read(REG_UMEM_GPU_PITCH, 32'h0000_0004, "runtime UMEM GPU pitch");
        expect_read(REG_UMEM_CMDQ_BASE, 32'h0000_3000, "runtime UMEM command queue base");
        expect_read(REG_UMEM_CMDQ_SIZE, 32'h0000_0200, "runtime UMEM command queue size");
        expect_read(REG_UMEM_CMDQ_HEAD, 32'h0000_0003, "runtime UMEM command queue head");
        expect_read(REG_UMEM_CMDQ_TAIL, 32'h0000_0001, "runtime UMEM command queue tail");
        expect_read(REG_UMEM_CMDQ_DOORBELL, 32'h0000_0002, "runtime UMEM command queue doorbell");
        expect_read(REG_UMEM_CMDQ_STATUS, 32'h0000_0000, "runtime UMEM command queue non-empty status");

        cmdq_tail_shadow_dbg = 32'h0000_0001;
        cmdq_status_shadow_dbg = 32'h0001_0001;
        cmdq_fetch_offset_dbg = 32'h1000_2020;
        cmdq_fetch_sequence_dbg = 32'h0000_0001;
        cmdq_fetch_slot_dbg = 16'h0001;
        umem_fetch_status_dbg = 32'h0000_0004;
        umem_fetch_last_araddr_dbg = 32'h1000_2020;
        umem_fetch_last_sequence_dbg = 32'h0000_0001;
        umem_fetch_beat_count_dbg = 4'h8;
        umem_fetch_desc_word0_dbg = 32'h0000_0001;
        cmdq_dispatch_status_dbg = 32'h0000_0004;
        cmdq_dispatch_opcode_dbg = 32'h0000_0001;
        cmdq_dispatch_npu_count_dbg = 32'h0000_0001;
        cmdq_dispatch_gpu_count_dbg = 32'h0000_0002;
        cmdq_dispatch_error_count_dbg = 32'h0000_0000;
        npu_cmd_exec_status_dbg = 32'h0001_8004;
        npu_cmd_exec_input_offset_dbg = 32'h0000_0400;
        npu_cmd_exec_output_offset_dbg = 32'h0000_0480;
        expect_read(REG_CMDQ_TAIL_SHADOW, 32'h0000_0001, "runtime command queue tail shadow");
        expect_read(REG_CMDQ_STATUS_SHADOW, 32'h0001_0001, "runtime command queue status shadow");
        expect_read(REG_CMDQ_FETCH_OFFSET, 32'h1000_2020, "runtime command queue fetch offset");
        expect_read(REG_CMDQ_FETCH_SEQUENCE, 32'h0000_0001, "runtime command queue fetch sequence");
        expect_read(REG_CMDQ_FETCH_SLOT, 32'h0000_0001, "runtime command queue fetch slot");
        expect_read(REG_UMEM_FETCH_STATUS, 32'h0000_0004, "runtime unified-memory fetch status");
        expect_read(REG_UMEM_FETCH_LAST_ARADDR, 32'h1000_2020, "runtime unified-memory fetch ARADDR");
        expect_read(REG_UMEM_FETCH_LAST_SEQUENCE, 32'h0000_0001, "runtime unified-memory fetch sequence");
        expect_read(REG_UMEM_FETCH_BEAT_COUNT, 32'h0000_0008, "runtime unified-memory fetch beat count");
        expect_read(REG_UMEM_FETCH_DESC_WORD0, 32'h0000_0001, "runtime unified-memory fetch desc word0");
        expect_read(REG_CMDQ_DISPATCH_STATUS, 32'h0000_0004, "runtime command queue dispatch status");
        expect_read(REG_CMDQ_DISPATCH_OPCODE, 32'h0000_0001, "runtime command queue dispatch opcode");
        expect_read(REG_CMDQ_DISPATCH_NPU_COUNT, 32'h0000_0001, "runtime command queue dispatch NPU count");
        expect_read(REG_CMDQ_DISPATCH_GPU_COUNT, 32'h0000_0002, "runtime command queue dispatch GPU count");
        expect_read(REG_CMDQ_DISPATCH_ERROR_COUNT, 32'h0000_0000, "runtime command queue dispatch error count");
        expect_read(REG_NPU_CMD_EXEC_STATUS, 32'h0001_8004, "runtime NPU command exec status");
        expect_read(REG_NPU_CMD_EXEC_INPUT_OFFSET, 32'h0000_0400, "runtime NPU command exec input offset");
        expect_read(REG_NPU_CMD_EXEC_OUTPUT_OFFSET, 32'h0000_0480, "runtime NPU command exec output offset");

        axi_write(REG_UMEM_CMDQ_TAIL, 32'h0000_0003);
        expect_read(REG_UMEM_CMDQ_STATUS, EXPECT_UMEM_CMDQ_STATUS_EMPTY, "runtime UMEM command queue empty status");

        axi_write(REG_NPU_CFG0, 32'h0008_0080);
        axi_write(REG_NPU_INPUT0, 32'h0002_0001);
        axi_write(REG_NPU_INPUT1, 32'h0004_0003);
        axi_write(REG_CONTROL, 32'h0000_0001);
        wait (npu_busy);
        wait (!npu_busy);

        axi_read(REG_STATUS, read_data);
        if ((read_data & 32'h0000_0002) == 0) begin
            $display("FAIL: runtime-model NPU done sticky bit was not set. status=%08x", read_data);
            $finish;
        end

        if (!irq) begin
            $display("FAIL: IRQ line was not asserted for runtime-model sample0.");
            $finish;
        end

        expect_read(REG_IRQ_STATUS, EXPECT_IRQ_NPU, "IRQ status runtime sample0");
        expect_read(REG_NPU_STATUS_WORD, EXPECT_RT_STATUS0, "NPU status runtime sample0");
        expect_read(REG_NPU_LOGIT0, EXPECT_LOGIT_POS20, "NPU logit0 runtime sample0");
        expect_read(REG_NPU_LOGIT1, 32'h0000_0000, "NPU logit1 runtime sample0");
        expect_read(REG_NPU_CLASS, 32'h0000_0000, "NPU class runtime sample0");

        axi_write(REG_STATUS, 32'h0000_0001);
        axi_read(REG_STATUS, read_data);
        if ((read_data & 32'h0000_0002) != 0) begin
            $display("FAIL: runtime-model NPU done sticky did not clear after sample0. status=%08x", read_data);
            $finish;
        end

        if (irq) begin
            $display("FAIL: IRQ line did not deassert after clearing runtime-model sample0.");
            $finish;
        end

        expect_read(REG_IRQ_STATUS, 32'h0000_0000, "IRQ status clear after runtime sample0");

        axi_write(REG_NPU_INPUT0, 32'h0200_0100);
        axi_write(REG_NPU_INPUT1, 32'h0400_0300);
        axi_write(REG_CONTROL, 32'h0000_0001);
        wait (npu_busy);
        wait (!npu_busy);

        axi_read(REG_STATUS, read_data);
        if ((read_data & 32'h0000_0002) == 0) begin
            $display("FAIL: runtime-model NPU done sticky bit was not set for sample1. status=%08x", read_data);
            $finish;
        end

        if (!irq) begin
            $display("FAIL: IRQ line was not asserted for runtime-model sample1.");
            $finish;
        end

        expect_read(REG_IRQ_STATUS, EXPECT_IRQ_NPU, "IRQ status runtime sample1");
        expect_read(REG_NPU_STATUS_WORD, EXPECT_RT_STATUS1, "NPU status runtime sample1");
        expect_read(REG_NPU_LOGIT0, 32'h0000_0000, "NPU logit0 runtime sample1");
        expect_read(REG_NPU_LOGIT1, EXPECT_LOGIT_POS20, "NPU logit1 runtime sample1");
        expect_read(REG_NPU_CLASS, 32'h0000_0001, "NPU class runtime sample1");

        axi_write(REG_STATUS, 32'h0000_0001);
        axi_read(REG_STATUS, read_data);
        if ((read_data & 32'h0000_0002) != 0) begin
            $display("FAIL: runtime-model NPU done sticky did not clear after sample1. status=%08x", read_data);
            $finish;
        end

        if (irq) begin
            $display("FAIL: IRQ line did not deassert after clearing runtime-model sample1.");
            $finish;
        end

        expect_read(REG_IRQ_STATUS, 32'h0000_0000, "IRQ status clear after runtime sample1");

        axi_write(REG_GPU_CLEAR_VALUE, 32'h0000_0000);
        axi_write(REG_GPU_CMD, 32'h0000_0001);
        axi_write(REG_CONTROL, 32'h0000_0002);
        wait (gpu_busy);
        wait (!gpu_busy);

        axi_read(REG_STATUS, read_data);
        if ((read_data & 32'h0000_0008) == 0) begin
            $display("FAIL: GPU done sticky bit was not set after clear. status=%08x", read_data);
            $finish;
        end

        if (!irq) begin
            $display("FAIL: IRQ line was not asserted for GPU clear.");
            $finish;
        end

        expect_read(REG_IRQ_STATUS, EXPECT_IRQ_GPU, "IRQ status gpu clear");
        expect_read(REG_GPU_FRAME_COUNT, 32'h0000_0001, "GPU frame count after clear");
        expect_read(REG_GPU_TRIANGLES, 32'h0000_0000, "GPU triangles after clear");
        expect_read(REG_GPU_RASTER_PIXELS, 32'h0000_0000, "GPU pixels after clear");
        expect_read(REG_GPU_LAST_AREA2, 32'h0000_0000, "GPU area2 after clear");
        expect_read(REG_GPU_LAST_BBOX, 32'h0000_0000, "GPU bbox after clear");
        axi_write(REG_GPU_FB_ROWSEL, 32'h0000_0002);
        expect_read(REG_GPU_FB_ROWDATA, 32'h0000_0000, "GPU framebuffer row2 after clear");

        axi_write(REG_STATUS, 32'h0000_0002);
        axi_read(REG_STATUS, read_data);
        if ((read_data & 32'h0000_0008) != 0) begin
            $display("FAIL: GPU done sticky bit did not clear after clear. status=%08x", read_data);
            $finish;
        end

        if (irq) begin
            $display("FAIL: IRQ line did not deassert after clearing GPU clear.");
            $finish;
        end

        expect_read(REG_IRQ_STATUS, 32'h0000_0000, "IRQ status clear after gpu clear");

        axi_write(REG_GPU_VERTEX0, EXPECT_DEFAULT_V0);
        axi_write(REG_GPU_VERTEX1, EXPECT_DEFAULT_V1);
        axi_write(REG_GPU_VERTEX2, EXPECT_DEFAULT_V2);
        axi_write(REG_GPU_CMD, 32'h0000_0002);
        axi_write(REG_CONTROL, 32'h0000_0002);
        wait (gpu_busy);
        wait (!gpu_busy);

        axi_read(REG_STATUS, read_data);
        if ((read_data & 32'h0000_0008) == 0) begin
            $display("FAIL: GPU done sticky bit was not set after draw. status=%08x", read_data);
            $finish;
        end

        if (!irq) begin
            $display("FAIL: IRQ line was not asserted for GPU draw.");
            $finish;
        end

        expect_read(REG_IRQ_STATUS, EXPECT_IRQ_GPU, "IRQ status gpu draw");
        expect_read(REG_GPU_TRIANGLES, 32'h0000_0001, "GPU triangles after draw");
        expect_read(REG_GPU_FRAME_COUNT, 32'h0000_0002, "GPU frame count after draw");
        expect_read(REG_GPU_RASTER_PIXELS, EXPECT_GPU_PIXELS, "GPU pixels after draw");
        expect_read(REG_GPU_LAST_AREA2, EXPECT_GPU_AREA2, "GPU area2 after draw");
        expect_read(REG_GPU_LAST_BBOX, EXPECT_GPU_BBOX, "GPU bbox after draw");

        axi_write(REG_GPU_FB_ROWSEL, 32'h0000_0002);
        expect_read(REG_GPU_FB_ROWDATA, EXPECT_GPU_ROW2, "GPU framebuffer row2 after draw");
        axi_write(REG_GPU_FB_ROWSEL, 32'h0000_0003);
        expect_read(REG_GPU_FB_ROWDATA, EXPECT_GPU_ROW3, "GPU framebuffer row3 after draw");
        axi_write(REG_GPU_FB_ROWSEL, 32'h0000_000A);
        expect_read(REG_GPU_FB_ROWDATA, EXPECT_GPU_ROW10, "GPU framebuffer row10 after draw");
        axi_write(REG_GPU_FB_ROWSEL, 32'h0000_000B);
        expect_read(REG_GPU_FB_ROWDATA, 32'h0000_0000, "GPU framebuffer row11 after draw");

        axi_write(REG_STATUS, 32'h0000_0002);
        axi_read(REG_STATUS, read_data);
        if ((read_data & 32'h0000_0008) != 0) begin
            $display("FAIL: GPU done sticky bit did not clear after draw. status=%08x", read_data);
            $finish;
        end

        if (irq) begin
            $display("FAIL: IRQ line did not deassert after clearing GPU draw.");
            $finish;
        end

        expect_read(REG_IRQ_STATUS, 32'h0000_0000, "IRQ status clear after gpu draw");

        $display("PASS: accel mmio regression completed.");
        $finish;
    end
endmodule
