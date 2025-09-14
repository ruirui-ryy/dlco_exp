`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/09/13 22:32:08
// Design Name: 
// Module Name: debounce
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


module debounce(
    input wire inp,
    input wire clk,
    input wire clr,
    output outp
);
    reg delay1;
    reg delay2;
    reg [19:0] count = 0;
    reg clk_20ms;
    always @( posedge clk or negedge clr)
        if (!clr) begin
            count <= 20'd0;
            clk_20ms <= 1'b0;
        end else if (count == 20'hfffff) begin
            clk_20ms <= ~clk_20ms;
            count <= 20'd0;
        end else begin
            count <= count + 1'b1;
        end
    always @( posedge clk_20ms or negedge clr)
        if (!clr) begin
            delay1 <= 1'b0;
            delay2 <= 2'b0;
        end else begin
           delay1 <= inp;
           delay2 <= delay1;
        end
    assign outp = delay1 & delay2;
endmodule


module top (
    input CLK100MHZ,
    input btn,
    output btn_db,
    output reg res = 0
);
    debounce u_db_start (
        .inp(btn),
        .clk(CLK100MHZ), 
        .clr(1'b1),
        .outp(btn_db)
    );
    reg start_reg = 0;
    always @(posedge CLK100MHZ) begin
        start_reg <= btn_db;
        if (btn_db && ~start_reg) begin
            res <= ~res;
        end
    end
endmodule 