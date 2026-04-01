`timescale 1ns / 1ps

module accel_npu_payload_fetch_stub_tb;
    reg clk;
    reg resetn;
    reg enable;
    reg [31:0] umem_base_addr;
    reg dispatch_valid;
    reg [7:0] model_id_in;
    reg [15:0] seq_length_in;
    reg [31:0] input_offset_in;
    reg [31:0] weight_offset_in;
    reg [31:0] output_offset_in;
    reg [31:0] shadow_input0;
    reg [31:0] shadow_input1;
    reg [31:0] shadow_weight0_a;
    reg [31:0] shadow_weight0_b;
    reg [31:0] shadow_weight1_a;
    reg [31:0] shadow_weight1_b;
    reg [31:0] shadow_bias0;
    reg [31:0] shadow_bias1;
    reg        m_axi_arready;
    reg [31:0] m_axi_rdata;
    reg [1:0]  m_axi_rresp;
    reg        m_axi_rlast;
    reg        m_axi_rvalid;

    wire        payload_valid;
    wire [7:0]  model_id_out;
    wire [15:0] seq_length_out;
    wire [31:0] input_offset_out;
    wire [31:0] weight_offset_out;
    wire [31:0] output_offset_out;
    wire [31:0] fetched_input0;
    wire [31:0] fetched_input1;
    wire [31:0] fetched_weight0_a;
    wire [31:0] fetched_weight0_b;
    wire [31:0] fetched_weight1_a;
    wire [31:0] fetched_weight1_b;
    wire [31:0] fetched_bias0;
    wire [31:0] fetched_bias1;
    wire [31:0] fetch_status;
    wire [31:0] fetch_count;
    wire [31:0] fetch_error_count;
    wire [31:0] m_axi_araddr;
    wire [7:0]  m_axi_arlen;
    wire [2:0]  m_axi_arsize;
    wire [1:0]  m_axi_arburst;
    wire        m_axi_arvalid;
    wire        m_axi_rready;

    reg [31:0] read_addr_q;
    reg [7:0]  read_len_q;
    reg [2:0]  read_beat_q;
    reg        read_active;

    function [31:0] umem_word;
        input [31:0] addr;
        begin
            case (addr)
                32'h1000_0400: umem_word = 32'h0002_0001;
                32'h1000_0404: umem_word = 32'h0004_0003;
                32'h1000_0420: umem_word = 32'h0002_0002;
                32'h1000_0424: umem_word = 32'h0002_0002;
                32'h1000_0428: umem_word = 32'h0200_0200;
                32'h1000_042C: umem_word = 32'h0200_0200;
                32'h1000_0430: umem_word = 32'h0000_0000;
                32'h1000_0434: umem_word = 32'h0000_0000;
                default:       umem_word = 32'hDEAD_BEEF;
            endcase
        end
    endfunction

    accel_npu_payload_fetch_stub dut (
        .clk(clk),
        .resetn(resetn),
        .enable(enable),
        .umem_base_addr(umem_base_addr),
        .dispatch_valid(dispatch_valid),
        .model_id_in(model_id_in),
        .seq_length_in(seq_length_in),
        .input_offset_in(input_offset_in),
        .weight_offset_in(weight_offset_in),
        .output_offset_in(output_offset_in),
        .shadow_input0(shadow_input0),
        .shadow_input1(shadow_input1),
        .shadow_weight0_a(shadow_weight0_a),
        .shadow_weight0_b(shadow_weight0_b),
        .shadow_weight1_a(shadow_weight1_a),
        .shadow_weight1_b(shadow_weight1_b),
        .shadow_bias0(shadow_bias0),
        .shadow_bias1(shadow_bias1),
        .payload_valid(payload_valid),
        .model_id_out(model_id_out),
        .seq_length_out(seq_length_out),
        .input_offset_out(input_offset_out),
        .weight_offset_out(weight_offset_out),
        .output_offset_out(output_offset_out),
        .fetched_input0(fetched_input0),
        .fetched_input1(fetched_input1),
        .fetched_weight0_a(fetched_weight0_a),
        .fetched_weight0_b(fetched_weight0_b),
        .fetched_weight1_a(fetched_weight1_a),
        .fetched_weight1_b(fetched_weight1_b),
        .fetched_bias0(fetched_bias0),
        .fetched_bias1(fetched_bias1),
        .fetch_status(fetch_status),
        .fetch_count(fetch_count),
        .fetch_error_count(fetch_error_count),
        .m_axi_araddr(m_axi_araddr),
        .m_axi_arlen(m_axi_arlen),
        .m_axi_arsize(m_axi_arsize),
        .m_axi_arburst(m_axi_arburst),
        .m_axi_arvalid(m_axi_arvalid),
        .m_axi_arready(m_axi_arready),
        .m_axi_rdata(m_axi_rdata),
        .m_axi_rresp(m_axi_rresp),
        .m_axi_rlast(m_axi_rlast),
        .m_axi_rvalid(m_axi_rvalid),
        .m_axi_rready(m_axi_rready)
    );

    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (!resetn) begin
            m_axi_rdata <= 32'h0000_0000;
            m_axi_rresp <= 2'b00;
            m_axi_rlast <= 1'b0;
            m_axi_rvalid <= 1'b0;
            read_addr_q <= 32'h0000_0000;
            read_len_q <= 8'h00;
            read_beat_q <= 3'd0;
            read_active <= 1'b0;
        end else begin
            if (m_axi_arvalid && m_axi_arready) begin
                read_addr_q <= m_axi_araddr;
                read_len_q <= m_axi_arlen;
                read_beat_q <= 3'd0;
                read_active <= 1'b1;
                m_axi_rdata <= umem_word(m_axi_araddr);
                m_axi_rresp <= 2'b00;
                m_axi_rlast <= (m_axi_arlen == 8'd0);
                m_axi_rvalid <= 1'b1;
            end else if (read_active && m_axi_rvalid && m_axi_rready) begin
                if (m_axi_rlast) begin
                    read_active <= 1'b0;
                    m_axi_rvalid <= 1'b0;
                    m_axi_rlast <= 1'b0;
                end else begin
                    read_addr_q <= read_addr_q + 32'd4;
                    read_beat_q <= read_beat_q + 3'd1;
                    m_axi_rdata <= umem_word(read_addr_q + 32'd4);
                    m_axi_rresp <= 2'b00;
                    m_axi_rlast <= ((read_beat_q + 3'd1) == read_len_q[2:0]);
                end
            end
        end
    end

    initial begin
        clk = 1'b0;
        resetn = 1'b0;
        enable = 1'b0;
        umem_base_addr = 32'h1000_0000;
        dispatch_valid = 1'b0;
        model_id_in = 8'h00;
        seq_length_in = 16'h0000;
        input_offset_in = 32'h0000_0000;
        weight_offset_in = 32'h0000_0000;
        output_offset_in = 32'h0000_0000;
        shadow_input0 = 32'h0000_0000;
        shadow_input1 = 32'h0000_0000;
        shadow_weight0_a = 32'h0000_0000;
        shadow_weight0_b = 32'h0000_0000;
        shadow_weight1_a = 32'h0000_0000;
        shadow_weight1_b = 32'h0000_0000;
        shadow_bias0 = 32'h0000_0000;
        shadow_bias1 = 32'h0000_0000;
        m_axi_arready = 1'b1;
        m_axi_rdata = 32'h0000_0000;
        m_axi_rresp = 2'b00;
        m_axi_rlast = 1'b0;
        m_axi_rvalid = 1'b0;

        repeat (6) @(posedge clk);
        resetn = 1'b1;
        enable = 1'b1;

        @(negedge clk);
        model_id_in = 8'h80;
        seq_length_in = 16'h0008;
        input_offset_in = 32'h0000_0400;
        weight_offset_in = 32'h0000_0420;
        output_offset_in = 32'h0000_0480;
        dispatch_valid = 1'b1;

        @(posedge clk);
        @(negedge clk);
        dispatch_valid = 1'b0;

        wait (payload_valid == 1'b1);
        if (model_id_out !== 8'h80 || seq_length_out !== 16'h0008) begin
            $display("FAIL: payload fetch metadata mismatch.");
            $finish;
        end

        if (input_offset_out !== 32'h0000_0400 || weight_offset_out !== 32'h0000_0420 ||
            output_offset_out !== 32'h0000_0480) begin
            $display("FAIL: payload fetch offsets mismatch.");
            $finish;
        end

        if (fetched_input0 !== 32'h0002_0001 || fetched_input1 !== 32'h0004_0003 ||
            fetched_weight0_a !== 32'h0002_0002 || fetched_weight0_b !== 32'h0002_0002 ||
            fetched_weight1_a !== 32'h0200_0200 || fetched_weight1_b !== 32'h0200_0200 ||
            fetched_bias0 !== 32'h0000_0000 || fetched_bias1 !== 32'h0000_0000) begin
            $display("FAIL: payload fetch data mismatch.");
            $finish;
        end

        @(posedge clk);
        if (fetch_status !== 32'h0000_0004 || fetch_count !== 32'h0000_0001 || fetch_error_count !== 32'h0000_0000) begin
            $display("FAIL: payload fetch counters/status mismatch. status=%08x count=%08x err=%08x",
                     fetch_status, fetch_count, fetch_error_count);
            $finish;
        end

        if (m_axi_arsize !== 3'b010 || m_axi_arburst !== 2'b01) begin
            $display("FAIL: payload fetch AXI metadata mismatch.");
            $finish;
        end

        $display("PASS: NPU payload fetch stub regression completed.");
        $finish;
    end
endmodule
