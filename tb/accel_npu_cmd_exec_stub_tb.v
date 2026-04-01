`timescale 1ns / 1ps

module accel_npu_cmd_exec_stub_tb;
    reg clk;
    reg resetn;
    reg enable;
    reg dispatch_valid;
    reg [7:0] model_id_in;
    reg [15:0] seq_length_in;
    reg [31:0] input_offset_in;
    reg [31:0] weight_offset_in;
    reg [31:0] output_offset_in;
    reg npu_busy;
    reg npu_done;
    wire npu_start_pulse;
    wire [7:0] npu_model_id_out;
    wire [15:0] npu_seq_length_out;
    wire [31:0] exec_status;
    wire [31:0] last_input_offset;
    wire [31:0] last_weight_offset;
    wire [31:0] last_output_offset;

    accel_npu_cmd_exec_stub dut (
        .clk(clk),
        .resetn(resetn),
        .enable(enable),
        .dispatch_valid(dispatch_valid),
        .model_id_in(model_id_in),
        .seq_length_in(seq_length_in),
        .input_offset_in(input_offset_in),
        .weight_offset_in(weight_offset_in),
        .output_offset_in(output_offset_in),
        .npu_busy(npu_busy),
        .npu_done(npu_done),
        .npu_start_pulse(npu_start_pulse),
        .npu_model_id_out(npu_model_id_out),
        .npu_seq_length_out(npu_seq_length_out),
        .exec_status(exec_status),
        .last_input_offset(last_input_offset),
        .last_weight_offset(last_weight_offset),
        .last_output_offset(last_output_offset)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 1'b0;
        resetn = 1'b0;
        enable = 1'b0;
        dispatch_valid = 1'b0;
        model_id_in = 8'h00;
        seq_length_in = 16'h0000;
        input_offset_in = 32'h0000_0000;
        weight_offset_in = 32'h0000_0000;
        output_offset_in = 32'h0000_0000;
        npu_busy = 1'b0;
        npu_done = 1'b0;

        repeat (6) @(posedge clk);
        resetn = 1'b1;
        enable = 1'b1;

        @(posedge clk);
        model_id_in = 8'h80;
        seq_length_in = 16'h0008;
        input_offset_in = 32'h0000_0400;
        weight_offset_in = 32'h0000_0420;
        output_offset_in = 32'h0000_0480;
        dispatch_valid = 1'b1;
        @(posedge clk);
        dispatch_valid = 1'b0;
        npu_busy = 1'b1;

        if (!npu_start_pulse || npu_model_id_out !== 8'h80 || npu_seq_length_out !== 16'h0008) begin
            $display("FAIL: NPU exec start pulse mismatch.");
            $finish;
        end

        if (last_input_offset !== 32'h0000_0400 || last_weight_offset !== 32'h0000_0420 ||
            last_output_offset !== 32'h0000_0480) begin
            $display("FAIL: NPU exec offsets mismatch.");
            $finish;
        end

        repeat (3) @(posedge clk);
        npu_busy = 1'b0;
        npu_done = 1'b1;
        @(posedge clk);
        npu_done = 1'b0;

        if (exec_status !== 32'h0001_8004) begin
            $display("FAIL: NPU exec idle status mismatch. got=%08x", exec_status);
            $finish;
        end

        @(posedge clk);
        dispatch_valid = 1'b1;
        npu_busy = 1'b1;
        @(posedge clk);
        dispatch_valid = 1'b0;
        npu_busy = 1'b0;

        if ((exec_status & 32'h0000_0002) == 0) begin
            $display("FAIL: NPU exec error bit was not latched.");
            $finish;
        end

        $display("PASS: NPU command execution stub regression completed.");
        $finish;
    end
endmodule
