module accel_cmdq_frontend_stub (
    input  wire        clk,
    input  wire        resetn,
    input  wire        enable,
    input  wire [31:0] cmdq_base_offset,
    input  wire [31:0] cmdq_size_bytes,
    input  wire [31:0] cmdq_head,
    input  wire [31:0] cmdq_tail_seed,
    input  wire [31:0] cmdq_doorbell,
    output reg  [31:0] cmdq_tail_shadow,
    output reg  [31:0] cmdq_status,
    output reg         fetch_valid,
    output reg  [15:0] fetch_slot,
    output reg  [31:0] fetch_offset,
    output reg  [31:0] fetch_sequence,
    input  wire        fetch_ready,
    input  wire        desc_done,
    input  wire        desc_error
);
    localparam [31:0] CMDQ_STATUS_BUSY  = 32'h0000_0001;
    localparam [31:0] CMDQ_STATUS_ERROR = 32'h0000_0002;
    localparam [31:0] CMDQ_STATUS_EMPTY = 32'h0000_0004;

    reg [31:0] processed_count;
    reg [31:0] last_doorbell;
    reg        fetch_inflight;
    reg [31:0] error_sticky;

    wire [31:0] entry_count_raw = cmdq_size_bytes >> 5;
    wire [31:0] entry_count = (entry_count_raw == 32'd0) ? 32'd1 : entry_count_raw;
    wire [31:0] tail_slot = cmdq_tail_shadow % entry_count;
    wire        queue_empty = (cmdq_head == cmdq_tail_shadow);

    always @(posedge clk) begin
        if (!resetn) begin
            cmdq_tail_shadow <= 32'h0000_0000;
            cmdq_status <= CMDQ_STATUS_EMPTY;
            fetch_valid <= 1'b0;
            fetch_slot <= 16'h0000;
            fetch_offset <= 32'h0000_0000;
            fetch_sequence <= 32'h0000_0000;
            processed_count <= 32'h0000_0000;
            last_doorbell <= 32'h0000_0000;
            fetch_inflight <= 1'b0;
            error_sticky <= 32'h0000_0000;
        end else begin
            if (!enable) begin
                cmdq_tail_shadow <= cmdq_tail_seed;
                cmdq_status <= (cmdq_head == cmdq_tail_seed) ? CMDQ_STATUS_EMPTY : 32'h0000_0000;
                fetch_valid <= 1'b0;
                fetch_slot <= 16'h0000;
                fetch_offset <= 32'h0000_0000;
                fetch_sequence <= 32'h0000_0000;
                processed_count <= 32'h0000_0000;
                last_doorbell <= cmdq_doorbell;
                fetch_inflight <= 1'b0;
                error_sticky <= 32'h0000_0000;
            end else begin
                last_doorbell <= cmdq_doorbell;

                if (!fetch_valid && !fetch_inflight && !queue_empty && (cmdq_doorbell != last_doorbell)) begin
                    fetch_valid <= 1'b1;
                    fetch_slot <= tail_slot[15:0];
                    fetch_offset <= cmdq_base_offset + (tail_slot << 5);
                    fetch_sequence <= processed_count;
                end

                if (fetch_valid && fetch_ready) begin
                    fetch_valid <= 1'b0;
                    fetch_inflight <= 1'b1;
                end

                if (fetch_inflight && desc_done) begin
                    fetch_inflight <= 1'b0;
                    cmdq_tail_shadow <= (cmdq_tail_shadow + 32'd1) % entry_count;
                    processed_count <= processed_count + 32'd1;
                    if (desc_error) begin
                        error_sticky <= 32'h0000_0001;
                    end
                end

                cmdq_status <=
                    (((processed_count + ((fetch_inflight && desc_done) ? 32'd1 : 32'd0)) & 32'h0000_FFFF) << 16) |
                    ((error_sticky != 32'h0000_0000 || desc_error) ? CMDQ_STATUS_ERROR : 32'h0000_0000) |
                    ((!fetch_valid && !fetch_inflight &&
                      (cmdq_head == ((fetch_inflight && desc_done) ? ((cmdq_tail_shadow + 32'd1) % entry_count) : cmdq_tail_shadow)))
                        ? CMDQ_STATUS_EMPTY : 32'h0000_0000) |
                    ((fetch_valid || fetch_inflight) ? CMDQ_STATUS_BUSY : 32'h0000_0000);
            end
        end
    end
endmodule
