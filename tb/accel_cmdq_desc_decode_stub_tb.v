`timescale 1ns / 1ps

module accel_cmdq_desc_decode_stub_tb;
    reg clk;
    reg resetn;
    reg enable;
    reg desc_valid;
    reg desc_error;
    reg [255:0] desc_data_flat;
    wire decode_valid;
    wire [31:0] desc_opcode;
    wire [31:0] desc_flags;
    wire [31:0] desc_src0;
    wire [31:0] desc_src1;
    wire [31:0] desc_src2;
    wire [31:0] desc_dst0;
    wire [31:0] desc_arg0;
    wire [31:0] desc_arg1;
    wire [7:0]  npu_model_id;
    wire [15:0] npu_seq_length;
    wire [15:0] gpu_vertex0_xy;
    wire [15:0] gpu_vertex1_xy;
    wire [15:0] gpu_vertex2_xy;
    wire [7:0]  gpu_clear_value;
    wire [31:0] decode_count;
    wire [31:0] error_count;

    accel_cmdq_desc_decode_stub dut (
        .clk(clk),
        .resetn(resetn),
        .enable(enable),
        .desc_valid(desc_valid),
        .desc_error(desc_error),
        .desc_data_flat(desc_data_flat),
        .decode_valid(decode_valid),
        .desc_opcode(desc_opcode),
        .desc_flags(desc_flags),
        .desc_src0(desc_src0),
        .desc_src1(desc_src1),
        .desc_src2(desc_src2),
        .desc_dst0(desc_dst0),
        .desc_arg0(desc_arg0),
        .desc_arg1(desc_arg1),
        .npu_model_id(npu_model_id),
        .npu_seq_length(npu_seq_length),
        .gpu_vertex0_xy(gpu_vertex0_xy),
        .gpu_vertex1_xy(gpu_vertex1_xy),
        .gpu_vertex2_xy(gpu_vertex2_xy),
        .gpu_clear_value(gpu_clear_value),
        .decode_count(decode_count),
        .error_count(error_count)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 1'b0;
        resetn = 1'b0;
        enable = 1'b0;
        desc_valid = 1'b0;
        desc_error = 1'b0;
        desc_data_flat = 256'h0;

        repeat (6) @(posedge clk);
        resetn = 1'b1;
        enable = 1'b1;

        @(posedge clk);
        desc_data_flat = {
            32'h0000_0000,
            32'h0000_0000,
            32'h0000_1000,
            32'h0000_0A02,
            32'h0000_020A,
            32'h0000_0202,
            32'h0000_0000,
            32'h0000_0003
        };
        desc_valid = 1'b1;
        @(posedge clk);
        desc_valid = 1'b0;

        if (!decode_valid) begin
            $display("FAIL: decode_valid did not pulse for GPU_DRAW_TRI.");
            $finish;
        end

        if (desc_opcode !== 32'h0000_0003 || gpu_vertex0_xy !== 16'h0202 ||
            gpu_vertex1_xy !== 16'h020A || gpu_vertex2_xy !== 16'h0A02) begin
            $display("FAIL: GPU descriptor decode mismatch.");
            $finish;
        end

        if (decode_count !== 32'h0000_0001 || error_count !== 32'h0000_0000) begin
            $display("FAIL: unexpected counters after GPU decode.");
            $finish;
        end

        @(posedge clk);
        desc_data_flat = {
            32'h0000_0000,
            32'h0000_0008,
            32'h0000_0200,
            32'h0000_0000,
            32'h0000_0100,
            32'h0000_0000,
            32'h0000_0080,
            32'h0000_0001
        };
        desc_valid = 1'b1;
        @(posedge clk);
        desc_valid = 1'b0;

        if (!decode_valid) begin
            $display("FAIL: decode_valid did not pulse for NPU_INFER.");
            $finish;
        end

        if (desc_opcode !== 32'h0000_0001 || npu_model_id !== 8'h80 ||
            npu_seq_length !== 16'h0008 || desc_dst0 !== 32'h0000_0200) begin
            $display("FAIL: NPU descriptor decode mismatch.");
            $finish;
        end

        if (decode_count !== 32'h0000_0002 || error_count !== 32'h0000_0000) begin
            $display("FAIL: unexpected counters after NPU decode.");
            $finish;
        end

        @(posedge clk);
        desc_data_flat = {
            32'h0000_0000,
            32'h0000_0001,
            32'h0000_1000,
            32'h0000_0000,
            32'h0000_0000,
            32'h0000_0000,
            32'h0000_0000,
            32'h0000_0002
        };
        desc_error = 1'b1;
        desc_valid = 1'b1;
        @(posedge clk);
        desc_valid = 1'b0;
        desc_error = 1'b0;

        if (decode_valid) begin
            $display("FAIL: decode_valid asserted for errored descriptor.");
            $finish;
        end

        if (decode_count !== 32'h0000_0002 || error_count !== 32'h0000_0001) begin
            $display("FAIL: unexpected counters after errored descriptor.");
            $finish;
        end

        $display("PASS: command-queue descriptor decode stub regression completed.");
        $finish;
    end
endmodule
