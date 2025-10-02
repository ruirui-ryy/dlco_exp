`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/09/13 10:35:51
// Design Name: 
// Module Name: clock
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


module clock(
    input clk,
    input [31:0]limit,
    output reg clk_d = 0
    );
    reg [31:0]cnt = 0;
    always @(posedge clk) begin
        if (cnt == limit - 1) begin
            cnt <= 0;
            clk_d <= ~clk_d;
        end else begin
            cnt <= cnt + 1;
        end
    end
endmodule
