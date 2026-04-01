`timescale 1ns / 1ps

module accel_umem_axi_fetch_stub_tb;
    reg clk;
    reg resetn;
    reg enable;
    reg fetch_valid;
    reg [31:0] umem_base_addr;
    reg [31:0] fetch_offset;
    reg [31:0] fetch_sequence;
    wire fetch_ready;
    wire desc_done;
    wire desc_error;
    wire [31:0] desc_status;
    wire [31:0] last_araddr;
    wire [31:0] last_sequence;
    wire [3:0] beat_count;
    wire [255:0] desc_data_flat;
    wire [31:0] m_axi_araddr;
    wire [7:0] m_axi_arlen;
    wire [2:0] m_axi_arsize;
    wire [1:0] m_axi_arburst;
    wire m_axi_arvalid;
    reg  m_axi_arready;
    reg [31:0] m_axi_rdata;
    reg [1:0] m_axi_rresp;
    reg m_axi_rlast;
    reg m_axi_rvalid;
    wire m_axi_rready;
    integer i;

    accel_umem_axi_fetch_stub dut (
        .clk(clk),
        .resetn(resetn),
        .enable(enable),
        .umem_base_addr(umem_base_addr),
        .fetch_valid(fetch_valid),
        .fetch_offset(fetch_offset),
        .fetch_sequence(fetch_sequence),
        .fetch_ready(fetch_ready),
        .desc_done(desc_done),
        .desc_error(desc_error),
        .desc_status(desc_status),
        .last_araddr(last_araddr),
        .last_sequence(last_sequence),
        .beat_count(beat_count),
        .desc_data_flat(desc_data_flat),
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

    initial begin
        clk = 1'b0;
        resetn = 1'b0;
        enable = 1'b0;
        fetch_valid = 1'b0;
        umem_base_addr = 32'h1000_0000;
        fetch_offset = 32'h0000_2000;
        fetch_sequence = 32'h0000_0003;
        m_axi_arready = 1'b0;
        m_axi_rdata = 32'h0000_0000;
        m_axi_rresp = 2'b00;
        m_axi_rlast = 1'b0;
        m_axi_rvalid = 1'b0;

        repeat (6) @(posedge clk);
        resetn = 1'b1;
        enable = 1'b1;
        @(posedge clk);

        fetch_valid = 1'b1;
        m_axi_arready = 1'b1;
        @(posedge clk);
        fetch_valid = 1'b0;
        m_axi_arready = 1'b0;

        if (!fetch_ready) begin
            $display("FAIL: fetch_ready did not pulse.");
            $finish;
        end

        if (last_araddr !== 32'h1000_2000) begin
            $display("FAIL: unexpected ARADDR. got=%08x", last_araddr);
            $finish;
        end

        if (m_axi_arlen !== 8'd7 || m_axi_arsize !== 3'b010 || m_axi_arburst !== 2'b01) begin
            $display("FAIL: unexpected AXI burst shape.");
            $finish;
        end

        for (i = 0; i < 8; i = i + 1) begin
            @(posedge clk);
            m_axi_rvalid = 1'b1;
            m_axi_rdata = 32'hA500_0000 + i;
            m_axi_rresp = 2'b00;
            m_axi_rlast = (i == 7);
        end
        @(posedge clk);
        m_axi_rvalid = 1'b0;
        m_axi_rlast = 1'b0;

        if (!desc_done) begin
            $display("FAIL: desc_done did not pulse.");
            $finish;
        end

        if (desc_error) begin
            $display("FAIL: desc_error asserted unexpectedly.");
            $finish;
        end

        if (desc_status !== 32'h0000_0004) begin
            $display("FAIL: desc_status not idle after burst. got=%08x", desc_status);
            $finish;
        end

        if (last_sequence !== 32'h0000_0003) begin
            $display("FAIL: last_sequence mismatch. got=%08x", last_sequence);
            $finish;
        end

        if (desc_data_flat[31:0] !== 32'hA500_0000 || desc_data_flat[255:224] !== 32'hA500_0007) begin
            $display("FAIL: descriptor data packing mismatch.");
            $finish;
        end

        $display("PASS: unified-memory AXI fetch stub regression completed.");
        $finish;
    end
endmodule
