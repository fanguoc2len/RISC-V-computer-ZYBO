`timescale 1ns / 1ps

module accel_npu_queue_runtime_mlp_tb;
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
    reg [31:0] shadow_input0;
    reg [31:0] shadow_input1;
    reg [31:0] shadow_weight0_a;
    reg [31:0] shadow_weight0_b;
    reg [31:0] shadow_weight1_a;
    reg [31:0] shadow_weight1_b;
    reg [31:0] shadow_bias0;
    reg [31:0] shadow_bias1;
    reg [31:0] umem_base_addr;
    reg        m_axi_arready;
    reg [31:0] m_axi_rdata;
    reg [1:0]  m_axi_rresp;
    reg        m_axi_rlast;
    reg        m_axi_rvalid;
    reg        m_axi_awready;
    reg        m_axi_wready;
    reg [1:0]  m_axi_bresp;
    reg        m_axi_bvalid;

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

    wire        payload_valid;
    wire [7:0]  payload_model_id;
    wire [15:0] payload_seq_length;
    wire [31:0] payload_input_offset;
    wire [31:0] payload_weight_offset;
    wire [31:0] payload_output_offset;
    wire [31:0] payload_input0;
    wire [31:0] payload_input1;
    wire [31:0] payload_weight0_a;
    wire [31:0] payload_weight0_b;
    wire [31:0] payload_weight1_a;
    wire [31:0] payload_weight1_b;
    wire [31:0] payload_bias0;
    wire [31:0] payload_bias1;
    wire [31:0] payload_fetch_status;
    wire [31:0] payload_fetch_count;
    wire [31:0] payload_fetch_error_count;
    wire [31:0] payload_m_axi_araddr;
    wire [7:0]  payload_m_axi_arlen;
    wire [2:0]  payload_m_axi_arsize;
    wire [1:0]  payload_m_axi_arburst;
    wire        payload_m_axi_arvalid;
    wire        payload_m_axi_rready;

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

    wire [31:0] store_status;
    wire [31:0] store_count;
    wire [31:0] store_error_count;
    wire [31:0] store_last_output_offset;
    wire [31:0] store_last_awaddr;
    wire [31:0] stored_status_word;
    wire [31:0] stored_logit0;
    wire [31:0] stored_logit1;
    wire [31:0] stored_class_word;
    wire [31:0] stored_hidden0;
    wire [31:0] stored_hidden1;
    wire [31:0] m_axi_awaddr;
    wire [7:0]  m_axi_awlen;
    wire [2:0]  m_axi_awsize;
    wire [1:0]  m_axi_awburst;
    wire        m_axi_awvalid;
    wire [31:0] m_axi_wdata;
    wire [3:0]  m_axi_wstrb;
    wire        m_axi_wlast;
    wire        m_axi_wvalid;
    wire        m_axi_bready;

    reg [31:0] write_words [0:5];
    integer write_count;
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
                32'h1000_0430: umem_word = 32'hFFFF_FFF8;
                32'h1000_0434: umem_word = 32'hFFFF_FFF8;
                default:       umem_word = 32'hDEAD_BEEF;
            endcase
        end
    endfunction

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

    accel_npu_payload_fetch_stub payload_dut (
        .clk(clk),
        .resetn(resetn),
        .enable(enable),
        .umem_base_addr(umem_base_addr),
        .dispatch_valid(npu_dispatch_pulse),
        .model_id_in(npu_model_id_out),
        .seq_length_in(npu_seq_length_out),
        .input_offset_in(npu_input_offset_out),
        .weight_offset_in(npu_weight_offset_out),
        .output_offset_in(npu_output_offset_out),
        .shadow_input0(shadow_input0),
        .shadow_input1(shadow_input1),
        .shadow_weight0_a(shadow_weight0_a),
        .shadow_weight0_b(shadow_weight0_b),
        .shadow_weight1_a(shadow_weight1_a),
        .shadow_weight1_b(shadow_weight1_b),
        .shadow_bias0(shadow_bias0),
        .shadow_bias1(shadow_bias1),
        .payload_valid(payload_valid),
        .model_id_out(payload_model_id),
        .seq_length_out(payload_seq_length),
        .input_offset_out(payload_input_offset),
        .weight_offset_out(payload_weight_offset),
        .output_offset_out(payload_output_offset),
        .fetched_input0(payload_input0),
        .fetched_input1(payload_input1),
        .fetched_weight0_a(payload_weight0_a),
        .fetched_weight0_b(payload_weight0_b),
        .fetched_weight1_a(payload_weight1_a),
        .fetched_weight1_b(payload_weight1_b),
        .fetched_bias0(payload_bias0),
        .fetched_bias1(payload_bias1),
        .fetch_status(payload_fetch_status),
        .fetch_count(payload_fetch_count),
        .fetch_error_count(payload_fetch_error_count),
        .m_axi_araddr(payload_m_axi_araddr),
        .m_axi_arlen(payload_m_axi_arlen),
        .m_axi_arsize(payload_m_axi_arsize),
        .m_axi_arburst(payload_m_axi_arburst),
        .m_axi_arvalid(payload_m_axi_arvalid),
        .m_axi_arready(m_axi_arready),
        .m_axi_rdata(m_axi_rdata),
        .m_axi_rresp(m_axi_rresp),
        .m_axi_rlast(m_axi_rlast),
        .m_axi_rvalid(m_axi_rvalid),
        .m_axi_rready(payload_m_axi_rready)
    );

    accel_npu_cmd_exec_stub exec_dut (
        .clk(clk),
        .resetn(resetn),
        .enable(enable),
        .dispatch_valid(payload_valid),
        .model_id_in(payload_model_id),
        .seq_length_in(payload_seq_length),
        .input_offset_in(payload_input_offset),
        .weight_offset_in(payload_weight_offset),
        .output_offset_in(payload_output_offset),
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
        .input_vec0(payload_input0),
        .input_vec1(payload_input1),
        .runtime_weight0_a(payload_weight0_a),
        .runtime_weight0_b(payload_weight0_b),
        .runtime_weight1_a(payload_weight1_a),
        .runtime_weight1_b(payload_weight1_b),
        .runtime_bias0(payload_bias0),
        .runtime_bias1(payload_bias1),
        .busy(npu_busy),
        .done(npu_done),
        .status_word(npu_status_word),
        .logit0(npu_logit0),
        .logit1(npu_logit1),
        .class_id(npu_class_id),
        .hidden0(npu_hidden0),
        .hidden1(npu_hidden1)
    );

    accel_npu_result_store_stub store_dut (
        .clk(clk),
        .resetn(resetn),
        .enable(enable),
        .store_request_valid(store_request_pulse),
        .umem_base_addr(umem_base_addr),
        .output_offset_in(last_output_offset),
        .status_word_in(npu_status_word),
        .logit0_in(npu_logit0),
        .logit1_in(npu_logit1),
        .class_id_in(npu_class_id),
        .hidden0_in(npu_hidden0),
        .hidden1_in(npu_hidden1),
        .store_status(store_status),
        .store_count(store_count),
        .store_error_count(store_error_count),
        .last_output_offset(store_last_output_offset),
        .last_awaddr(store_last_awaddr),
        .stored_status_word(stored_status_word),
        .stored_logit0(stored_logit0),
        .stored_logit1(stored_logit1),
        .stored_class_word(stored_class_word),
        .stored_hidden0(stored_hidden0),
        .stored_hidden1(stored_hidden1),
        .m_axi_awaddr(m_axi_awaddr),
        .m_axi_awlen(m_axi_awlen),
        .m_axi_awsize(m_axi_awsize),
        .m_axi_awburst(m_axi_awburst),
        .m_axi_awvalid(m_axi_awvalid),
        .m_axi_awready(m_axi_awready),
        .m_axi_wdata(m_axi_wdata),
        .m_axi_wstrb(m_axi_wstrb),
        .m_axi_wlast(m_axi_wlast),
        .m_axi_wvalid(m_axi_wvalid),
        .m_axi_wready(m_axi_wready),
        .m_axi_bresp(m_axi_bresp),
        .m_axi_bvalid(m_axi_bvalid),
        .m_axi_bready(m_axi_bready)
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
            if (payload_m_axi_arvalid && m_axi_arready) begin
                read_addr_q <= payload_m_axi_araddr;
                read_len_q <= payload_m_axi_arlen;
                read_beat_q <= 3'd0;
                read_active <= 1'b1;
                m_axi_rdata <= umem_word(payload_m_axi_araddr);
                m_axi_rresp <= 2'b00;
                m_axi_rlast <= (payload_m_axi_arlen == 8'd0);
                m_axi_rvalid <= 1'b1;
            end else if (read_active && m_axi_rvalid && payload_m_axi_rready) begin
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

    always @(posedge clk) begin
        if (!resetn) begin
            m_axi_bvalid <= 1'b0;
        end else begin
            if (m_axi_wvalid && m_axi_wready && m_axi_wlast) begin
                m_axi_bvalid <= 1'b1;
            end else if (m_axi_bvalid && m_axi_bready) begin
                m_axi_bvalid <= 1'b0;
            end
        end
    end

    always @(posedge clk) begin
        if (!resetn) begin
            write_count <= 0;
        end else if (m_axi_wvalid && m_axi_wready) begin
            if (write_count < 6) begin
                write_words[write_count] <= m_axi_wdata;
            end
            write_count <= write_count + 1;
        end
    end

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
        shadow_input0 = 32'h0000_0000;
        shadow_input1 = 32'h0000_0000;
        shadow_weight0_a = 32'h0000_0000;
        shadow_weight0_b = 32'h0000_0000;
        shadow_weight1_a = 32'h0000_0000;
        shadow_weight1_b = 32'h0000_0000;
        shadow_bias0 = 32'h0000_0000;
        shadow_bias1 = 32'h0000_0000;
        umem_base_addr = 32'h1000_0000;
        m_axi_arready = 1'b1;
        m_axi_rdata = 32'h0000_0000;
        m_axi_rresp = 2'b00;
        m_axi_rlast = 1'b0;
        m_axi_rvalid = 1'b0;
        m_axi_awready = 1'b1;
        m_axi_wready = 1'b1;
        m_axi_bresp = 2'b00;
        m_axi_bvalid = 1'b0;
        write_count = 0;

        repeat (6) @(posedge clk);
        resetn = 1'b1;
        enable = 1'b1;

        @(negedge clk);
        desc_opcode = 32'h0000_0001;
        desc_flags = 32'h0000_0081;
        desc_src0 = 32'h0000_0400;
        desc_src1 = 32'h0000_0420;
        desc_dst0 = 32'h0000_0480;
        desc_arg0 = 32'h0000_0008;
        npu_model_id_in = 8'h81;
        npu_seq_length_in = 16'h0008;
        decode_valid = 1'b1;

        @(posedge clk);
        @(negedge clk);
        decode_valid = 1'b0;

        wait (npu_done == 1'b1);
        wait (m_axi_bvalid == 1'b1);
        wait (m_axi_bready == 1'b1);
        @(posedge clk);
        @(posedge clk);

        if (dispatch_status !== 32'h0000_0004 || payload_fetch_status !== 32'h0000_0004 ||
            exec_status !== 32'h0001_8104 || store_status !== 32'h0001_0004) begin
            $display("FAIL: runtime MLP queue status mismatch. dispatch=%08x fetch=%08x exec=%08x store=%08x",
                     dispatch_status, payload_fetch_status, exec_status, store_status);
            $finish;
        end

        if (payload_m_axi_arsize !== 3'b010 || payload_m_axi_arburst !== 2'b01) begin
            $display("FAIL: runtime MLP payload AXI metadata mismatch.");
            $finish;
        end

        if (last_input_offset !== 32'h0000_0400 || last_weight_offset !== 32'h0000_0420 ||
            last_output_offset !== 32'h0000_0480 || store_last_output_offset !== 32'h0000_0480) begin
            $display("FAIL: runtime MLP offsets mismatch.");
            $finish;
        end

        if (!store_request_pulse) begin
            $display("FAIL: runtime MLP queue path did not emit store_request_pulse.");
            $finish;
        end

        if (npu_status_word !== 32'h4E00_8108 || npu_logit0 !== 32'h0000_000C ||
            npu_logit1 !== 32'hFFFF_FFF4 || npu_class_id !== 8'h00 ||
            npu_hidden0 !== 32'h0000_000C || npu_hidden1 !== 32'h0000_0000) begin
            $display("FAIL: runtime MLP NPU result mismatch.");
            $finish;
        end

        if (store_count !== 32'h0000_0001 || store_error_count !== 32'h0000_0000 ||
            store_last_awaddr !== 32'h1000_0480 || m_axi_awaddr !== 32'h1000_0480 ||
            m_axi_awlen !== 8'd5 || m_axi_awsize !== 3'b010 || m_axi_awburst !== 2'b01) begin
            $display("FAIL: runtime MLP AXI metadata mismatch.");
            $finish;
        end

        if (stored_status_word !== 32'h4E00_8108 || stored_logit0 !== 32'h0000_000C ||
            stored_logit1 !== 32'hFFFF_FFF4 || stored_class_word !== 32'h0000_0000 ||
            stored_hidden0 !== 32'h0000_000C || stored_hidden1 !== 32'h0000_0000) begin
            $display("FAIL: runtime MLP stored payload mismatch.");
            $finish;
        end

        if (write_count !== 6 ||
            write_words[0] !== 32'h4E00_8108 ||
            write_words[1] !== 32'h0000_000C ||
            write_words[2] !== 32'hFFFF_FFF4 ||
            write_words[3] !== 32'h0000_0000 ||
            write_words[4] !== 32'h0000_000C ||
            write_words[5] !== 32'h0000_0000) begin
            $display("FAIL: runtime MLP AXI beats mismatch.");
            $finish;
        end

        $display("PASS: NPU queue runtime-MLP regression completed.");
        $finish;
    end
endmodule
