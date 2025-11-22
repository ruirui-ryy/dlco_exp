`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/16 20:58:41
// Design Name: 
// Module Name: char_vram
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


// Simple dual-port RAM implemented as inferred block RAM
// depth = 2100, addr width = 11 (2048 < 2100 < 4096) -> use 12 bits for address
module char_vram(
    input clk,
    // port A: VGA read
    input [11:0] rd_addr,    // 0..2099
    output reg [7:0] rd_data,
    // port B: CPU/keyboard write
    input we,
    input [11:0] wr_addr,
    input [7:0] wr_data
);
    parameter DEPTH = 4096;
    reg [7:0] mem [0:DEPTH-1];

    initial begin
         $readmemh("vram_init.mem", mem);
    end

    // read side (sync)
    always @(posedge clk) begin
        rd_data <= mem[rd_addr];
    end

    // write side
    always @(posedge clk) begin
        if (we) mem[wr_addr] <= wr_data;
    end
endmodule
