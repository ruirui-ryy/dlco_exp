`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/01 23:53:37
// Design Name: 
// Module Name: immgen
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


module immgen(input  [31:0] instr, 
              input  [2:0]  ExtOp,
              output reg [31:0] imm
              );
    always @(*) begin
        case (ExtOp)
            3'b000: imm = {{20{instr[31]}}, instr[31:20]};
            3'b001: imm = {instr[31:12], 12'b0};
            3'b010: imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};
            3'b011: imm = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
            3'b100: imm = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};
            default: imm = 32'b0;
        endcase
    end
endmodule
