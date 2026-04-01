module accel_npu_cmd_exec_stub (
    input  wire        clk,
    input  wire        resetn,
    input  wire        enable,
    input  wire        dispatch_valid,
    input  wire [7:0]  model_id_in,
    input  wire [15:0] seq_length_in,
    input  wire [31:0] input_offset_in,
    input  wire [31:0] weight_offset_in,
    input  wire [31:0] output_offset_in,
    input  wire        npu_busy,
    input  wire        npu_done,
    output reg         npu_start_pulse,
    output reg         store_request_pulse,
    output reg  [7:0]  npu_model_id_out,
    output reg  [15:0] npu_seq_length_out,
    output reg  [31:0] exec_status,
    output reg  [31:0] last_input_offset,
    output reg  [31:0] last_weight_offset,
    output reg  [31:0] last_output_offset
);
    localparam [31:0] STATUS_BUSY  = 32'h0000_0001;
    localparam [31:0] STATUS_ERROR = 32'h0000_0002;
    localparam [31:0] STATUS_IDLE  = 32'h0000_0004;

    reg        inflight;
    reg [15:0] exec_count;
    reg [7:0]  last_model_id;
    reg        error_sticky;

    always @(posedge clk) begin
        if (!resetn) begin
            npu_start_pulse <= 1'b0;
            store_request_pulse <= 1'b0;
            npu_model_id_out <= 8'h00;
            npu_seq_length_out <= 16'h0000;
            exec_status <= STATUS_IDLE;
            last_input_offset <= 32'h0000_0000;
            last_weight_offset <= 32'h0000_0000;
            last_output_offset <= 32'h0000_0000;
            inflight <= 1'b0;
            exec_count <= 16'h0000;
            last_model_id <= 8'h00;
            error_sticky <= 1'b0;
        end else begin
            npu_start_pulse <= 1'b0;
            store_request_pulse <= 1'b0;

            if (!enable) begin
                exec_status <= STATUS_IDLE;
                last_input_offset <= 32'h0000_0000;
                last_weight_offset <= 32'h0000_0000;
                last_output_offset <= 32'h0000_0000;
                inflight <= 1'b0;
                exec_count <= 16'h0000;
                last_model_id <= 8'h00;
                error_sticky <= 1'b0;
            end else begin
                if (dispatch_valid) begin
                    last_input_offset <= input_offset_in;
                    last_weight_offset <= weight_offset_in;
                    last_output_offset <= output_offset_in;
                    last_model_id <= model_id_in;

                    if (inflight || npu_busy) begin
                        error_sticky <= 1'b1;
                    end else begin
                        npu_start_pulse <= 1'b1;
                        npu_model_id_out <= model_id_in;
                        npu_seq_length_out <= seq_length_in;
                        inflight <= 1'b1;
                        exec_count <= exec_count + 16'd1;
                    end
                end

                if (inflight && npu_done) begin
                    inflight <= 1'b0;
                    store_request_pulse <= 1'b1;
                end

                exec_status <= {exec_count, last_model_id, 5'h00,
                                ((inflight || npu_busy) ? STATUS_BUSY : 32'h0) |
                                (error_sticky ? STATUS_ERROR : 32'h0) |
                                ((!inflight && !npu_busy) ? STATUS_IDLE : 32'h0)};
            end
        end
    end
endmodule
