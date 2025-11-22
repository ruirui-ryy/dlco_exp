`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/15 16:20:04
// Design Name: 
// Module Name: lab11
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


module vga_main(
    input CLK100MHZ,
    input reset,
    input [11:0] ascii_addr,
    input [7:0] ascii_din,
    input ascii_wea,
    output hsync,
    output vsync,
    output [3:0] vga_r,
    output [3:0] vga_g,
    output [3:0] vga_b,
    output locked
);
    wire [3:0] vga_r_int;
    wire [3:0] vga_g_int;
    wire [3:0] vga_b_int;
    wire [9:0] h_addr;
    wire [9:0] v_addr;
    wire valid, locked;
    wire [11:0] vga_data;
    wire vga_clk;
    wire [18:0] ram_addr;
    
    clk_wiz_0 myclk0(
    .clk_in1(CLK100MHZ),
    .reset(reset),
    .locked(locked),
    .clk_out1(vga_clk));
    
    getcol mycol(
    .clk(vga_clk),
    .h_addr(h_addr),
    .v_addr(v_addr),
    .ascii_addr(ascii_addr),
    .ascii_din(ascii_din),
    .ascii_wea(ascii_wea),
    .valid(valid),
    .vga_data(vga_data));
    
    vga_ctrl myvga(
    .pclk(vga_clk),
    .reset(reset),
    .vga_data(vga_data),
    .h_addr(h_addr),
    .v_addr(v_addr),
    .hsync(hsync),
    .vsync(vsync),
    .valid(valid),
    .vga_r(vga_r_int),
    .vga_g(vga_g_int),
    .vga_b(vga_b_int));

    assign vga_r = valid ? vga_r_int : 4'b0;
    assign vga_g = valid ? vga_g_int : 4'b0;
    assign vga_b = valid ? vga_b_int : 4'b0;

endmodule
