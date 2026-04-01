module npu_v2_stub (
    input  wire        clk,
    input  wire        resetn,
    input  wire        start,
    input  wire [7:0]  model_id,
    input  wire [15:0] seq_length,
    input  wire [31:0] input_vec0,
    input  wire [31:0] input_vec1,
    input  wire [31:0] runtime_weight0_a,
    input  wire [31:0] runtime_weight0_b,
    input  wire [31:0] runtime_weight1_a,
    input  wire [31:0] runtime_weight1_b,
    input  wire [31:0] runtime_bias0,
    input  wire [31:0] runtime_bias1,
    output reg         busy,
    output reg         done,
    output reg  [31:0] status_word,
    output reg  [31:0] logit0,
    output reg  [31:0] logit1,
    output reg  [7:0]  class_id
);
    reg [7:0]  countdown;
    reg [7:0]  model_id_q;
    reg [15:0] seq_length_q;
    reg [31:0] input_vec0_q;
    reg [31:0] input_vec1_q;

    reg [31:0] weight0_a;
    reg [31:0] weight0_b;
    reg [31:0] weight1_a;
    reg [31:0] weight1_b;
    reg signed [31:0] bias0;
    reg signed [31:0] bias1;

    wire [31:0] dot0_a;
    wire [31:0] dot0_b;
    wire [31:0] dot1_a;
    wire [31:0] dot1_b;
    wire signed [31:0] sum0 = $signed(dot0_a) + $signed(dot0_b) + bias0;
    wire signed [31:0] sum1 = $signed(dot1_a) + $signed(dot1_b) + bias1;
    wire [7:0] class_next = ($signed(sum1) > $signed(sum0)) ? 8'h01 : 8'h00;

    npu_dot4_i8 dot0a_i (
        .vec_a  (input_vec0_q),
        .vec_b  (weight0_a),
        .result (dot0_a)
    );

    npu_dot4_i8 dot0b_i (
        .vec_a  (input_vec1_q),
        .vec_b  (weight0_b),
        .result (dot0_b)
    );

    npu_dot4_i8 dot1a_i (
        .vec_a  (input_vec0_q),
        .vec_b  (weight1_a),
        .result (dot1_a)
    );

    npu_dot4_i8 dot1b_i (
        .vec_a  (input_vec1_q),
        .vec_b  (weight1_b),
        .result (dot1_b)
    );

    always @* begin
        case (model_id_q)
            8'h02: begin
                // Model 2: favor the latter half of the input vector.
                weight0_a = 32'hFFFFFFFF;
                weight0_b = 32'h01010101;
                weight1_a = 32'h01010101;
                weight1_b = 32'hFFFFFFFF;
                bias0 = 32'sd2;
                bias1 = -32'sd2;
            end
            8'h80: begin
                // Runtime-programmable 2-class linear model loaded via MMIO.
                weight0_a = runtime_weight0_a;
                weight0_b = runtime_weight0_b;
                weight1_a = runtime_weight1_a;
                weight1_b = runtime_weight1_b;
                bias0 = runtime_bias0;
                bias1 = runtime_bias1;
            end
            default: begin
                // Model 1: 2-class classifier on 8 signed int8 features.
                // class0 ~= sum(first4) - sum(last4)
                // class1 ~= -sum(first4) + sum(last4)
                weight0_a = 32'h01010101;
                weight0_b = 32'hFFFFFFFF;
                weight1_a = 32'hFFFFFFFF;
                weight1_b = 32'h01010101;
                bias0 = 32'sd0;
                bias1 = 32'sd0;
            end
        endcase
    end

    always @(posedge clk) begin
        if (!resetn) begin
            busy <= 1'b0;
            done <= 1'b0;
            countdown <= 8'h00;
            model_id_q <= 8'h01;
            seq_length_q <= 16'd8;
            input_vec0_q <= 32'h00000000;
            input_vec1_q <= 32'h00000000;
            status_word <= 32'h00000000;
            logit0 <= 32'h00000000;
            logit1 <= 32'h00000000;
            class_id <= 8'h00;
        end else begin
            done <= 1'b0;

            if (start && !busy) begin
                busy <= 1'b1;
                countdown <= 8'd4;
                model_id_q <= model_id;
                seq_length_q <= seq_length;
                input_vec0_q <= input_vec0;
                input_vec1_q <= input_vec1;
            end else if (busy) begin
                if (countdown == 8'd0) begin
                    busy <= 1'b0;
                    done <= 1'b1;
                    logit0 <= sum0;
                    logit1 <= sum1;
                    class_id <= class_next;
                    status_word <= {8'h4E, class_next, model_id_q, seq_length_q[7:0]};
                end else begin
                    countdown <= countdown - 8'd1;
                end
            end
        end
    end
endmodule
