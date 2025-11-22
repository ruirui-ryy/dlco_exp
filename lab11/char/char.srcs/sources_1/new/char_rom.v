`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/16 20:49:32
// Design Name: 
// Module Name: char_rom
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


// 读入 font.mem：每行 12bit 的 hex 数据。每个字符占 16 行。
// address: {char_code[7:0], row[3:0]} -> 12-bit row pattern
module char_rom(
    input clk,
    input [7:0] char_code,
    input [3:0] row,           // 0..15
    output reg [11:0] rowdata  // low 9 bits are pixels
);
    parameter DEPTH = 256*16;
    reg [11:0] mem [0:DEPTH-1];

    initial begin
        $readmemh("vga_font.txt", mem);
    end

    wire [15:0] addr = {char_code, row};
    always @(posedge clk) begin
        rowdata <= mem[addr];
    end
endmodule
