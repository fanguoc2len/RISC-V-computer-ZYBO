`timescale 1ns / 1ps

module accel_cmdq_frontend_stub_tb;
    localparam [31:0] EXPECT_STATUS_EMPTY = 32'h0000_0004;
    localparam [31:0] EXPECT_STATUS_BUSY  = 32'h0000_0001;
    localparam [31:0] EXPECT_STATUS_DONE1 = 32'h0001_0004;
    localparam [31:0] EXPECT_STATUS_DONE2 = 32'h0002_0004;

    reg clk;
    reg resetn;
    reg enable;
    reg [31:0] cmdq_base_offset;
    reg [31:0] cmdq_size_bytes;
    reg [31:0] cmdq_head;
    reg [31:0] cmdq_tail_seed;
    reg [31:0] cmdq_doorbell;
    wire [31:0] cmdq_tail_shadow;
    wire [31:0] cmdq_status;
    wire        fetch_valid;
    wire [15:0] fetch_slot;
    wire [31:0] fetch_offset;
    wire [31:0] fetch_sequence;
    reg         fetch_ready;
    reg         desc_done;
    reg         desc_error;

    accel_cmdq_frontend_stub dut (
        .clk(clk),
        .resetn(resetn),
        .enable(enable),
        .cmdq_base_offset(cmdq_base_offset),
        .cmdq_size_bytes(cmdq_size_bytes),
        .cmdq_head(cmdq_head),
        .cmdq_tail_seed(cmdq_tail_seed),
        .cmdq_doorbell(cmdq_doorbell),
        .cmdq_tail_shadow(cmdq_tail_shadow),
        .cmdq_status(cmdq_status),
        .fetch_valid(fetch_valid),
        .fetch_slot(fetch_slot),
        .fetch_offset(fetch_offset),
        .fetch_sequence(fetch_sequence),
        .fetch_ready(fetch_ready),
        .desc_done(desc_done),
        .desc_error(desc_error)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 1'b0;
        resetn = 1'b0;
        enable = 1'b0;
        cmdq_base_offset = 32'h0000_2000;
        cmdq_size_bytes = 32'h0000_0100;
        cmdq_head = 32'h0000_0000;
        cmdq_tail_seed = 32'h0000_0000;
        cmdq_doorbell = 32'h0000_0000;
        fetch_ready = 1'b0;
        desc_done = 1'b0;
        desc_error = 1'b0;

        repeat (8) @(posedge clk);
        resetn = 1'b1;
        repeat (2) @(posedge clk);

        if (cmdq_status !== EXPECT_STATUS_EMPTY) begin
            $display("FAIL: expected empty status after reset. got=%08x", cmdq_status);
            $finish;
        end

        enable <= 1'b1;
        cmdq_head <= 32'h0000_0002;
        cmdq_doorbell <= 32'h0000_0002;
        @(posedge clk);

        if (!fetch_valid) begin
            $display("FAIL: fetch_valid did not assert after first doorbell.");
            $finish;
        end

        if (fetch_slot !== 16'h0000) begin
            $display("FAIL: expected first fetch slot 0. got=%04x", fetch_slot);
            $finish;
        end

        if (fetch_offset !== 32'h0000_2000) begin
            $display("FAIL: expected first fetch offset 0x2000. got=%08x", fetch_offset);
            $finish;
        end

        if (cmdq_status !== EXPECT_STATUS_BUSY) begin
            $display("FAIL: expected busy status during first fetch. got=%08x", cmdq_status);
            $finish;
        end

        fetch_ready <= 1'b1;
        @(posedge clk);
        fetch_ready <= 1'b0;
        desc_done <= 1'b1;
        @(posedge clk);
        desc_done <= 1'b0;
        @(posedge clk);

        if (cmdq_tail_shadow !== 32'h0000_0001) begin
            $display("FAIL: expected tail shadow 1 after first retire. got=%08x", cmdq_tail_shadow);
            $finish;
        end

        if (cmdq_status !== EXPECT_STATUS_DONE1) begin
            $display("FAIL: expected status after first retire. got=%08x", cmdq_status);
            $finish;
        end

        cmdq_head <= 32'h0000_0002;
        cmdq_doorbell <= 32'h0000_0003;
        @(posedge clk);

        if (!fetch_valid) begin
            $display("FAIL: fetch_valid did not assert for second descriptor.");
            $finish;
        end

        if (fetch_slot !== 16'h0001) begin
            $display("FAIL: expected second fetch slot 1. got=%04x", fetch_slot);
            $finish;
        end

        if (fetch_offset !== 32'h0000_2020) begin
            $display("FAIL: expected second fetch offset 0x2020. got=%08x", fetch_offset);
            $finish;
        end

        fetch_ready <= 1'b1;
        @(posedge clk);
        fetch_ready <= 1'b0;
        desc_done <= 1'b1;
        @(posedge clk);
        desc_done <= 1'b0;
        @(posedge clk);

        if (cmdq_tail_shadow !== 32'h0000_0002) begin
            $display("FAIL: expected tail shadow 2 after second retire. got=%08x", cmdq_tail_shadow);
            $finish;
        end

        if (cmdq_status !== EXPECT_STATUS_DONE2) begin
            $display("FAIL: expected final empty status after two retires. got=%08x", cmdq_status);
            $finish;
        end

        $display("PASS: command-queue frontend stub regression completed.");
        $finish;
    end
endmodule
