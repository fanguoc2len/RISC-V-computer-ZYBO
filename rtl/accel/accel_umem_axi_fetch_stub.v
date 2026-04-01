module accel_umem_axi_fetch_stub (
    input  wire        clk,
    input  wire        resetn,
    input  wire        enable,
    input  wire [31:0] umem_base_addr,
    input  wire        fetch_valid,
    input  wire [31:0] fetch_offset,
    input  wire [31:0] fetch_sequence,
    output reg         fetch_ready,
    output reg         desc_done,
    output reg         desc_error,
    output reg  [31:0] desc_status,
    output reg  [31:0] last_araddr,
    output reg  [31:0] last_sequence,
    output reg  [3:0]  beat_count,
    output reg  [255:0] desc_data_flat,
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
    localparam [31:0] STATUS_IDLE  = 32'h0000_0004;
    localparam [31:0] STATUS_BUSY  = 32'h0000_0001;
    localparam [31:0] STATUS_ERROR = 32'h0000_0002;

    reg active;

    always @(posedge clk) begin
        if (!resetn) begin
            fetch_ready <= 1'b0;
            desc_done <= 1'b0;
            desc_error <= 1'b0;
            desc_status <= STATUS_IDLE;
            last_araddr <= 32'h0000_0000;
            last_sequence <= 32'h0000_0000;
            beat_count <= 4'h0;
            desc_data_flat <= 256'h0;
            m_axi_araddr <= 32'h0000_0000;
            m_axi_arlen <= 8'd7;
            m_axi_arsize <= 3'b010;
            m_axi_arburst <= 2'b01;
            m_axi_arvalid <= 1'b0;
            m_axi_rready <= 1'b0;
            active <= 1'b0;
        end else begin
            fetch_ready <= 1'b0;
            desc_done <= 1'b0;
            desc_error <= 1'b0;

            if (!enable) begin
                desc_status <= STATUS_IDLE;
                m_axi_arvalid <= 1'b0;
                m_axi_rready <= 1'b0;
                beat_count <= 4'h0;
                desc_data_flat <= 256'h0;
                active <= 1'b0;
            end else begin
                if (!active && fetch_valid) begin
                    m_axi_araddr <= umem_base_addr + fetch_offset;
                    m_axi_arlen <= 8'd7;
                    m_axi_arsize <= 3'b010;
                    m_axi_arburst <= 2'b01;
                    m_axi_arvalid <= 1'b1;
                    m_axi_rready <= 1'b0;
                    desc_status <= STATUS_BUSY;
                    beat_count <= 4'h0;
                    desc_data_flat <= 256'h0;
                    last_sequence <= fetch_sequence;
                end

                if (m_axi_arvalid && m_axi_arready) begin
                    m_axi_arvalid <= 1'b0;
                    m_axi_rready <= 1'b1;
                    fetch_ready <= 1'b1;
                    active <= 1'b1;
                    last_araddr <= m_axi_araddr;
                end

                if (active && m_axi_rvalid && m_axi_rready) begin
                    case (beat_count)
                        4'd0: desc_data_flat[31:0] <= m_axi_rdata;
                        4'd1: desc_data_flat[63:32] <= m_axi_rdata;
                        4'd2: desc_data_flat[95:64] <= m_axi_rdata;
                        4'd3: desc_data_flat[127:96] <= m_axi_rdata;
                        4'd4: desc_data_flat[159:128] <= m_axi_rdata;
                        4'd5: desc_data_flat[191:160] <= m_axi_rdata;
                        4'd6: desc_data_flat[223:192] <= m_axi_rdata;
                        4'd7: desc_data_flat[255:224] <= m_axi_rdata;
                        default: begin
                        end
                    endcase

                    beat_count <= beat_count + 4'd1;
                    if (m_axi_rresp != 2'b00) begin
                        desc_error <= 1'b1;
                        desc_status <= STATUS_ERROR;
                    end

                    if (m_axi_rlast) begin
                        m_axi_rready <= 1'b0;
                        desc_done <= 1'b1;
                        active <= 1'b0;
                        if (m_axi_rresp == 2'b00) begin
                            desc_status <= STATUS_IDLE;
                        end
                    end
                end
            end
        end
    end
endmodule
