module accel_cmdq_dispatch_stub (
    input  wire        clk,
    input  wire        resetn,
    input  wire        enable,
    input  wire        decode_valid,
    input  wire [31:0] desc_opcode,
    input  wire [31:0] desc_flags,
    input  wire [31:0] desc_src0,
    input  wire [31:0] desc_src1,
    input  wire [31:0] desc_dst0,
    input  wire [31:0] desc_arg0,
    input  wire [7:0]  npu_model_id_in,
    input  wire [15:0] npu_seq_length_in,
    input  wire [15:0] gpu_vertex0_xy_in,
    input  wire [15:0] gpu_vertex1_xy_in,
    input  wire [15:0] gpu_vertex2_xy_in,
    input  wire [7:0]  gpu_clear_value_in,
    output reg         npu_dispatch_pulse,
    output reg  [7:0]  npu_model_id_out,
    output reg  [15:0] npu_seq_length_out,
    output reg  [31:0] npu_input_offset_out,
    output reg  [31:0] npu_weight_offset_out,
    output reg  [31:0] npu_output_offset_out,
    output reg         gpu_dispatch_pulse,
    output reg  [7:0]  gpu_cmd_opcode_out,
    output reg  [15:0] gpu_vertex0_xy_out,
    output reg  [15:0] gpu_vertex1_xy_out,
    output reg  [15:0] gpu_vertex2_xy_out,
    output reg  [7:0]  gpu_clear_value_out,
    output reg  [31:0] dispatch_status,
    output reg  [31:0] last_opcode,
    output reg  [31:0] npu_dispatch_count,
    output reg  [31:0] gpu_dispatch_count,
    output reg  [31:0] dispatch_error_count
);
    localparam [31:0] OPCODE_NOP          = 32'h0000_0000;
    localparam [31:0] OPCODE_NPU_INFER    = 32'h0000_0001;
    localparam [31:0] OPCODE_GPU_CLEAR    = 32'h0000_0002;
    localparam [31:0] OPCODE_GPU_DRAW_TRI = 32'h0000_0003;
    localparam [31:0] STATUS_BUSY         = 32'h0000_0001;
    localparam [31:0] STATUS_ERROR        = 32'h0000_0002;
    localparam [31:0] STATUS_IDLE         = 32'h0000_0004;

    always @(posedge clk) begin
        if (!resetn) begin
            npu_dispatch_pulse <= 1'b0;
            npu_model_id_out <= 8'h00;
            npu_seq_length_out <= 16'h0000;
            npu_input_offset_out <= 32'h0000_0000;
            npu_weight_offset_out <= 32'h0000_0000;
            npu_output_offset_out <= 32'h0000_0000;
            gpu_dispatch_pulse <= 1'b0;
            gpu_cmd_opcode_out <= 8'h00;
            gpu_vertex0_xy_out <= 16'h0000;
            gpu_vertex1_xy_out <= 16'h0000;
            gpu_vertex2_xy_out <= 16'h0000;
            gpu_clear_value_out <= 8'h00;
            dispatch_status <= STATUS_IDLE;
            last_opcode <= OPCODE_NOP;
            npu_dispatch_count <= 32'h0000_0000;
            gpu_dispatch_count <= 32'h0000_0000;
            dispatch_error_count <= 32'h0000_0000;
        end else begin
            npu_dispatch_pulse <= 1'b0;
            gpu_dispatch_pulse <= 1'b0;

            if (!enable) begin
                dispatch_status <= STATUS_IDLE;
                last_opcode <= OPCODE_NOP;
                npu_dispatch_count <= 32'h0000_0000;
                gpu_dispatch_count <= 32'h0000_0000;
                dispatch_error_count <= 32'h0000_0000;
            end else if (decode_valid) begin
                dispatch_status <= STATUS_BUSY;
                last_opcode <= desc_opcode;

                case (desc_opcode)
                    OPCODE_NPU_INFER: begin
                        npu_dispatch_pulse <= 1'b1;
                        npu_model_id_out <= npu_model_id_in;
                        npu_seq_length_out <= npu_seq_length_in;
                        npu_input_offset_out <= desc_src0;
                        npu_weight_offset_out <= desc_src1;
                        npu_output_offset_out <= desc_dst0;
                        npu_dispatch_count <= npu_dispatch_count + 32'd1;
                        dispatch_status <= STATUS_IDLE;
                    end

                    OPCODE_GPU_CLEAR: begin
                        gpu_dispatch_pulse <= 1'b1;
                        gpu_cmd_opcode_out <= 8'h01;
                        gpu_clear_value_out <= desc_arg0[7:0];
                        gpu_dispatch_count <= gpu_dispatch_count + 32'd1;
                        dispatch_status <= STATUS_IDLE;
                    end

                    OPCODE_GPU_DRAW_TRI: begin
                        gpu_dispatch_pulse <= 1'b1;
                        gpu_cmd_opcode_out <= 8'h02;
                        gpu_vertex0_xy_out <= gpu_vertex0_xy_in;
                        gpu_vertex1_xy_out <= gpu_vertex1_xy_in;
                        gpu_vertex2_xy_out <= gpu_vertex2_xy_in;
                        gpu_dispatch_count <= gpu_dispatch_count + 32'd1;
                        dispatch_status <= STATUS_IDLE;
                    end

                    default: begin
                        dispatch_error_count <= dispatch_error_count + 32'd1;
                        dispatch_status <= STATUS_ERROR;
                    end
                endcase
            end else begin
                dispatch_status <= (dispatch_status == STATUS_ERROR) ? STATUS_ERROR : STATUS_IDLE;
            end
        end
    end
endmodule
