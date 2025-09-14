`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/09/12 14:02:07
// Design Name: 
// Module Name: clk_div
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


module clk_div(
    input clk,
    input [25:0] limit,
    output reg clk_d = 0
);
    reg [25:0] cnt = 0;
    always @(posedge clk) begin
        if (cnt == limit - 1) begin 
            cnt <= 0;
            clk_d <= ~clk_d;      
        end else begin
            cnt <= cnt + 1;
        end
    end
endmodule

module top(
    input CLK100MHZ,
    output clk_1
);
    clk_div u_1(
        .clk(CLK100MHZ),
        .limit(26'd5),
        .clk_d(clk_1)
    );
endmodule
