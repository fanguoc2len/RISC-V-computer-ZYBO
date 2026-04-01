module accel_npu_result_store_stub (
    input  wire        clk,
    input  wire        resetn,
    input  wire        enable,
    input  wire        store_request_valid,
    input  wire [31:0] umem_base_addr,
    input  wire [31:0] output_offset_in,
    input  wire [31:0] status_word_in,
    input  wire [31:0] logit0_in,
    input  wire [31:0] logit1_in,
    input  wire [7:0]  class_id_in,
    input  wire [31:0] hidden0_in,
    input  wire [31:0] hidden1_in,
    output reg  [31:0] store_status,
    output reg  [31:0] store_count,
    output reg  [31:0] store_error_count,
    output reg  [31:0] last_output_offset,
    output reg  [31:0] last_awaddr,
    output reg  [31:0] stored_status_word,
    output reg  [31:0] stored_logit0,
    output reg  [31:0] stored_logit1,
    output reg  [31:0] stored_class_word,
    output reg  [31:0] stored_hidden0,
    output reg  [31:0] stored_hidden1,
    output reg  [31:0] m_axi_awaddr,
    output reg  [7:0]  m_axi_awlen,
    output reg  [2:0]  m_axi_awsize,
    output reg  [1:0]  m_axi_awburst,
    output reg         m_axi_awvalid,
    input  wire        m_axi_awready,
    output reg  [31:0] m_axi_wdata,
    output reg  [3:0]  m_axi_wstrb,
    output reg         m_axi_wlast,
    output reg         m_axi_wvalid,
    input  wire        m_axi_wready,
    input  wire [1:0]  m_axi_bresp,
    input  wire        m_axi_bvalid,
    output reg         m_axi_bready
);
    localparam [1:0] STATE_IDLE = 2'd0;
    localparam [1:0] STATE_AW   = 2'd1;
    localparam [1:0] STATE_W    = 2'd2;
    localparam [1:0] STATE_B    = 2'd3;

    reg [1:0] state;
    reg [2:0] beat_index;
    reg [7:0] last_class_id;
    reg       error_sticky;

    function [31:0] select_payload_word;
        input [2:0]  beat;
        input [31:0] word0;
        input [31:0] word1;
        input [31:0] word2;
        input [31:0] word3;
        input [31:0] word4;
        input [31:0] word5;
        begin
            case (beat)
                3'd0: select_payload_word = word0;
                3'd1: select_payload_word = word1;
                3'd2: select_payload_word = word2;
                3'd3: select_payload_word = word3;
                3'd4: select_payload_word = word4;
                default: select_payload_word = word5;
            endcase
        end
    endfunction

    always @(posedge clk) begin
        if (!resetn) begin
            store_status <= 32'h0000_0004;
            store_count <= 32'h0000_0000;
            store_error_count <= 32'h0000_0000;
            last_output_offset <= 32'h0000_0000;
            last_awaddr <= 32'h0000_0000;
            stored_status_word <= 32'h0000_0000;
            stored_logit0 <= 32'h0000_0000;
            stored_logit1 <= 32'h0000_0000;
            stored_class_word <= 32'h0000_0000;
            stored_hidden0 <= 32'h0000_0000;
            stored_hidden1 <= 32'h0000_0000;
            m_axi_awaddr <= 32'h0000_0000;
            m_axi_awlen <= 8'h00;
            m_axi_awsize <= 3'b010;
            m_axi_awburst <= 2'b01;
            m_axi_awvalid <= 1'b0;
            m_axi_wdata <= 32'h0000_0000;
            m_axi_wstrb <= 4'hF;
            m_axi_wlast <= 1'b0;
            m_axi_wvalid <= 1'b0;
            m_axi_bready <= 1'b0;
            state <= STATE_IDLE;
            beat_index <= 3'd0;
            last_class_id <= 8'h00;
            error_sticky <= 1'b0;
        end else begin
            if (!enable) begin
                store_status <= 32'h0000_0004;
                store_count <= 32'h0000_0000;
                store_error_count <= 32'h0000_0000;
                last_output_offset <= 32'h0000_0000;
                last_awaddr <= 32'h0000_0000;
                stored_status_word <= 32'h0000_0000;
                stored_logit0 <= 32'h0000_0000;
                stored_logit1 <= 32'h0000_0000;
                stored_class_word <= 32'h0000_0000;
                stored_hidden0 <= 32'h0000_0000;
                stored_hidden1 <= 32'h0000_0000;
                m_axi_awaddr <= 32'h0000_0000;
                m_axi_awlen <= 8'h00;
                m_axi_awsize <= 3'b010;
                m_axi_awburst <= 2'b01;
                m_axi_awvalid <= 1'b0;
                m_axi_wdata <= 32'h0000_0000;
                m_axi_wstrb <= 4'hF;
                m_axi_wlast <= 1'b0;
                m_axi_wvalid <= 1'b0;
                m_axi_bready <= 1'b0;
                state <= STATE_IDLE;
                beat_index <= 3'd0;
                last_class_id <= 8'h00;
                error_sticky <= 1'b0;
            end else begin
                if (store_request_valid && (state != STATE_IDLE)) begin
                    error_sticky <= 1'b1;
                    store_error_count <= store_error_count + 32'd1;
                end

                case (state)
                    STATE_IDLE: begin
                        m_axi_awvalid <= 1'b0;
                        m_axi_wvalid <= 1'b0;
                        m_axi_wlast <= 1'b0;
                        m_axi_bready <= 1'b0;
                        beat_index <= 3'd0;

                        if (store_request_valid) begin
                            last_output_offset <= output_offset_in;
                            last_awaddr <= umem_base_addr + output_offset_in;
                            last_class_id <= class_id_in;
                            stored_status_word <= status_word_in;
                            stored_logit0 <= logit0_in;
                            stored_logit1 <= logit1_in;
                            stored_class_word <= {24'h000000, class_id_in};
                            stored_hidden0 <= hidden0_in;
                            stored_hidden1 <= hidden1_in;
                            m_axi_awaddr <= umem_base_addr + output_offset_in;
                            m_axi_awlen <= 8'd5;
                            m_axi_awsize <= 3'b010;
                            m_axi_awburst <= 2'b01;
                            m_axi_awvalid <= 1'b1;
                            store_count <= store_count + 32'd1;
                            state <= STATE_AW;
                        end
                    end

                    STATE_AW: begin
                        if (m_axi_awvalid && m_axi_awready) begin
                            m_axi_awvalid <= 1'b0;
                            m_axi_wdata <= stored_status_word;
                            m_axi_wstrb <= 4'hF;
                            m_axi_wlast <= 1'b0;
                            m_axi_wvalid <= 1'b1;
                            beat_index <= 3'd0;
                            state <= STATE_W;
                        end
                    end

                    STATE_W: begin
                        if (m_axi_wvalid && m_axi_wready) begin
                            if (beat_index == 3'd5) begin
                                m_axi_wvalid <= 1'b0;
                                m_axi_wlast <= 1'b0;
                                m_axi_bready <= 1'b1;
                                state <= STATE_B;
                            end else begin
                                beat_index <= beat_index + 3'd1;
                                m_axi_wdata <= select_payload_word(
                                    beat_index + 3'd1,
                                    stored_status_word,
                                    stored_logit0,
                                    stored_logit1,
                                    stored_class_word,
                                    stored_hidden0,
                                    stored_hidden1
                                );
                                m_axi_wlast <= (beat_index == 3'd4);
                            end
                        end
                    end

                    STATE_B: begin
                        if (m_axi_bvalid && m_axi_bready) begin
                            if (m_axi_bresp != 2'b00) begin
                                error_sticky <= 1'b1;
                                store_error_count <= store_error_count + 32'd1;
                            end
                            m_axi_bready <= 1'b0;
                            state <= STATE_IDLE;
                        end
                    end

                    default: begin
                        state <= STATE_IDLE;
                    end
                endcase

                store_status <= {
                    store_count[15:0],
                    last_class_id,
                    5'h00,
                    (state == STATE_IDLE),
                    error_sticky,
                    (state != STATE_IDLE)
                };
            end
        end
    end
endmodule
