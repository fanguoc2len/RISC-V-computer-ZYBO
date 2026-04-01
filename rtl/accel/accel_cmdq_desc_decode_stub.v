module accel_cmdq_desc_decode_stub (
    input  wire        clk,
    input  wire        resetn,
    input  wire        enable,
    input  wire        desc_valid,
    input  wire        desc_error,
    input  wire [255:0] desc_data_flat,
    output reg         decode_valid,
    output reg  [31:0] desc_opcode,
    output reg  [31:0] desc_flags,
    output reg  [31:0] desc_src0,
    output reg  [31:0] desc_src1,
    output reg  [31:0] desc_src2,
    output reg  [31:0] desc_dst0,
    output reg  [31:0] desc_arg0,
    output reg  [31:0] desc_arg1,
    output reg  [7:0]  npu_model_id,
    output reg  [15:0] npu_seq_length,
    output reg  [15:0] gpu_vertex0_xy,
    output reg  [15:0] gpu_vertex1_xy,
    output reg  [15:0] gpu_vertex2_xy,
    output reg  [7:0]  gpu_clear_value,
    output reg  [31:0] decode_count,
    output reg  [31:0] error_count
);
    always @(posedge clk) begin
        if (!resetn) begin
            decode_valid <= 1'b0;
            desc_opcode <= 32'h0000_0000;
            desc_flags <= 32'h0000_0000;
            desc_src0 <= 32'h0000_0000;
            desc_src1 <= 32'h0000_0000;
            desc_src2 <= 32'h0000_0000;
            desc_dst0 <= 32'h0000_0000;
            desc_arg0 <= 32'h0000_0000;
            desc_arg1 <= 32'h0000_0000;
            npu_model_id <= 8'h00;
            npu_seq_length <= 16'h0000;
            gpu_vertex0_xy <= 16'h0000;
            gpu_vertex1_xy <= 16'h0000;
            gpu_vertex2_xy <= 16'h0000;
            gpu_clear_value <= 8'h00;
            decode_count <= 32'h0000_0000;
            error_count <= 32'h0000_0000;
        end else begin
            decode_valid <= 1'b0;

            if (enable && desc_valid) begin
                desc_opcode <= desc_data_flat[31:0];
                desc_flags <= desc_data_flat[63:32];
                desc_src0 <= desc_data_flat[95:64];
                desc_src1 <= desc_data_flat[127:96];
                desc_src2 <= desc_data_flat[159:128];
                desc_dst0 <= desc_data_flat[191:160];
                desc_arg0 <= desc_data_flat[223:192];
                desc_arg1 <= desc_data_flat[255:224];
                npu_model_id <= desc_data_flat[39:32];
                npu_seq_length <= desc_data_flat[207:192];
                gpu_vertex0_xy <= desc_data_flat[79:64];
                gpu_vertex1_xy <= desc_data_flat[111:96];
                gpu_vertex2_xy <= desc_data_flat[143:128];
                gpu_clear_value <= desc_data_flat[199:192];

                if (desc_error) begin
                    error_count <= error_count + 32'd1;
                end else begin
                    decode_valid <= 1'b1;
                    decode_count <= decode_count + 32'd1;
                end
            end
        end
    end
endmodule
