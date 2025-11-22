`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/10/05 10:38:11
// Design Name: 
// Module Name: scancode
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


//simple scancode converter
module scancode_ram(
    input clk,
    input [7:0] addr,
    input shift_pressed,
    input ctrl_pressed,
    input alt_pressed,
    input caps_lock, 
    input extend_code,
    output reg [7:0] outdata);
//Do not change the name of this ram, testbench will initialize this
reg [7:0] ascii_tab[255:0];
reg [7:0] shift_tab[255:0];
reg [7:0] extend_tab[255:0];
initial begin
        $readmemh("rom.txt", ascii_tab, 0, 255);
        $readmemh("shift.txt", shift_tab, 0, 255);
        $readmemh("extend.txt", extend_tab, 0, 255);
    end

always @(posedge clk)
begin
    if ((addr >= 8'h15 && addr <= 8'h1D) ||  // q-w-e-r-t-y-u-i-o-p
        (addr >= 8'h1A && addr <= 8'h22) ||  // z-x-c-v-b-n-m
        (addr >= 8'h24 && addr <= 8'h2D) ||  // a-s-d-f-g-h-j-k-l
        (addr >= 8'h32 && addr <= 8'h35) ||  // b-n-m
        addr == 8'h1C || addr == 8'h1B ||    // a-s
        addr == 8'h23 || addr == 8'h2B ||    // d-f
        addr == 8'h34 || addr == 8'h33 ||    // g-h
        addr == 8'h43 || addr == 8'h3B ||    // i-j
        addr == 8'h42 || addr == 8'h4B ||    // k-l
        addr == 8'h3A || addr == 8'h31 ||    // m-n
        addr == 8'h44 || addr == 8'h4D) begin // o-p
        if (shift_pressed ^ caps_lock) outdata <= shift_tab[addr];
        else outdata <= ascii_tab[addr];
    end else begin
        if (extend_code) outdata <= extend_tab[addr];
        else if (shift_pressed) outdata <= shift_tab[addr];
        else outdata <= ascii_tab[addr];
    end
end

endmodule