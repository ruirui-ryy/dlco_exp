`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/15 16:55:03
// Design Name: 
// Module Name: getcol
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module getcol(
    input clk,                    // 100MHz时钟
    input [9:0] h_addr,           // 水平坐标 (0-639)
    input [9:0] v_addr,           // 垂直坐标 (0-479)
    input valid,                  // 有效显示区域
    input [11:0] ascii_addr,
    input [7:0] ascii_din,
    input ascii_wea,
    output reg [11:0] vga_data    // RGB颜色输出
);

    // 字符显示参数
    parameter CHAR_WIDTH = 9;      // 每个字符宽度（像素）
    parameter CHAR_HEIGHT = 16;    // 每个字符高度（像素）
    parameter CHARS_PER_ROW = 70;  // 每行字符数
    parameter CHARS_PER_COL = 30;  // 每列字符数
    parameter DISPLAY_WIDTH = 635; // 显示区域宽度 (70*9=630)
    
    // 预计算的除法查找表 - 用于 h_addr / 9
    reg [6:0] div_lut [0:639];    // 0-629 的除以9结果
    reg [3:0] mod_lut [0:639];    // 0-629 的模9结果
    
    // 初始化查找表 - 只在仿真开始时执行一次
    integer i;
    initial begin
        for (i = 0; i < 640; i = i + 1) begin
            div_lut[i] = i / 9;
            mod_lut[i] = i % 9;
        end
    end
    
    // 字符坐标计算
    wire [6:0] char_col;          // 字符列坐标 (0-69)
    wire [4:0] char_row;          // 字符行坐标 (0-29)
    wire [3:0] pixel_col;         // 字符内像素列 (0-8)
    wire [3:0] pixel_row;         // 字符内像素行 (0-15)
    
    // 垂直坐标计算 - 使用移位（16是2的幂）
    assign char_row = v_addr[8:4];     // v_addr / 16
    assign pixel_row = v_addr[3:0];    // v_addr % 16
    
    // 水平坐标计算 - 使用查找表
    assign char_col = (h_addr < DISPLAY_WIDTH) ? div_lut[h_addr] : 7'd0;
    assign pixel_col = (h_addr < DISPLAY_WIDTH) ? mod_lut[h_addr] : 4'd0;
    
    // 字符ROM接口
    wire [7:0] ascii_code;        // ASCII字符码
    wire [11:0] char_line_data;   // 字符一行点阵数据（12bit存储9bit点阵）
    wire bitmap_pixel;            // 当前像素点（0=黑，1=白）
    
    ascii_ram ascii_ram (
        // 端口A - 可能是写端口（暂时不用）
        .clka(clk),
        .ena(1'b1),               // 禁用写端口
        .wea(ascii_wea),
        .addra(ascii_addr),
        .dina(ascii_din),
        
        // 端口B - 读端口（用于显示读取）
        .clkb(clk),
        .enb(1'b1),               // 使能读端口
        .addrb({char_row, char_col}), // 显示读取地址
        .doutb(ascii_code)        // 输出ASCII码到这里！
    );

    // 字符点阵ROM
    font_rom font_rom (
        .clka(clk),
        .ena(1'b1),
//        .wea(1'b0),
        .addra({ascii_code, pixel_row}), // 地址：ASCII码 + 行号
//        .dina(12'b0),
        .douta(char_line_data)
    );

    // 从12bit数据中提取9bit点阵的对应像素
    wire [8:0] actual_bitmap = char_line_data[8:0]; // 提取9bit点阵数据
    wire [3:0] column;
    wire [3:0] col2;
    assign column = 8 - ((pixel_col <= 4) ? (4 - pixel_col) : (13 - pixel_col));
    assign col2 = (column == 8) ? 0 : column + 1;
    // 根据pixel_col选择对应的位（从左到右，pixel_col=0对应最高位）
    assign bitmap_pixel = (h_addr < DISPLAY_WIDTH) ? actual_bitmap[col2] : 1'b0;
//    assign bitmap_pixel = (pixel_col == 0 || pixel_col == 8) ? 1'b1 : 1'b0;

    // 光标闪烁计数器
    reg [24:0] blink_cnt;
    always @(posedge clk) begin
        blink_cnt <= blink_cnt + 1;
    end
    wire cursor_show = blink_cnt[24];

    wire [11:0] render_addr = {char_row, char_col};
    wire is_cursor_pos = (render_addr == ascii_addr);
    
    // 输出颜色：白色(12'hFFF)或黑色(12'h000)
    always @(posedge clk) begin
        if (!valid) begin
            vga_data <= 12'h000;  // 非显示区域输出黑色
        end else begin
            if (h_addr >= DISPLAY_WIDTH || h_addr <= 3) begin
                vga_data <= 12'h000;  // 超出70字符区域显示黑色
            end else if (is_cursor_pos && cursor_show && pixel_col <= 5 && pixel_col >= 4) begin
                vga_data <= 12'hFFF; // 光标颜色 (白)
            end else if (bitmap_pixel) begin
                vga_data <= 12'hFFF;  // 点阵为1：白色
            end else begin
                vga_data <= 12'h000;  // 点阵为0：黑色
            end
        end
    end

endmodule