module accel_npu_payload_fetch_stub (
    input  wire        clk,
    input  wire        resetn,
    input  wire        enable,
    input  wire [31:0] umem_base_addr,
    input  wire        dispatch_valid,
    input  wire [7:0]  model_id_in,
    input  wire [15:0] seq_length_in,
    input  wire [31:0] input_offset_in,
    input  wire [31:0] weight_offset_in,
    input  wire [31:0] output_offset_in,
    input  wire [31:0] shadow_input0,
    input  wire [31:0] shadow_input1,
    input  wire [31:0] shadow_weight0_a,
    input  wire [31:0] shadow_weight0_b,
    input  wire [31:0] shadow_weight1_a,
    input  wire [31:0] shadow_weight1_b,
    input  wire [31:0] shadow_bias0,
    input  wire [31:0] shadow_bias1,
    output reg         payload_valid,
    output reg  [7:0]  model_id_out,
    output reg  [15:0] seq_length_out,
    output reg  [31:0] input_offset_out,
    output reg  [31:0] weight_offset_out,
    output reg  [31:0] output_offset_out,
    output reg  [31:0] fetched_input0,
    output reg  [31:0] fetched_input1,
    output reg  [31:0] fetched_weight0_a,
    output reg  [31:0] fetched_weight0_b,
    output reg  [31:0] fetched_weight1_a,
    output reg  [31:0] fetched_weight1_b,
    output reg  [31:0] fetched_bias0,
    output reg  [31:0] fetched_bias1,
    output reg  [31:0] fetch_status,
    output reg  [31:0] fetch_count,
    output reg  [31:0] fetch_error_count,
    output reg  [31:0] m_axi_araddr,
    output reg  [7:0]  m_axi_arlen,
    output reg  [2:0]  m_axi_arsize,
    output reg  [1:0]  m_axi_arburst,
    output reg         m_axi_arvalid,
    input  wire        m_axi_arready,
    input  wire [31:0] m_axi_rdata,
    input  wire [1:0]  m_axi_rresp,
    input  wire        m_axi_rlast,
    input  wire        m_axi_rvalid,
    output reg         m_axi_rready
);
    localparam [31:0] STATUS_BUSY  = 32'h0000_0001;
    localparam [31:0] STATUS_ERROR = 32'h0000_0002;
    localparam [31:0] STATUS_IDLE  = 32'h0000_0004;

    localparam [2:0] STATE_IDLE      = 3'd0;
    localparam [2:0] STATE_INPUT_AR  = 3'd1;
    localparam [2:0] STATE_INPUT_R   = 3'd2;
    localparam [2:0] STATE_WEIGHT_AR = 3'd3;
    localparam [2:0] STATE_WEIGHT_R  = 3'd4;

    reg [2:0] state;
    reg [2:0] beat_index;
    reg error_sticky;
    reg burst_error;

    always @(posedge clk) begin
        if (!resetn) begin
            payload_valid <= 1'b0;
            model_id_out <= 8'h00;
            seq_length_out <= 16'h0000;
            input_offset_out <= 32'h0000_0000;
            weight_offset_out <= 32'h0000_0000;
            output_offset_out <= 32'h0000_0000;
            fetched_input0 <= 32'h0000_0000;
            fetched_input1 <= 32'h0000_0000;
            fetched_weight0_a <= 32'h0000_0000;
            fetched_weight0_b <= 32'h0000_0000;
            fetched_weight1_a <= 32'h0000_0000;
            fetched_weight1_b <= 32'h0000_0000;
            fetched_bias0 <= 32'h0000_0000;
            fetched_bias1 <= 32'h0000_0000;
            fetch_status <= STATUS_IDLE;
            fetch_count <= 32'h0000_0000;
            fetch_error_count <= 32'h0000_0000;
            m_axi_araddr <= 32'h0000_0000;
            m_axi_arlen <= 8'h00;
            m_axi_arsize <= 3'b010;
            m_axi_arburst <= 2'b01;
            m_axi_arvalid <= 1'b0;
            m_axi_rready <= 1'b0;
            state <= STATE_IDLE;
            beat_index <= 3'd0;
            error_sticky <= 1'b0;
            burst_error <= 1'b0;
        end else begin
            payload_valid <= 1'b0;

            if (!enable) begin
                model_id_out <= 8'h00;
                seq_length_out <= 16'h0000;
                input_offset_out <= 32'h0000_0000;
                weight_offset_out <= 32'h0000_0000;
                output_offset_out <= 32'h0000_0000;
                fetched_input0 <= 32'h0000_0000;
                fetched_input1 <= 32'h0000_0000;
                fetched_weight0_a <= 32'h0000_0000;
                fetched_weight0_b <= 32'h0000_0000;
                fetched_weight1_a <= 32'h0000_0000;
                fetched_weight1_b <= 32'h0000_0000;
                fetched_bias0 <= 32'h0000_0000;
                fetched_bias1 <= 32'h0000_0000;
                fetch_status <= STATUS_IDLE;
                fetch_count <= 32'h0000_0000;
                fetch_error_count <= 32'h0000_0000;
                m_axi_araddr <= 32'h0000_0000;
                m_axi_arlen <= 8'h00;
                m_axi_arsize <= 3'b010;
                m_axi_arburst <= 2'b01;
                m_axi_arvalid <= 1'b0;
                m_axi_rready <= 1'b0;
                state <= STATE_IDLE;
                beat_index <= 3'd0;
                error_sticky <= 1'b0;
                burst_error <= 1'b0;
            end else begin
                if (dispatch_valid && (state != STATE_IDLE)) begin
                    error_sticky <= 1'b1;
                    fetch_error_count <= fetch_error_count + 32'd1;
                end

                case (state)
                    STATE_IDLE: begin
                        m_axi_arvalid <= 1'b0;
                        m_axi_rready <= 1'b0;
                        beat_index <= 3'd0;
                        burst_error <= 1'b0;
                        fetch_status <= error_sticky ? (STATUS_ERROR | STATUS_IDLE) : STATUS_IDLE;

                        if (dispatch_valid) begin
                            model_id_out <= model_id_in;
                            seq_length_out <= seq_length_in;
                            input_offset_out <= input_offset_in;
                            weight_offset_out <= weight_offset_in;
                            output_offset_out <= output_offset_in;
                            fetched_input0 <= shadow_input0;
                            fetched_input1 <= shadow_input1;
                            fetched_weight0_a <= shadow_weight0_a;
                            fetched_weight0_b <= shadow_weight0_b;
                            fetched_weight1_a <= shadow_weight1_a;
                            fetched_weight1_b <= shadow_weight1_b;
                            fetched_bias0 <= shadow_bias0;
                            fetched_bias1 <= shadow_bias1;
                            m_axi_araddr <= umem_base_addr + input_offset_in;
                            m_axi_arlen <= 8'd1;
                            m_axi_arsize <= 3'b010;
                            m_axi_arburst <= 2'b01;
                            m_axi_arvalid <= 1'b1;
                            fetch_status <= STATUS_BUSY;
                            state <= STATE_INPUT_AR;
                        end
                    end

                    STATE_INPUT_AR: begin
                        fetch_status <= STATUS_BUSY;
                        if (m_axi_arvalid && m_axi_arready) begin
                            m_axi_arvalid <= 1'b0;
                            m_axi_rready <= 1'b1;
                            beat_index <= 3'd0;
                            burst_error <= 1'b0;
                            state <= STATE_INPUT_R;
                        end
                    end

                    STATE_INPUT_R: begin
                        fetch_status <= STATUS_BUSY;
                        if (m_axi_rvalid && m_axi_rready) begin
                            if (m_axi_rresp != 2'b00) begin
                                burst_error <= 1'b1;
                            end

                            case (beat_index)
                                3'd0: fetched_input0 <= m_axi_rdata;
                                3'd1: fetched_input1 <= m_axi_rdata;
                                default: begin
                                end
                            endcase

                            if (m_axi_rlast) begin
                                if (beat_index != 3'd1) begin
                                    burst_error <= 1'b1;
                                end
                                m_axi_rready <= 1'b0;
                                m_axi_araddr <= umem_base_addr + weight_offset_out;
                                m_axi_arlen <= 8'd5;
                                m_axi_arsize <= 3'b010;
                                m_axi_arburst <= 2'b01;
                                m_axi_arvalid <= 1'b1;
                                beat_index <= 3'd0;
                                state <= STATE_WEIGHT_AR;
                            end else begin
                                beat_index <= beat_index + 3'd1;
                            end
                        end
                    end

                    STATE_WEIGHT_AR: begin
                        fetch_status <= STATUS_BUSY;
                        if (m_axi_arvalid && m_axi_arready) begin
                            m_axi_arvalid <= 1'b0;
                            m_axi_rready <= 1'b1;
                            beat_index <= 3'd0;
                            state <= STATE_WEIGHT_R;
                        end
                    end

                    STATE_WEIGHT_R: begin
                        fetch_status <= STATUS_BUSY;
                        if (m_axi_rvalid && m_axi_rready) begin
                            if (m_axi_rresp != 2'b00) begin
                                burst_error <= 1'b1;
                            end

                            case (beat_index)
                                3'd0: fetched_weight0_a <= m_axi_rdata;
                                3'd1: fetched_weight0_b <= m_axi_rdata;
                                3'd2: fetched_weight1_a <= m_axi_rdata;
                                3'd3: fetched_weight1_b <= m_axi_rdata;
                                3'd4: fetched_bias0 <= m_axi_rdata;
                                3'd5: fetched_bias1 <= m_axi_rdata;
                                default: begin
                                end
                            endcase

                            if (m_axi_rlast) begin
                                m_axi_rready <= 1'b0;
                                fetch_count <= fetch_count + 32'd1;
                                payload_valid <= 1'b1;
                                if (beat_index != 3'd5 || burst_error || (m_axi_rresp != 2'b00)) begin
                                    error_sticky <= 1'b1;
                                    fetch_error_count <= fetch_error_count + 32'd1;
                                end
                                fetch_status <=
                                    ((error_sticky || burst_error || (m_axi_rresp != 2'b00) || (beat_index != 3'd5))
                                        ? STATUS_ERROR : 32'h0000_0000) |
                                    STATUS_IDLE;
                                state <= STATE_IDLE;
                            end else begin
                                beat_index <= beat_index + 3'd1;
                            end
                        end
                    end

                    default: begin
                        state <= STATE_IDLE;
                        fetch_status <= error_sticky ? (STATUS_ERROR | STATUS_IDLE) : STATUS_IDLE;
                    end
                end
            end
        end
    end
endmodule
