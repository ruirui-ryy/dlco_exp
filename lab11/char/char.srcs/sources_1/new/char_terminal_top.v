`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/16 23:32:46
// Design Name: 
// Module Name: char_terminal_top
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


// char_terminal_top.v
module char_terminal_top(
    input CLK100MHZ,
    input resetn,    // active low reset from board button
    // PS2
    input PS2_CLK,
    input PS2_DATA,
    // VGA outputs
    output HSYNC,
    output VSYNC,
    output [3:0] VGA_R,
    output [3:0] VGA_G,
    output [3:0] VGA_B,
    output locked
);
    wire reset = ~resetn;

    // generate 25MHz VGA clock via your clk_wiz_0
    wire vga_clk;
    clk_wiz_0 clkgen(
        .clk_in1(CLK100MHZ),
        .reset(reset),
        .locked(locked),
        .clk_out1(vga_clk)
    );

    // instantiate original vga_ctrl (your code)
    wire [11:0] vga_data_from_display;
    wire [9:0] h_addr, v_addr;
    wire hsync_i, vsync_i, valid;
    wire [3:0] r4,g4,b4;

    // we reuse your vga_ctrl (unchanged)
    vga_ctrl vctl(
        .pclk(vga_clk),
        .reset(reset),
        .vga_data(vga_data_from_display),
        .h_addr(h_addr),
        .v_addr(v_addr),
        .hsync(hsync_i),
        .vsync(vsync_i),
        .valid(valid),
        .vga_r(r4),
        .vga_g(g4),
        .vga_b(b4)
    );

    assign HSYNC = hsync_i;
    assign VSYNC = vsync_i;
    // display module will produce 12-bit color white/black
    assign VGA_R = r4; // but we override below with display output
    assign VGA_G = g4;
    assign VGA_B = b4;

    // instantiate keyboard module
    wire k_shift, k_ctrl;
    wire [7:0] k_ascii;
    wire k_ascii_valid;
    wire k_backspace, k_enter;
    kbd_mod kbd(
        .clk(CLK100MHZ),       // note: kbd expects a clk that samples ps2; your ps2 module used 'clk' earlier
        .clrn(resetn),
        .ps2_clk(PS2_CLK),
        .ps2_data(PS2_DATA),
        .shift_flag(k_shift),
        .ctrl_flag(k_ctrl),
        .ascii(k_ascii),
        .ascii_valid(k_ascii_valid),
        .backspace(k_backspace),
        .enter(k_enter),
        .left(), .right(), .up(), .down()
    );

    // instantiate char_display, pclk should be vga_clk
    wire [10:0] cursor_x;
    wire [4:0] cursor_y;
    char_display disp(
        .pclk(vga_clk),
        .reset(reset),
        .valid(valid),
        .h_addr(h_addr),
        .v_addr(v_addr),
        .vga_data(vga_data_from_display),
        .kbd_ascii(k_ascii),
        .kbd_ascii_valid(k_ascii_valid),
        .backspace(k_backspace),
        .enter(k_enter),
        .cursor_x(cursor_x),
        .cursor_y(cursor_y)
    );

    // final output: map 12-bit grayscale to 4-bit channels
    assign VGA_R = vga_data_from_display[11:8];
    assign VGA_G = vga_data_from_display[7:4];
    assign VGA_B = vga_data_from_display[3:0];

endmodule
