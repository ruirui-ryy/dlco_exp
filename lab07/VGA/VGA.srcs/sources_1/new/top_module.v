`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/10/15 09:38:38
// Design Name: 
// Module Name: top_module
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


module top_module (
    input CLK100MHZ, 
    input reset,
    // VGA 输出引脚连接到 Nexys A7-100T 的 HD-DB15 接口
    output hsync,
    output vsync,
    output [3:0] vga_r,
    output [3:0] vga_g,
    output [3:0] vga_b,
    output locked
);

    wire vga_clk;
    wire [11:0] vga_data_from_mem; 
    wire [9:0] h_addr_out, v_addr_out;
    wire valid_out;
    
    wire hsync_int; 
    wire vsync_int;
    wire [3:0] vga_r_int, vga_g_int, vga_b_int;
    
    // 1. 时钟生成
    clk_wiz_0 myvgaclk(
        .clk_in1(CLK100MHZ),
        .reset(reset),
        .locked(locked),
        .clk_out1(vga_clk) // 25MHz VGA 时钟
    );
    
    // 2. VGA 控制器
    vga_ctrl myvgactrl (
        .pclk(vga_clk),
        .reset(reset),
        .vga_data(vga_data_from_mem),
        .h_addr(h_addr_out),
        .v_addr(v_addr_out),
        .hsync(hsync_int),
        .vsync(vsync_int),
        .valid(valid_out),
        .vga_r(vga_r_int),
        .vga_g(vga_g_int),
        .vga_b(vga_b_int)
    );
    
    // 3. 显存 
    wire [18:0] ram_addr;
    assign ram_addr = { h_addr_out, v_addr_out[8:0] };
    blk_mem_gen_0 myram (
        .addra(ram_addr),
        .clka(vga_clk),
        .dina(12'd0),
        .douta(vga_data_from_mem),
        .ena(1'b1),
        .wea(1'b0)
    );
    
    // 4. 消隐
    assign hsync = hsync_int;
    assign vsync = vsync_int;
    assign vga_r = valid_out ? vga_r_int : 4'd0;
    assign vga_g = valid_out ? vga_g_int : 4'd0;
    assign vga_b = valid_out ? vga_b_int : 4'd0;
    
endmodule
