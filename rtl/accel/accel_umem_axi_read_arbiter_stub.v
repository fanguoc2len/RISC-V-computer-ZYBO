module accel_umem_axi_read_arbiter_stub (
    input  wire        clk,
    input  wire        resetn,

    input  wire [31:0] desc_m_axi_araddr,
    input  wire [7:0]  desc_m_axi_arlen,
    input  wire [2:0]  desc_m_axi_arsize,
    input  wire [1:0]  desc_m_axi_arburst,
    input  wire        desc_m_axi_arvalid,
    output wire        desc_m_axi_arready,
    output wire [31:0] desc_m_axi_rdata,
    output wire [1:0]  desc_m_axi_rresp,
    output wire        desc_m_axi_rlast,
    output wire        desc_m_axi_rvalid,
    input  wire        desc_m_axi_rready,

    input  wire [31:0] npu_m_axi_araddr,
    input  wire [7:0]  npu_m_axi_arlen,
    input  wire [2:0]  npu_m_axi_arsize,
    input  wire [1:0]  npu_m_axi_arburst,
    input  wire        npu_m_axi_arvalid,
    output wire        npu_m_axi_arready,
    output wire [31:0] npu_m_axi_rdata,
    output wire [1:0]  npu_m_axi_rresp,
    output wire        npu_m_axi_rlast,
    output wire        npu_m_axi_rvalid,
    input  wire        npu_m_axi_rready,

    output wire [31:0] m_axi_araddr,
    output wire [7:0]  m_axi_arlen,
    output wire [2:0]  m_axi_arsize,
    output wire [1:0]  m_axi_arburst,
    output wire        m_axi_arvalid,
    input  wire        m_axi_arready,
    input  wire [31:0] m_axi_rdata,
    input  wire [1:0]  m_axi_rresp,
    input  wire        m_axi_rlast,
    input  wire        m_axi_rvalid,
    output wire        m_axi_rready
);
    reg read_active;
    reg owner_desc;

    wire grant_desc = !read_active && desc_m_axi_arvalid;
    wire grant_npu = !read_active && !desc_m_axi_arvalid && npu_m_axi_arvalid;

    assign m_axi_araddr = grant_desc ? desc_m_axi_araddr : npu_m_axi_araddr;
    assign m_axi_arlen = grant_desc ? desc_m_axi_arlen : npu_m_axi_arlen;
    assign m_axi_arsize = grant_desc ? desc_m_axi_arsize : npu_m_axi_arsize;
    assign m_axi_arburst = grant_desc ? desc_m_axi_arburst : npu_m_axi_arburst;
    assign m_axi_arvalid = grant_desc ? desc_m_axi_arvalid :
                           grant_npu ? npu_m_axi_arvalid : 1'b0;

    assign desc_m_axi_arready = grant_desc ? m_axi_arready : 1'b0;
    assign npu_m_axi_arready = grant_npu ? m_axi_arready : 1'b0;

    assign desc_m_axi_rdata = m_axi_rdata;
    assign desc_m_axi_rresp = m_axi_rresp;
    assign desc_m_axi_rlast = m_axi_rlast;
    assign desc_m_axi_rvalid = (read_active && owner_desc) ? m_axi_rvalid : 1'b0;

    assign npu_m_axi_rdata = m_axi_rdata;
    assign npu_m_axi_rresp = m_axi_rresp;
    assign npu_m_axi_rlast = m_axi_rlast;
    assign npu_m_axi_rvalid = (read_active && !owner_desc) ? m_axi_rvalid : 1'b0;

    assign m_axi_rready = !read_active ? 1'b0 :
                          owner_desc ? desc_m_axi_rready : npu_m_axi_rready;

    always @(posedge clk) begin
        if (!resetn) begin
            read_active <= 1'b0;
            owner_desc <= 1'b1;
        end else begin
            if (!read_active) begin
                if (grant_desc && m_axi_arready) begin
                    read_active <= 1'b1;
                    owner_desc <= 1'b1;
                end else if (grant_npu && m_axi_arready) begin
                    read_active <= 1'b1;
                    owner_desc <= 1'b0;
                end
            end else if (m_axi_rvalid && m_axi_rready && m_axi_rlast) begin
                read_active <= 1'b0;
            end
        end
    end
endmodule
