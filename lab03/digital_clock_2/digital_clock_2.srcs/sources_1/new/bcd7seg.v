`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/09/12 23:24:23
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


module seg7(
    input [3:0] b,
    output reg [7:0] h
);
    always @(*) begin
        case (b)
            // �����ǹ�������ܣ�0��1��
            4'd0: h = 8'b11000000; // 0
            4'd1: h = 8'b11111001; // 1
            4'd2: h = 8'b10100100; // 2
            4'd3: h = 8'b10110000; // 3
            4'd4: h = 8'b10011001; // 4
            4'd5: h = 8'b10010010; // 5
            4'd6: h = 8'b10000010; // 6
            4'd7: h = 8'b11111000; // 7
            4'd8: h = 8'b10000000; // 8
            4'd9: h = 8'b10010000; // 9
            default: h = 8'b11111111; // ȫ��
        endcase
    end
endmodule
