`timescale 1ns / 1ps

module accel_cmdq_dispatch_stub_tb;
    reg clk;
    reg resetn;
    reg enable;
    reg decode_valid;
    reg [31:0] desc_opcode;
    reg [31:0] desc_flags;
    reg [31:0] desc_src0;
    reg [31:0] desc_src1;
    reg [31:0] desc_dst0;
    reg [31:0] desc_arg0;
    reg [7:0]  npu_model_id_in;
    reg [15:0] npu_seq_length_in;
    reg [15:0] gpu_vertex0_xy_in;
    reg [15:0] gpu_vertex1_xy_in;
    reg [15:0] gpu_vertex2_xy_in;
    reg [7:0]  gpu_clear_value_in;
    wire       npu_dispatch_pulse;
    wire [7:0] npu_model_id_out;
    wire [15:0] npu_seq_length_out;
    wire [31:0] npu_input_offset_out;
    wire [31:0] npu_weight_offset_out;
    wire [31:0] npu_output_offset_out;
    wire       gpu_dispatch_pulse;
    wire [7:0] gpu_cmd_opcode_out;
    wire [15:0] gpu_vertex0_xy_out;
    wire [15:0] gpu_vertex1_xy_out;
    wire [15:0] gpu_vertex2_xy_out;
    wire [7:0] gpu_clear_value_out;
    wire [31:0] dispatch_status;
    wire [31:0] last_opcode;
    wire [31:0] npu_dispatch_count;
    wire [31:0] gpu_dispatch_count;
    wire [31:0] dispatch_error_count;

    accel_cmdq_dispatch_stub dut (
        .clk(clk),
        .resetn(resetn),
        .enable(enable),
        .decode_valid(decode_valid),
        .desc_opcode(desc_opcode),
        .desc_flags(desc_flags),
        .desc_src0(desc_src0),
        .desc_src1(desc_src1),
        .desc_dst0(desc_dst0),
        .desc_arg0(desc_arg0),
        .npu_model_id_in(npu_model_id_in),
        .npu_seq_length_in(npu_seq_length_in),
        .gpu_vertex0_xy_in(gpu_vertex0_xy_in),
        .gpu_vertex1_xy_in(gpu_vertex1_xy_in),
        .gpu_vertex2_xy_in(gpu_vertex2_xy_in),
        .gpu_clear_value_in(gpu_clear_value_in),
        .npu_dispatch_pulse(npu_dispatch_pulse),
        .npu_model_id_out(npu_model_id_out),
        .npu_seq_length_out(npu_seq_length_out),
        .npu_input_offset_out(npu_input_offset_out),
        .npu_weight_offset_out(npu_weight_offset_out),
        .npu_output_offset_out(npu_output_offset_out),
        .gpu_dispatch_pulse(gpu_dispatch_pulse),
        .gpu_cmd_opcode_out(gpu_cmd_opcode_out),
        .gpu_vertex0_xy_out(gpu_vertex0_xy_out),
        .gpu_vertex1_xy_out(gpu_vertex1_xy_out),
        .gpu_vertex2_xy_out(gpu_vertex2_xy_out),
        .gpu_clear_value_out(gpu_clear_value_out),
        .dispatch_status(dispatch_status),
        .last_opcode(last_opcode),
        .npu_dispatch_count(npu_dispatch_count),
        .gpu_dispatch_count(gpu_dispatch_count),
        .dispatch_error_count(dispatch_error_count)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 1'b0;
        resetn = 1'b0;
        enable = 1'b0;
        decode_valid = 1'b0;
        desc_opcode = 32'h0000_0000;
        desc_flags = 32'h0000_0000;
        desc_src0 = 32'h0000_0000;
        desc_src1 = 32'h0000_0000;
        desc_dst0 = 32'h0000_0000;
        desc_arg0 = 32'h0000_0000;
        npu_model_id_in = 8'h00;
        npu_seq_length_in = 16'h0000;
        gpu_vertex0_xy_in = 16'h0000;
        gpu_vertex1_xy_in = 16'h0000;
        gpu_vertex2_xy_in = 16'h0000;
        gpu_clear_value_in = 8'h00;

        repeat (6) @(posedge clk);
        resetn = 1'b1;
        enable = 1'b1;

        @(posedge clk);
        desc_opcode = 32'h0000_0002;
        desc_arg0 = 32'h0000_0001;
        decode_valid = 1'b1;
        @(posedge clk);
        decode_valid = 1'b0;

        if (!gpu_dispatch_pulse || gpu_cmd_opcode_out !== 8'h01 || gpu_clear_value_out !== 8'h01) begin
            $display("FAIL: GPU_CLEAR dispatch mismatch.");
            $finish;
        end

        @(posedge clk);
        gpu_vertex0_xy_in = 16'h0202;
        gpu_vertex1_xy_in = 16'h020A;
        gpu_vertex2_xy_in = 16'h0A02;
        desc_opcode = 32'h0000_0003;
        decode_valid = 1'b1;
        @(posedge clk);
        decode_valid = 1'b0;

        if (!gpu_dispatch_pulse || gpu_cmd_opcode_out !== 8'h02 ||
            gpu_vertex0_xy_out !== 16'h0202 || gpu_vertex1_xy_out !== 16'h020A ||
            gpu_vertex2_xy_out !== 16'h0A02) begin
            $display("FAIL: GPU_DRAW_TRI dispatch mismatch.");
            $finish;
        end

        @(posedge clk);
        npu_model_id_in = 8'h80;
        npu_seq_length_in = 16'h0008;
        desc_src0 = 32'h0000_0400;
        desc_src1 = 32'h0000_0420;
        desc_dst0 = 32'h0000_0480;
        desc_opcode = 32'h0000_0001;
        decode_valid = 1'b1;
        @(posedge clk);
        decode_valid = 1'b0;

        if (!npu_dispatch_pulse || npu_model_id_out !== 8'h80 || npu_seq_length_out !== 16'h0008 ||
            npu_input_offset_out !== 32'h0000_0400 || npu_weight_offset_out !== 32'h0000_0420 ||
            npu_output_offset_out !== 32'h0000_0480) begin
            $display("FAIL: NPU_INFER dispatch mismatch.");
            $finish;
        end

        @(posedge clk);
        desc_opcode = 32'hFFFF_FFFF;
        decode_valid = 1'b1;
        @(posedge clk);
        decode_valid = 1'b0;

        if (dispatch_status !== 32'h0000_0002) begin
            $display("FAIL: invalid opcode did not latch dispatch error. status=%08x", dispatch_status);
            $finish;
        end

        if (gpu_dispatch_count !== 32'd2 || npu_dispatch_count !== 32'd1 || dispatch_error_count !== 32'd1) begin
            $display("FAIL: unexpected dispatch counters. gpu=%0d npu=%0d err=%0d",
                     gpu_dispatch_count, npu_dispatch_count, dispatch_error_count);
            $finish;
        end

        if (last_opcode !== 32'hFFFF_FFFF) begin
            $display("FAIL: last opcode mismatch. got=%08x", last_opcode);
            $finish;
        end

        $display("PASS: command-queue dispatch stub regression completed.");
        $finish;
    end
endmodule
