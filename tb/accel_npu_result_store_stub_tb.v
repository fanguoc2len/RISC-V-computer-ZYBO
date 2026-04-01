`timescale 1ns / 1ps

module accel_npu_result_store_stub_tb;
    reg clk;
    reg resetn;
    reg enable;
    reg store_request_valid;
    reg [31:0] umem_base_addr;
    reg [31:0] output_offset_in;
    reg [31:0] status_word_in;
    reg [31:0] logit0_in;
    reg [31:0] logit1_in;
    reg [7:0]  class_id_in;
    reg [31:0] hidden0_in;
    reg [31:0] hidden1_in;
    reg        m_axi_awready;
    reg        m_axi_wready;
    reg [1:0]  m_axi_bresp;
    reg        m_axi_bvalid;

    wire [31:0] store_status;
    wire [31:0] store_count;
    wire [31:0] store_error_count;
    wire [31:0] last_output_offset;
    wire [31:0] last_awaddr;
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

    accel_npu_result_store_stub dut (
        .clk(clk),
        .resetn(resetn),
        .enable(enable),
        .store_request_valid(store_request_valid),
        .umem_base_addr(umem_base_addr),
        .output_offset_in(output_offset_in),
        .status_word_in(status_word_in),
        .logit0_in(logit0_in),
        .logit1_in(logit1_in),
        .class_id_in(class_id_in),
        .hidden0_in(hidden0_in),
        .hidden1_in(hidden1_in),
        .store_status(store_status),
        .store_count(store_count),
        .store_error_count(store_error_count),
        .last_output_offset(last_output_offset),
        .last_awaddr(last_awaddr),
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
        store_request_valid = 1'b0;
        umem_base_addr = 32'h1000_0000;
        output_offset_in = 32'h0000_0480;
        status_word_in = 32'h4E00_8008;
        logit0_in = 32'h0000_0014;
        logit1_in = 32'h0000_0000;
        class_id_in = 8'h00;
        hidden0_in = 32'h0000_0014;
        hidden1_in = 32'h0000_0000;
        m_axi_awready = 1'b1;
        m_axi_wready = 1'b1;
        m_axi_bresp = 2'b00;
        m_axi_bvalid = 1'b0;
        write_count = 0;

        repeat (6) @(posedge clk);
        resetn = 1'b1;
        enable = 1'b1;

        @(negedge clk);
        store_request_valid = 1'b1;

        @(posedge clk);
        @(negedge clk);
        store_request_valid = 1'b0;

        wait (m_axi_bvalid == 1'b1);
        wait (m_axi_bready == 1'b1);
        @(posedge clk);
        @(posedge clk);

        if (m_axi_awaddr !== 32'h1000_0480 || m_axi_awlen !== 8'd5 ||
            m_axi_awsize !== 3'b010 || m_axi_awburst !== 2'b01) begin
            $display("FAIL: result store AXI AW mismatch.");
            $finish;
        end

        if (last_output_offset !== 32'h0000_0480 || last_awaddr !== 32'h1000_0480) begin
            $display("FAIL: result store offsets mismatch.");
            $finish;
        end

        if (stored_status_word !== 32'h4E00_8008 || stored_logit0 !== 32'h0000_0014 ||
            stored_logit1 !== 32'h0000_0000 || stored_class_word !== 32'h0000_0000 ||
            stored_hidden0 !== 32'h0000_0014 || stored_hidden1 !== 32'h0000_0000) begin
            $display("FAIL: result store latched payload mismatch.");
            $finish;
        end

        if (write_count !== 6 ||
            write_words[0] !== 32'h4E00_8008 ||
            write_words[1] !== 32'h0000_0014 ||
            write_words[2] !== 32'h0000_0000 ||
            write_words[3] !== 32'h0000_0000 ||
            write_words[4] !== 32'h0000_0014 ||
            write_words[5] !== 32'h0000_0000) begin
            $display("FAIL: result store write beats mismatch.");
            $finish;
        end

        if (store_count !== 32'h0000_0001 || store_error_count !== 32'h0000_0000 ||
            store_status !== 32'h0001_0004) begin
            $display("FAIL: result store status mismatch. status=%08x count=%08x err=%08x",
                     store_status, store_count, store_error_count);
            $finish;
        end

        $display("PASS: NPU result store stub regression completed.");
        $finish;
    end
endmodule
