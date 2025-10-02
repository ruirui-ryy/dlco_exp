`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/09/16 16:16:50
// Design Name: 
// Module Name: timer
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


module timer(
    input CLK100MHZ,
    input en,
    input [7:0] limit,
    input rst,
    input add,
    output [3:0] ones,
    output [3:0] tens,
    output reg carry
    );

    // °´Å¥Âö³å 
    reg add0, add1;
    always @(posedge CLK100MHZ) begin
        add0 <= add;
        add1 <= add0;
    end 
    wire add_pulse = add0 & ~add1;
    
    // +1 Âö³å 
    wire pulse = en | add_pulse;
    
    // Ê±ÖÓÂß¼­ 
    reg [7:0] times;
    always @(posedge CLK100MHZ or posedge rst) begin
        if (rst) begin
            times <= 0;
            carry <= 0;
        end else if (pulse) begin
            times <= (times == limit - 1) ? 0 : times + 1;
            carry <= (times == limit - 1) ? 1 : 0;
        end else begin
            carry <= 0;
        end
    end
    
    assign ones = times % 10;
    assign tens = times / 10;
endmodule
