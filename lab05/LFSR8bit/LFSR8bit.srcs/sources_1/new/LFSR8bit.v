`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/09/28 22:04:48
// Design Name: 
// Module Name: LFSR8bit
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


module LFSR8bit(
    input CLK100MHZ,
    input clk,
    input rst,
    output reg [7:0] seg,
    output reg [7:0] AN
    );
    
    // 线性反馈 
    reg [7:0] dout = 8'b00000001;
    wire feedback;
    assign feedback = dout[0] ^ dout[2] ^ dout[3] ^ dout[4];
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout <= 8'b00000001;
        end else begin
            dout <= {feedback, dout[7:1]};
        end
    end 
    
    // 数码管显示
    wire [7:0] hex0;
    wire [7:0] hex1;
    bcd7seg u_hex0 (.b(dout[3:0]), .h(hex0));
    bcd7seg u_hex1 (.b(dout[7:4]), .h(hex1));
    
    reg sel = 0;
    reg [16:0] cnt = 0;
    always @(posedge CLK100MHZ) begin
        if (cnt == 99999) begin
            cnt <= 0;
            sel <= sel + 1;
        end else begin 
            cnt <= cnt + 1;
        end
    end
    
    always @(*) begin 
        case (sel) 
            1'd0: begin AN = 8'b11111110; seg = hex0; end 
            1'd1: begin AN = 8'b11111101; seg = hex1; end 
        endcase
    end 
    
endmodule
