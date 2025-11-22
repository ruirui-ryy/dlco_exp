`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/03 00:01:40
// Design Name: 
// Module Name: BandJ
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


module BandJ(
    input [2:0] BandJ,
    input zero,
    input result0,
    output NPCASrc,
    output reg NPCBSrc
    );
    always @(*) begin 
        case (BandJ)
            3'b000: NPCBSrc = 1'b0;
            3'b001: NPCBSrc = 1'b1;
            3'b010: NPCBSrc = 1'b1;
            3'b100: NPCBSrc = zero;
            3'b101: NPCBSrc = ~zero;
            3'b110: NPCBSrc = result0;
            3'b111: NPCBSrc = zero | ~result0;
            default: NPCBSrc = 1'b0;
        endcase 
    end 
    assign NPCASrc = (~BandJ[0]) & (BandJ[1]) & (~BandJ[2]);
            
endmodule
