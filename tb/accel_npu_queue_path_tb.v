`timescale 1ns / 1ps

module accel_npu_queue_path_tb;
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
    reg [31:0] input_vec0;
    reg [31:0] input_vec1;
    reg [31:0] runtime_weight0_a;
    reg [31:0] runtime_weight0_b;
    reg [31:0] runtime_weight1_a;
    reg [31:0] runtime_weight1_b;
    reg [31:0] runtime_bias0;
    reg [31:0] runtime_bias1;

    wire        npu_dispatch_pulse;
    wire [7:0]  npu_model_id_out;
    wire [15:0] npu_seq_length_out;
    wire [31:0] npu_input_offset_out;
    wire [31:0] npu_weight_offset_out;
    wire [31:0] npu_output_offset_out;
    wire        gpu_dispatch_pulse;
    wire [7:0]  gpu_cmd_opcode_out;
    wire [15:0] gpu_vertex0_xy_out;
    wire [15:0] gpu_vertex1_xy_out;
    wire [15:0] gpu_vertex2_xy_out;
    wire [7:0]  gpu_clear_value_out;
    wire [31:0] dispatch_status;
    wire [31:0] last_opcode;
    wire [31:0] npu_dispatch_count;
    wire [31:0] gpu_dispatch_count;
    wire [31:0] dispatch_error_count;

    wire        npu_start_pulse;
    wire        store_request_pulse;
    wire [7:0]  npu_model_id_exec;
    wire [15:0] npu_seq_length_exec;
    wire [31:0] exec_status;
    wire [31:0] last_input_offset;
    wire [31:0] last_weight_offset;
    wire [31:0] last_output_offset;

    wire        npu_busy;
    wire        npu_done;
    wire [31:0] npu_status_word;
    wire [31:0] npu_logit0;
    wire [31:0] npu_logit1;
    wire [7:0]  npu_class_id;
    wire [31:0] npu_hidden0;
    wire [31:0] npu_hidden1;

    accel_cmdq_dispatch_stub dispatch_dut (
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

    accel_npu_cmd_exec_stub exec_dut (
        .clk(clk),
        .resetn(resetn),
        .enable(enable),
        .dispatch_valid(npu_dispatch_pulse),
        .model_id_in(npu_model_id_out),
        .seq_length_in(npu_seq_length_out),
        .input_offset_in(npu_input_offset_out),
        .weight_offset_in(npu_weight_offset_out),
        .output_offset_in(npu_output_offset_out),
        .npu_busy(npu_busy),
        .npu_done(npu_done),
        .npu_start_pulse(npu_start_pulse),
        .store_request_pulse(store_request_pulse),
        .npu_model_id_out(npu_model_id_exec),
        .npu_seq_length_out(npu_seq_length_exec),
        .exec_status(exec_status),
        .last_input_offset(last_input_offset),
        .last_weight_offset(last_weight_offset),
        .last_output_offset(last_output_offset)
    );

    npu_v2_stub npu_dut (
        .clk(clk),
        .resetn(resetn),
        .start(npu_start_pulse),
        .model_id(npu_model_id_exec),
        .seq_length(npu_seq_length_exec),
        .input_vec0(input_vec0),
        .input_vec1(input_vec1),
        .runtime_weight0_a(runtime_weight0_a),
        .runtime_weight0_b(runtime_weight0_b),
        .runtime_weight1_a(runtime_weight1_a),
        .runtime_weight1_b(runtime_weight1_b),
        .runtime_bias0(runtime_bias0),
        .runtime_bias1(runtime_bias1),
        .busy(npu_busy),
        .done(npu_done),
        .status_word(npu_status_word),
        .logit0(npu_logit0),
        .logit1(npu_logit1),
        .class_id(npu_class_id),
        .hidden0(npu_hidden0),
        .hidden1(npu_hidden1)
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
        input_vec0 = 32'h0002_0001;
        input_vec1 = 32'h0004_0003;
        runtime_weight0_a = 32'h0002_0002;
        runtime_weight0_b = 32'h0002_0002;
        runtime_weight1_a = 32'h0200_0200;
        runtime_weight1_b = 32'h0200_0200;
        runtime_bias0 = 32'h0000_0000;
        runtime_bias1 = 32'h0000_0000;

        repeat (6) @(posedge clk);
        resetn = 1'b1;
        enable = 1'b1;

        @(negedge clk);
        desc_opcode = 32'h0000_0001;
        desc_flags = 32'h0000_0080;
        desc_src0 = 32'h0000_0400;
        desc_src1 = 32'h0000_0420;
        desc_dst0 = 32'h0000_0480;
        desc_arg0 = 32'h0000_0008;
        npu_model_id_in = 8'h80;
        npu_seq_length_in = 16'h0008;
        decode_valid = 1'b1;

        @(posedge clk);
        @(negedge clk);
        decode_valid = 1'b0;

        wait (npu_dispatch_pulse == 1'b1);
        if (last_opcode !== 32'h0000_0001 || npu_dispatch_count !== 32'h0000_0001 ||
            gpu_dispatch_count !== 32'h0000_0000 || dispatch_error_count !== 32'h0000_0000) begin
            $display("FAIL: NPU dispatch counters/opcode mismatch.");
            $finish;
        end

        if (npu_input_offset_out !== 32'h0000_0400 || npu_weight_offset_out !== 32'h0000_0420 ||
            npu_output_offset_out !== 32'h0000_0480) begin
            $display("FAIL: NPU dispatch offsets mismatch.");
            $finish;
        end

        wait (npu_start_pulse == 1'b1);
        if (npu_model_id_exec !== 8'h80 || npu_seq_length_exec !== 16'h0008) begin
            $display("FAIL: NPU exec launch payload mismatch.");
            $finish;
        end

        if (last_input_offset !== 32'h0000_0400 || last_weight_offset !== 32'h0000_0420 ||
            last_output_offset !== 32'h0000_0480) begin
            $display("FAIL: NPU exec latched offsets mismatch.");
            $finish;
        end

        wait (npu_busy == 1'b1);
        wait (npu_done == 1'b1);
        @(posedge clk);

        if (!store_request_pulse) begin
            $display("FAIL: NPU queue-path did not emit store_request_pulse.");
            $finish;
        end

        if (dispatch_status !== 32'h0000_0004 || exec_status !== 32'h0001_8004) begin
            $display("FAIL: NPU queue-path status mismatch. dispatch=%08x exec=%08x",
                     dispatch_status, exec_status);
            $finish;
        end

        if (npu_status_word !== 32'h4E00_8008 || npu_logit0 !== 32'h0000_0014 ||
            npu_logit1 !== 32'h0000_0000 || npu_class_id !== 8'h00) begin
            $display("FAIL: NPU queue-path result mismatch. status=%08x logit0=%08x logit1=%08x class=%02x",
                     npu_status_word, npu_logit0, npu_logit1, npu_class_id);
            $finish;
        end

        $display("PASS: NPU queue-path regression completed.");
        $finish;
    end
endmodule
