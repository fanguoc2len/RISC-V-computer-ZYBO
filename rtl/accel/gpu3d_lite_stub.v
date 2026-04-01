module gpu3d_lite_stub (
    input  wire        clk,
    input  wire        resetn,
    input  wire        cmd_valid,
    input  wire [7:0]  cmd_opcode,
    input  wire [15:0] vertex0_xy,
    input  wire [15:0] vertex1_xy,
    input  wire [15:0] vertex2_xy,
    input  wire [7:0]  clear_value,
    input  wire [4:0]  fb_row_select,
    output reg         busy,
    output reg         frame_done,
    output reg  [31:0] triangles_drawn,
    output reg  [31:0] frame_counter,
    output reg  [31:0] raster_pixels,
    output reg  [31:0] last_area2,
    output reg  [31:0] last_bbox,
    output wire [31:0] fb_row_data
);
    localparam [7:0] CMD_CLEAR    = 8'h01;
    localparam [7:0] CMD_DRAW_TRI = 8'h02;
    localparam [1:0] MODE_IDLE    = 2'd0;
    localparam [1:0] MODE_CLEAR   = 2'd1;
    localparam [1:0] MODE_DRAW    = 2'd2;

    reg [31:0] framebuffer [0:31];
    reg [1:0]  mode_q;
    reg [4:0]  clear_row_q;
    reg        clear_fill_q;
    reg [4:0]  scan_x_q;
    reg [4:0]  scan_y_q;
    reg [4:0]  min_x_q;
    reg [4:0]  max_x_q;
    reg [4:0]  min_y_q;
    reg [4:0]  max_y_q;
    reg [7:0]  x0_q;
    reg [7:0]  y0_q;
    reg [7:0]  x1_q;
    reg [7:0]  y1_q;
    reg [7:0]  x2_q;
    reg [7:0]  y2_q;

    integer row_i;

    function [7:0] min3_u8;
        input [7:0] a;
        input [7:0] b;
        input [7:0] c;
        begin
            min3_u8 = (a < b) ? ((a < c) ? a : c) : ((b < c) ? b : c);
        end
    endfunction

    function [7:0] max3_u8;
        input [7:0] a;
        input [7:0] b;
        input [7:0] c;
        begin
            max3_u8 = (a > b) ? ((a > c) ? a : c) : ((b > c) ? b : c);
        end
    endfunction

    function [4:0] clamp_fb_coord;
        input [7:0] value;
        begin
            if (value > 8'd31) begin
                clamp_fb_coord = 5'd31;
            end else begin
                clamp_fb_coord = value[4:0];
            end
        end
    endfunction

    function signed [31:0] edge_function;
        input [7:0] ax;
        input [7:0] ay;
        input [7:0] bx;
        input [7:0] by;
        input [7:0] px;
        input [7:0] py;
        reg signed [31:0] ap_x;
        reg signed [31:0] ap_y;
        reg signed [31:0] ab_x;
        reg signed [31:0] ab_y;
        begin
            ap_x = $signed({1'b0, px}) - $signed({1'b0, ax});
            ap_y = $signed({1'b0, py}) - $signed({1'b0, ay});
            ab_x = $signed({1'b0, bx}) - $signed({1'b0, ax});
            ab_y = $signed({1'b0, by}) - $signed({1'b0, ay});
            edge_function = (ab_x * ap_y) - (ab_y * ap_x);
        end
    endfunction

    function signed [31:0] triangle_area2;
        input [7:0] ax;
        input [7:0] ay;
        input [7:0] bx;
        input [7:0] by;
        input [7:0] cx;
        input [7:0] cy;
        begin
            triangle_area2 = edge_function(ax, ay, bx, by, cx, cy);
        end
    endfunction

    wire [7:0] vertex0_x = vertex0_xy[7:0];
    wire [7:0] vertex0_y = vertex0_xy[15:8];
    wire [7:0] vertex1_x = vertex1_xy[7:0];
    wire [7:0] vertex1_y = vertex1_xy[15:8];
    wire [7:0] vertex2_x = vertex2_xy[7:0];
    wire [7:0] vertex2_y = vertex2_xy[15:8];

    wire [4:0] min_x_start = clamp_fb_coord(min3_u8(vertex0_x, vertex1_x, vertex2_x));
    wire [4:0] max_x_start = clamp_fb_coord(max3_u8(vertex0_x, vertex1_x, vertex2_x));
    wire [4:0] min_y_start = clamp_fb_coord(min3_u8(vertex0_y, vertex1_y, vertex2_y));
    wire [4:0] max_y_start = clamp_fb_coord(max3_u8(vertex0_y, vertex1_y, vertex2_y));
    wire signed [31:0] area2_start = triangle_area2(vertex0_x, vertex0_y, vertex1_x, vertex1_y, vertex2_x, vertex2_y);

    wire signed [31:0] edge0 = edge_function(x0_q, y0_q, x1_q, y1_q, {3'b000, scan_x_q}, {3'b000, scan_y_q});
    wire signed [31:0] edge1 = edge_function(x1_q, y1_q, x2_q, y2_q, {3'b000, scan_x_q}, {3'b000, scan_y_q});
    wire signed [31:0] edge2 = edge_function(x2_q, y2_q, x0_q, y0_q, {3'b000, scan_x_q}, {3'b000, scan_y_q});
    wire draw_inside = ($signed(last_area2) > 0) ? ((edge0 >= 0) && (edge1 >= 0) && (edge2 >= 0)) :
                       ($signed(last_area2) < 0) ? ((edge0 <= 0) && (edge1 <= 0) && (edge2 <= 0)) :
                       1'b0;

    assign fb_row_data = framebuffer[fb_row_select];

    always @(posedge clk) begin
        if (!resetn) begin
            busy <= 1'b0;
            frame_done <= 1'b0;
            triangles_drawn <= 32'h0000_0000;
            frame_counter <= 32'h0000_0000;
            raster_pixels <= 32'h0000_0000;
            last_area2 <= 32'h0000_0000;
            last_bbox <= 32'h0000_0000;
            mode_q <= MODE_IDLE;
            clear_row_q <= 5'd0;
            clear_fill_q <= 1'b0;
            scan_x_q <= 5'd0;
            scan_y_q <= 5'd0;
            min_x_q <= 5'd0;
            max_x_q <= 5'd0;
            min_y_q <= 5'd0;
            max_y_q <= 5'd0;
            x0_q <= 8'd0;
            y0_q <= 8'd0;
            x1_q <= 8'd0;
            y1_q <= 8'd0;
            x2_q <= 8'd0;
            y2_q <= 8'd0;
            for (row_i = 0; row_i < 32; row_i = row_i + 1) begin
                framebuffer[row_i] <= 32'h0000_0000;
            end
        end else begin
            frame_done <= 1'b0;

            if (!busy && cmd_valid) begin
                case (cmd_opcode)
                    CMD_CLEAR: begin
                        busy <= 1'b1;
                        mode_q <= MODE_CLEAR;
                        clear_row_q <= 5'd0;
                        clear_fill_q <= clear_value[0];
                        raster_pixels <= 32'h0000_0000;
                        last_area2 <= 32'h0000_0000;
                        last_bbox <= 32'h0000_0000;
                    end
                    CMD_DRAW_TRI: begin
                        busy <= 1'b1;
                        mode_q <= MODE_DRAW;
                        x0_q <= vertex0_x;
                        y0_q <= vertex0_y;
                        x1_q <= vertex1_x;
                        y1_q <= vertex1_y;
                        x2_q <= vertex2_x;
                        y2_q <= vertex2_y;
                        min_x_q <= min_x_start;
                        max_x_q <= max_x_start;
                        min_y_q <= min_y_start;
                        max_y_q <= max_y_start;
                        scan_x_q <= min_x_start;
                        scan_y_q <= min_y_start;
                        raster_pixels <= 32'h0000_0000;
                        last_area2 <= area2_start;
                        last_bbox <= {max_y_start, max_x_start, min_y_start, min_x_start};
                    end
                    default: begin
                    end
                endcase
            end else if (busy) begin
                case (mode_q)
                    MODE_CLEAR: begin
                        framebuffer[clear_row_q] <= {32{clear_fill_q}};
                        if (clear_row_q == 5'd31) begin
                            busy <= 1'b0;
                            mode_q <= MODE_IDLE;
                            frame_done <= 1'b1;
                            frame_counter <= frame_counter + 32'd1;
                        end else begin
                            clear_row_q <= clear_row_q + 5'd1;
                        end
                    end
                    MODE_DRAW: begin
                        if (draw_inside) begin
                            framebuffer[scan_y_q][scan_x_q] <= 1'b1;
                            raster_pixels <= raster_pixels + 32'd1;
                        end

                        if (scan_x_q == max_x_q) begin
                            if (scan_y_q == max_y_q) begin
                                busy <= 1'b0;
                                mode_q <= MODE_IDLE;
                                frame_done <= 1'b1;
                                frame_counter <= frame_counter + 32'd1;
                                triangles_drawn <= triangles_drawn + 32'd1;
                            end else begin
                                scan_x_q <= min_x_q;
                                scan_y_q <= scan_y_q + 5'd1;
                            end
                        end else begin
                            scan_x_q <= scan_x_q + 5'd1;
                        end
                    end
                    default: begin
                        busy <= 1'b0;
                        mode_q <= MODE_IDLE;
                    end
                endcase
            end
        end
    end
endmodule
