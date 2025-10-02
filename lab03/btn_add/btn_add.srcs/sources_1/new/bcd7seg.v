`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/09/16 15:34:41
// Design Name: 
// Module Name: bcd7seg
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

module bcd7seg(
    input  [3:0] b,
    output reg [7:0] h
);
    always @(*) begin
        case (b)
            4'd0: h = 8'b11000000;
            4'd1: h = 8'b11111001;
            4'd2: h = 8'b10100100;
            4'd3: h = 8'b10110000;
            4'd4: h = 8'b10011001;
            4'd5: h = 8'b10010010;
            4'd6: h = 8'b10000010;
            4'd7: h = 8'b11111000;
            4'd8: h = 8'b10000000;
            4'd9: h = 8'b10010000;
            default: h = 8'b11111111;
        endcase
    end
endmodule