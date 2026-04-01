module accel_mmio_regs #(
    parameter integer ADDR_WIDTH = 8
) (
    input  wire                  clk,
    input  wire                  resetn,
    input  wire [ADDR_WIDTH-1:0] s_axi_awaddr,
    input  wire                  s_axi_awvalid,
    output reg                   s_axi_awready,
    input  wire [31:0]           s_axi_wdata,
    input  wire [3:0]            s_axi_wstrb,
    input  wire                  s_axi_wvalid,
    output reg                   s_axi_wready,
    output reg  [1:0]            s_axi_bresp,
    output reg                   s_axi_bvalid,
    input  wire                  s_axi_bready,
    input  wire [ADDR_WIDTH-1:0] s_axi_araddr,
    input  wire                  s_axi_arvalid,
    output reg                   s_axi_arready,
    output reg  [31:0]           s_axi_rdata,
    output reg  [1:0]            s_axi_rresp,
    output reg                   s_axi_rvalid,
    input  wire                  s_axi_rready,
    output reg                   npu_start_pulse,
    output reg  [7:0]            npu_model_id,
    output reg  [15:0]           npu_seq_length,
    output reg  [31:0]           npu_input_vec0,
    output reg  [31:0]           npu_input_vec1,
    output reg  [31:0]           npu_weight0_a,
    output reg  [31:0]           npu_weight0_b,
    output reg  [31:0]           npu_weight1_a,
    output reg  [31:0]           npu_weight1_b,
    output reg  [31:0]           npu_bias0,
    output reg  [31:0]           npu_bias1,
    output reg  [31:0]           umem_ctrl,
    output reg  [31:0]           umem_base_addr,
    output reg  [31:0]           umem_size_bytes,
    output reg  [31:0]           umem_npu_input_offset,
    output reg  [31:0]           umem_npu_weight_offset,
    output reg  [31:0]           umem_npu_output_offset,
    output reg  [31:0]           umem_gpu_fb_offset,
    output reg  [31:0]           umem_gpu_fb_pitch,
    output reg  [31:0]           umem_cmdq_base_offset,
    output reg  [31:0]           umem_cmdq_size_bytes,
    output reg  [31:0]           umem_cmdq_head,
    output reg  [31:0]           umem_cmdq_tail,
    output reg  [31:0]           umem_cmdq_doorbell,
    input  wire [31:0]           cmdq_tail_shadow_dbg,
    input  wire [31:0]           cmdq_status_shadow_dbg,
    input  wire [31:0]           cmdq_fetch_offset_dbg,
    input  wire [31:0]           cmdq_fetch_sequence_dbg,
    input  wire [15:0]           cmdq_fetch_slot_dbg,
    input  wire [31:0]           umem_fetch_status_dbg,
    input  wire [31:0]           umem_fetch_last_araddr_dbg,
    input  wire [31:0]           umem_fetch_last_sequence_dbg,
    input  wire [3:0]            umem_fetch_beat_count_dbg,
    input  wire [31:0]           umem_fetch_desc_word0_dbg,
    input  wire [31:0]           cmdq_dispatch_status_dbg,
    input  wire [31:0]           cmdq_dispatch_opcode_dbg,
    input  wire [31:0]           cmdq_dispatch_npu_count_dbg,
    input  wire [31:0]           cmdq_dispatch_gpu_count_dbg,
    input  wire [31:0]           cmdq_dispatch_error_count_dbg,
    input  wire [31:0]           npu_cmd_exec_status_dbg,
    input  wire [31:0]           npu_cmd_exec_input_offset_dbg,
    input  wire [31:0]           npu_cmd_exec_output_offset_dbg,
    input  wire                  npu_busy,
    input  wire                  npu_done,
    input  wire [31:0]           npu_status_word,
    input  wire [31:0]           npu_logit0,
    input  wire [31:0]           npu_logit1,
    input  wire [7:0]            npu_class_id,
    output wire                  irq,
    output reg                   gpu_cmd_pulse,
    output reg  [7:0]            gpu_cmd_opcode,
    output reg  [15:0]           gpu_vertex0_xy,
    output reg  [15:0]           gpu_vertex1_xy,
    output reg  [15:0]           gpu_vertex2_xy,
    output reg  [7:0]            gpu_clear_value,
    output reg  [4:0]            gpu_fb_row_select,
    input  wire                  gpu_busy,
    input  wire                  gpu_frame_done,
    input  wire [31:0]           gpu_triangles_drawn,
    input  wire [31:0]           gpu_frame_counter,
    input  wire [31:0]           gpu_raster_pixels,
    input  wire [31:0]           gpu_last_area2,
    input  wire [31:0]           gpu_last_bbox,
    input  wire [31:0]           gpu_fb_row_data,
    input  wire [31:0]           legacy_boot_status,
    input  wire [31:0]           legacy_gpio_out
);
    localparam [31:0] REG_ID_VERSION = 32'h5A37_100A;

    reg                  aw_captured;
    reg [ADDR_WIDTH-1:0] awaddr_reg;
    reg                  w_captured;
    reg [31:0]           wdata_reg;
    reg [3:0]            wstrb_reg;
    reg [31:0]           control_shadow;
    reg                  npu_done_sticky;
    reg                  gpu_done_sticky;
    reg [1:0]            irq_enable;

    function [31:0] reg_read_data;
        input [ADDR_WIDTH-1:0] addr;
        begin
            case (addr[ADDR_WIDTH-1:2])
                6'h00: reg_read_data = REG_ID_VERSION;
                6'h01: reg_read_data = control_shadow;
                6'h02: reg_read_data = {28'h0, gpu_done_sticky, gpu_busy, npu_done_sticky, npu_busy};
                6'h03: reg_read_data = {npu_seq_length, 8'h00, npu_model_id};
                6'h04: reg_read_data = npu_status_word;
                6'h05: reg_read_data = npu_input_vec0;
                6'h06: reg_read_data = npu_input_vec1;
                6'h07: reg_read_data = npu_logit0;
                6'h08: reg_read_data = npu_logit1;
                6'h09: reg_read_data = {24'h0, npu_class_id};
                6'h0A: reg_read_data = {24'h0, gpu_cmd_opcode};
                6'h0B: reg_read_data = gpu_triangles_drawn;
                6'h0C: reg_read_data = legacy_boot_status;
                6'h0D: reg_read_data = legacy_gpio_out;
                6'h0E: reg_read_data = {30'h0, irq_enable[1], irq_enable[0]};
                6'h0F: reg_read_data = {29'h0, irq, gpu_done_sticky, npu_done_sticky};
                6'h10: reg_read_data = {16'h0000, gpu_vertex0_xy};
                6'h11: reg_read_data = {16'h0000, gpu_vertex1_xy};
                6'h12: reg_read_data = {16'h0000, gpu_vertex2_xy};
                6'h13: reg_read_data = {24'h000000, gpu_clear_value};
                6'h14: reg_read_data = gpu_frame_counter;
                6'h15: reg_read_data = gpu_raster_pixels;
                6'h16: reg_read_data = gpu_last_area2;
                6'h17: reg_read_data = gpu_last_bbox;
                6'h18: reg_read_data = {27'h0000000, gpu_fb_row_select};
                6'h19: reg_read_data = gpu_fb_row_data;
                6'h1A: reg_read_data = npu_weight0_a;
                6'h1B: reg_read_data = npu_weight0_b;
                6'h1C: reg_read_data = npu_weight1_a;
                6'h1D: reg_read_data = npu_weight1_b;
                6'h1E: reg_read_data = npu_bias0;
                6'h1F: reg_read_data = npu_bias1;
                6'h20: reg_read_data = umem_ctrl;
                6'h21: reg_read_data = umem_base_addr;
                6'h22: reg_read_data = umem_size_bytes;
                6'h23: reg_read_data = umem_npu_input_offset;
                6'h24: reg_read_data = umem_npu_weight_offset;
                6'h25: reg_read_data = umem_npu_output_offset;
                6'h26: reg_read_data = umem_gpu_fb_offset;
                6'h27: reg_read_data = umem_gpu_fb_pitch;
                6'h28: reg_read_data = umem_cmdq_base_offset;
                6'h29: reg_read_data = umem_cmdq_size_bytes;
                6'h2A: reg_read_data = umem_cmdq_head;
                6'h2B: reg_read_data = umem_cmdq_tail;
                6'h2C: reg_read_data = umem_cmdq_doorbell;
                6'h2D: reg_read_data = {29'h0, (umem_cmdq_head == umem_cmdq_tail), 2'b00};
                6'h2E: reg_read_data = cmdq_tail_shadow_dbg;
                6'h2F: reg_read_data = cmdq_status_shadow_dbg;
                6'h30: reg_read_data = cmdq_fetch_offset_dbg;
                6'h31: reg_read_data = cmdq_fetch_sequence_dbg;
                6'h32: reg_read_data = {16'h0000, cmdq_fetch_slot_dbg};
                6'h33: reg_read_data = umem_fetch_status_dbg;
                6'h34: reg_read_data = umem_fetch_last_araddr_dbg;
                6'h35: reg_read_data = umem_fetch_last_sequence_dbg;
                6'h36: reg_read_data = {28'h0000000, umem_fetch_beat_count_dbg};
                6'h37: reg_read_data = umem_fetch_desc_word0_dbg;
                6'h38: reg_read_data = cmdq_dispatch_status_dbg;
                6'h39: reg_read_data = cmdq_dispatch_opcode_dbg;
                6'h3A: reg_read_data = cmdq_dispatch_npu_count_dbg;
                6'h3B: reg_read_data = cmdq_dispatch_gpu_count_dbg;
                6'h3C: reg_read_data = cmdq_dispatch_error_count_dbg;
                6'h3D: reg_read_data = npu_cmd_exec_status_dbg;
                6'h3E: reg_read_data = npu_cmd_exec_input_offset_dbg;
                6'h3F: reg_read_data = npu_cmd_exec_output_offset_dbg;
                default: reg_read_data = 32'h0000_0000;
            endcase
        end
    endfunction

    wire do_write = aw_captured && w_captured && !s_axi_bvalid;
    assign irq = (npu_done_sticky && irq_enable[0]) || (gpu_done_sticky && irq_enable[1]);

    always @(posedge clk) begin
        if (!resetn) begin
            s_axi_awready <= 1'b0;
            s_axi_wready <= 1'b0;
            s_axi_bresp <= 2'b00;
            s_axi_bvalid <= 1'b0;
            s_axi_arready <= 1'b0;
            s_axi_rdata <= 32'h0000_0000;
            s_axi_rresp <= 2'b00;
            s_axi_rvalid <= 1'b0;
            aw_captured <= 1'b0;
            awaddr_reg <= {ADDR_WIDTH{1'b0}};
            w_captured <= 1'b0;
            wdata_reg <= 32'h0000_0000;
            wstrb_reg <= 4'h0;
            control_shadow <= 32'h0000_0000;
            npu_start_pulse <= 1'b0;
            npu_model_id <= 8'h01;
            npu_seq_length <= 16'd8;
            npu_input_vec0 <= 32'h0403_0201;
            npu_input_vec1 <= 32'h0000_0000;
            npu_weight0_a <= 32'h01010101;
            npu_weight0_b <= 32'hFFFFFFFF;
            npu_weight1_a <= 32'hFFFFFFFF;
            npu_weight1_b <= 32'h01010101;
            npu_bias0 <= 32'h0000_0000;
            npu_bias1 <= 32'h0000_0000;
            umem_ctrl <= 32'h0000_0000;
            umem_base_addr <= 32'h1000_0000;
            umem_size_bytes <= 32'h0001_0000;
            umem_npu_input_offset <= 32'h0000_0000;
            umem_npu_weight_offset <= 32'h0000_0100;
            umem_npu_output_offset <= 32'h0000_0200;
            umem_gpu_fb_offset <= 32'h0000_1000;
            umem_gpu_fb_pitch <= 32'h0000_0004;
            umem_cmdq_base_offset <= 32'h0000_2000;
            umem_cmdq_size_bytes <= 32'h0000_0100;
            umem_cmdq_head <= 32'h0000_0000;
            umem_cmdq_tail <= 32'h0000_0000;
            umem_cmdq_doorbell <= 32'h0000_0000;
            gpu_cmd_pulse <= 1'b0;
            gpu_cmd_opcode <= 8'h02;
            gpu_vertex0_xy <= 16'h0202;
            gpu_vertex1_xy <= 16'h020A;
            gpu_vertex2_xy <= 16'h0A02;
            gpu_clear_value <= 8'h00;
            gpu_fb_row_select <= 5'd0;
            npu_done_sticky <= 1'b0;
            gpu_done_sticky <= 1'b0;
            irq_enable <= 2'b00;
        end else begin
            s_axi_awready <= 1'b0;
            s_axi_wready <= 1'b0;
            s_axi_arready <= 1'b0;
            npu_start_pulse <= 1'b0;
            gpu_cmd_pulse <= 1'b0;

            if (npu_done) begin
                npu_done_sticky <= 1'b1;
            end

            if (gpu_frame_done) begin
                gpu_done_sticky <= 1'b1;
            end

            if (!aw_captured && s_axi_awvalid) begin
                aw_captured <= 1'b1;
                awaddr_reg <= s_axi_awaddr;
                s_axi_awready <= 1'b1;
            end

            if (!w_captured && s_axi_wvalid) begin
                w_captured <= 1'b1;
                wdata_reg <= s_axi_wdata;
                wstrb_reg <= s_axi_wstrb;
                s_axi_wready <= 1'b1;
            end

            if (do_write) begin
                s_axi_bvalid <= 1'b1;
                s_axi_bresp <= 2'b00;
                aw_captured <= 1'b0;
                w_captured <= 1'b0;

                case (awaddr_reg[ADDR_WIDTH-1:2])
                    6'h01: begin
                        if (wstrb_reg[0]) begin
                            control_shadow[7:0] <= wdata_reg[7:0];
                            if (wdata_reg[0]) begin
                                npu_start_pulse <= 1'b1;
                            end
                            if (wdata_reg[1]) begin
                                gpu_cmd_pulse <= 1'b1;
                            end
                        end
                        if (wstrb_reg[1]) control_shadow[15:8] <= wdata_reg[15:8];
                        if (wstrb_reg[2]) control_shadow[23:16] <= wdata_reg[23:16];
                        if (wstrb_reg[3]) control_shadow[31:24] <= wdata_reg[31:24];
                    end
                    6'h02: begin
                        if (wstrb_reg[0] && wdata_reg[0]) npu_done_sticky <= 1'b0;
                        if (wstrb_reg[0] && wdata_reg[1]) gpu_done_sticky <= 1'b0;
                    end
                    6'h03: begin
                        if (wstrb_reg[0]) npu_model_id <= wdata_reg[7:0];
                        if (wstrb_reg[2]) npu_seq_length[7:0] <= wdata_reg[23:16];
                        if (wstrb_reg[3]) npu_seq_length[15:8] <= wdata_reg[31:24];
                    end
                    6'h05: begin
                        if (wstrb_reg[0]) npu_input_vec0[7:0] <= wdata_reg[7:0];
                        if (wstrb_reg[1]) npu_input_vec0[15:8] <= wdata_reg[15:8];
                        if (wstrb_reg[2]) npu_input_vec0[23:16] <= wdata_reg[23:16];
                        if (wstrb_reg[3]) npu_input_vec0[31:24] <= wdata_reg[31:24];
                    end
                    6'h06: begin
                        if (wstrb_reg[0]) npu_input_vec1[7:0] <= wdata_reg[7:0];
                        if (wstrb_reg[1]) npu_input_vec1[15:8] <= wdata_reg[15:8];
                        if (wstrb_reg[2]) npu_input_vec1[23:16] <= wdata_reg[23:16];
                        if (wstrb_reg[3]) npu_input_vec1[31:24] <= wdata_reg[31:24];
                    end
                    6'h1A: begin
                        if (wstrb_reg[0]) npu_weight0_a[7:0] <= wdata_reg[7:0];
                        if (wstrb_reg[1]) npu_weight0_a[15:8] <= wdata_reg[15:8];
                        if (wstrb_reg[2]) npu_weight0_a[23:16] <= wdata_reg[23:16];
                        if (wstrb_reg[3]) npu_weight0_a[31:24] <= wdata_reg[31:24];
                    end
                    6'h1B: begin
                        if (wstrb_reg[0]) npu_weight0_b[7:0] <= wdata_reg[7:0];
                        if (wstrb_reg[1]) npu_weight0_b[15:8] <= wdata_reg[15:8];
                        if (wstrb_reg[2]) npu_weight0_b[23:16] <= wdata_reg[23:16];
                        if (wstrb_reg[3]) npu_weight0_b[31:24] <= wdata_reg[31:24];
                    end
                    6'h1C: begin
                        if (wstrb_reg[0]) npu_weight1_a[7:0] <= wdata_reg[7:0];
                        if (wstrb_reg[1]) npu_weight1_a[15:8] <= wdata_reg[15:8];
                        if (wstrb_reg[2]) npu_weight1_a[23:16] <= wdata_reg[23:16];
                        if (wstrb_reg[3]) npu_weight1_a[31:24] <= wdata_reg[31:24];
                    end
                    6'h1D: begin
                        if (wstrb_reg[0]) npu_weight1_b[7:0] <= wdata_reg[7:0];
                        if (wstrb_reg[1]) npu_weight1_b[15:8] <= wdata_reg[15:8];
                        if (wstrb_reg[2]) npu_weight1_b[23:16] <= wdata_reg[23:16];
                        if (wstrb_reg[3]) npu_weight1_b[31:24] <= wdata_reg[31:24];
                    end
                    6'h1E: begin
                        if (wstrb_reg[0]) npu_bias0[7:0] <= wdata_reg[7:0];
                        if (wstrb_reg[1]) npu_bias0[15:8] <= wdata_reg[15:8];
                        if (wstrb_reg[2]) npu_bias0[23:16] <= wdata_reg[23:16];
                        if (wstrb_reg[3]) npu_bias0[31:24] <= wdata_reg[31:24];
                    end
                    6'h1F: begin
                        if (wstrb_reg[0]) npu_bias1[7:0] <= wdata_reg[7:0];
                        if (wstrb_reg[1]) npu_bias1[15:8] <= wdata_reg[15:8];
                        if (wstrb_reg[2]) npu_bias1[23:16] <= wdata_reg[23:16];
                        if (wstrb_reg[3]) npu_bias1[31:24] <= wdata_reg[31:24];
                    end
                    6'h20: begin
                        if (wstrb_reg[0]) umem_ctrl[7:0] <= wdata_reg[7:0];
                        if (wstrb_reg[1]) umem_ctrl[15:8] <= wdata_reg[15:8];
                        if (wstrb_reg[2]) umem_ctrl[23:16] <= wdata_reg[23:16];
                        if (wstrb_reg[3]) umem_ctrl[31:24] <= wdata_reg[31:24];
                    end
                    6'h21: begin
                        if (wstrb_reg[0]) umem_base_addr[7:0] <= wdata_reg[7:0];
                        if (wstrb_reg[1]) umem_base_addr[15:8] <= wdata_reg[15:8];
                        if (wstrb_reg[2]) umem_base_addr[23:16] <= wdata_reg[23:16];
                        if (wstrb_reg[3]) umem_base_addr[31:24] <= wdata_reg[31:24];
                    end
                    6'h22: begin
                        if (wstrb_reg[0]) umem_size_bytes[7:0] <= wdata_reg[7:0];
                        if (wstrb_reg[1]) umem_size_bytes[15:8] <= wdata_reg[15:8];
                        if (wstrb_reg[2]) umem_size_bytes[23:16] <= wdata_reg[23:16];
                        if (wstrb_reg[3]) umem_size_bytes[31:24] <= wdata_reg[31:24];
                    end
                    6'h23: begin
                        if (wstrb_reg[0]) umem_npu_input_offset[7:0] <= wdata_reg[7:0];
                        if (wstrb_reg[1]) umem_npu_input_offset[15:8] <= wdata_reg[15:8];
                        if (wstrb_reg[2]) umem_npu_input_offset[23:16] <= wdata_reg[23:16];
                        if (wstrb_reg[3]) umem_npu_input_offset[31:24] <= wdata_reg[31:24];
                    end
                    6'h24: begin
                        if (wstrb_reg[0]) umem_npu_weight_offset[7:0] <= wdata_reg[7:0];
                        if (wstrb_reg[1]) umem_npu_weight_offset[15:8] <= wdata_reg[15:8];
                        if (wstrb_reg[2]) umem_npu_weight_offset[23:16] <= wdata_reg[23:16];
                        if (wstrb_reg[3]) umem_npu_weight_offset[31:24] <= wdata_reg[31:24];
                    end
                    6'h25: begin
                        if (wstrb_reg[0]) umem_npu_output_offset[7:0] <= wdata_reg[7:0];
                        if (wstrb_reg[1]) umem_npu_output_offset[15:8] <= wdata_reg[15:8];
                        if (wstrb_reg[2]) umem_npu_output_offset[23:16] <= wdata_reg[23:16];
                        if (wstrb_reg[3]) umem_npu_output_offset[31:24] <= wdata_reg[31:24];
                    end
                    6'h26: begin
                        if (wstrb_reg[0]) umem_gpu_fb_offset[7:0] <= wdata_reg[7:0];
                        if (wstrb_reg[1]) umem_gpu_fb_offset[15:8] <= wdata_reg[15:8];
                        if (wstrb_reg[2]) umem_gpu_fb_offset[23:16] <= wdata_reg[23:16];
                        if (wstrb_reg[3]) umem_gpu_fb_offset[31:24] <= wdata_reg[31:24];
                    end
                    6'h27: begin
                        if (wstrb_reg[0]) umem_gpu_fb_pitch[7:0] <= wdata_reg[7:0];
                        if (wstrb_reg[1]) umem_gpu_fb_pitch[15:8] <= wdata_reg[15:8];
                        if (wstrb_reg[2]) umem_gpu_fb_pitch[23:16] <= wdata_reg[23:16];
                        if (wstrb_reg[3]) umem_gpu_fb_pitch[31:24] <= wdata_reg[31:24];
                    end
                    6'h28: begin
                        if (wstrb_reg[0]) umem_cmdq_base_offset[7:0] <= wdata_reg[7:0];
                        if (wstrb_reg[1]) umem_cmdq_base_offset[15:8] <= wdata_reg[15:8];
                        if (wstrb_reg[2]) umem_cmdq_base_offset[23:16] <= wdata_reg[23:16];
                        if (wstrb_reg[3]) umem_cmdq_base_offset[31:24] <= wdata_reg[31:24];
                    end
                    6'h29: begin
                        if (wstrb_reg[0]) umem_cmdq_size_bytes[7:0] <= wdata_reg[7:0];
                        if (wstrb_reg[1]) umem_cmdq_size_bytes[15:8] <= wdata_reg[15:8];
                        if (wstrb_reg[2]) umem_cmdq_size_bytes[23:16] <= wdata_reg[23:16];
                        if (wstrb_reg[3]) umem_cmdq_size_bytes[31:24] <= wdata_reg[31:24];
                    end
                    6'h2A: begin
                        if (wstrb_reg[0]) umem_cmdq_head[7:0] <= wdata_reg[7:0];
                        if (wstrb_reg[1]) umem_cmdq_head[15:8] <= wdata_reg[15:8];
                        if (wstrb_reg[2]) umem_cmdq_head[23:16] <= wdata_reg[23:16];
                        if (wstrb_reg[3]) umem_cmdq_head[31:24] <= wdata_reg[31:24];
                    end
                    6'h2B: begin
                        if (wstrb_reg[0]) umem_cmdq_tail[7:0] <= wdata_reg[7:0];
                        if (wstrb_reg[1]) umem_cmdq_tail[15:8] <= wdata_reg[15:8];
                        if (wstrb_reg[2]) umem_cmdq_tail[23:16] <= wdata_reg[23:16];
                        if (wstrb_reg[3]) umem_cmdq_tail[31:24] <= wdata_reg[31:24];
                    end
                    6'h2C: begin
                        if (wstrb_reg[0]) umem_cmdq_doorbell[7:0] <= wdata_reg[7:0];
                        if (wstrb_reg[1]) umem_cmdq_doorbell[15:8] <= wdata_reg[15:8];
                        if (wstrb_reg[2]) umem_cmdq_doorbell[23:16] <= wdata_reg[23:16];
                        if (wstrb_reg[3]) umem_cmdq_doorbell[31:24] <= wdata_reg[31:24];
                    end
                    6'h0A: begin
                        if (wstrb_reg[0]) gpu_cmd_opcode <= wdata_reg[7:0];
                    end
                    6'h0E: begin
                        if (wstrb_reg[0]) begin
                            irq_enable[0] <= wdata_reg[0];
                            irq_enable[1] <= wdata_reg[1];
                        end
                    end
                    6'h10: begin
                        if (wstrb_reg[0]) gpu_vertex0_xy[7:0] <= wdata_reg[7:0];
                        if (wstrb_reg[1]) gpu_vertex0_xy[15:8] <= wdata_reg[15:8];
                    end
                    6'h11: begin
                        if (wstrb_reg[0]) gpu_vertex1_xy[7:0] <= wdata_reg[7:0];
                        if (wstrb_reg[1]) gpu_vertex1_xy[15:8] <= wdata_reg[15:8];
                    end
                    6'h12: begin
                        if (wstrb_reg[0]) gpu_vertex2_xy[7:0] <= wdata_reg[7:0];
                        if (wstrb_reg[1]) gpu_vertex2_xy[15:8] <= wdata_reg[15:8];
                    end
                    6'h13: begin
                        if (wstrb_reg[0]) gpu_clear_value <= wdata_reg[7:0];
                    end
                    6'h18: begin
                        if (wstrb_reg[0]) gpu_fb_row_select <= wdata_reg[4:0];
                    end
                    default: begin
                    end
                endcase
            end

            if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
            end

            if (!s_axi_rvalid && s_axi_arvalid) begin
                s_axi_arready <= 1'b1;
                s_axi_rvalid <= 1'b1;
                s_axi_rresp <= 2'b00;
                s_axi_rdata <= reg_read_data(s_axi_araddr);
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end
endmodule
