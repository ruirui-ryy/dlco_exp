`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/09/16 16:20:42
// Design Name: 
// Module Name: clk_pulse
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


module clk_pulse(
    input CLK100MHZ,
    input in_pulse,
    input [31:0] limit,
    output reg out_pulse = 0
    );
    reg [31:0] cnt = 0;
    always @(posedge CLK100MHZ) begin 
        if (in_pulse) begin
            if (cnt == limit - 1) begin
                cnt <= 0;
                out_pulse <= 1;
            end else begin 
                cnt <= cnt + 1;
                out_pulse <= 0;
            end
        end else begin 
            out_pulse <= 0;
        end
    end
endmodule
