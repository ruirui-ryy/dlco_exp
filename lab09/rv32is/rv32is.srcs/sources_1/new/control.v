`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/02 15:01:48
// Design Name: 
// Module Name: control
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


module control(
    input  [6:0] op,
    input  [2:0] func3,
    input        func7_5,
    output reg [2:0] ExtOp,
    output reg       RegWr,
    output reg [2:0] Branch,
    output reg       MemtoReg,
    output reg       MemWr,
    output reg [2:0] MemOP,
    output reg       ALUAsrc,
    output reg [1:0] ALUBsrc,
    output reg [3:0] ALUctr
);

    wire [4:0] op5 = op[6:2];

    always @(*) begin
        // defaults
        ExtOp = 3'b000;
        RegWr = 1'b0;
        Branch = 3'b000;
        MemtoReg = 1'b0;
        MemWr = 1'b0;
        MemOP = 3'b010; // default word
        ALUAsrc = 1'b0;
        ALUBsrc = 2'b00;
        ALUctr = 4'b0000;

        case (op5)
            5'b01101: begin // lui
                ExtOp = 3'b001; RegWr = 1'b1; ALUBsrc = 2'b01; ALUctr = 4'b0011; ALUAsrc = 1'b0;
            end
            5'b00101: begin // auipc
                ExtOp = 3'b001; RegWr = 1'b1; ALUAsrc = 1'b1; ALUBsrc = 2'b01; ALUctr = 4'b0000;
            end
            5'b00100: begin // I-type ALU immediate (addi, slti, sltiu, xori, ori, andi, shifts)
                ExtOp = 3'b000; RegWr = 1'b1; ALUBsrc = 2'b01; ALUAsrc = 1'b0;
                case (func3)
                    3'b000: ALUctr = 4'b0000; // addi
                    3'b010: ALUctr = 4'b0010; // slti -> slt compare via ALU set 1/0
                    3'b011: ALUctr = 4'b1010; // sltiu
                    3'b100: ALUctr = 4'b0100; // xori
                    3'b110: ALUctr = 4'b0110; // ori
                    3'b111: ALUctr = 4'b0111; // andi
                    3'b001: ALUctr = 4'b0001; // slli (shamt)
                    3'b101: begin // srli or srai depending on func7[5]
                        if (func7_5==1'b0) ALUctr = 4'b0101; else ALUctr = 4'b1101;
                    end
                    default: ALUctr = 4'b0000;
                endcase
            end
            5'b01100: begin // R-type (register-reg)
                RegWr = 1'b1; ALUAsrc = 1'b0; ALUBsrc = 2'b00;
                case (func3)
                    3'b000: ALUctr = (func7_5==1'b1) ? 4'b1000 : 4'b0000; // sub/add
                    3'b001: ALUctr = 4'b0001; // sll
                    3'b010: ALUctr = 4'b0010; // slt
                    3'b011: ALUctr = 4'b1010; // sltu
                    3'b100: ALUctr = 4'b0100; // xor
                    3'b101: ALUctr = (func7_5==1'b1) ? 4'b1101 : 4'b0101; // sra/srl
                    3'b110: ALUctr = 4'b0110; // or
                    3'b111: ALUctr = 4'b0111; // and
                    default: ALUctr = 4'b0000;
                endcase
            end
            5'b11011: begin // jal
                ExtOp = 3'b100; RegWr = 1'b1; Branch = 3'b001; ALUAsrc = 1'b1; ALUBsrc = 2'b10; ALUctr = 4'b0000; // ALU produces PC+4
            end
            5'b11001: begin // jalr
                ExtOp = 3'b000; RegWr = 1'b1; Branch = 3'b010; ALUAsrc = 1'b1; ALUBsrc = 2'b10; ALUctr = 4'b0000;
            end
            5'b11000: begin // branches (B-type) beq bne blt bge bltu bgeu
                ExtOp = 3'b011; RegWr = 1'b0; ALUAsrc = 1'b0; ALUBsrc = 2'b00;
                case (func3)
                    3'b000: begin Branch = 3'b100; ALUctr = 4'b0010; end // beq uses Zero
                    3'b001: begin Branch = 3'b101; ALUctr = 4'b0010; end// bne
                    3'b100: begin Branch = 3'b110; ALUctr = 4'b0010; end// blt
                    3'b101: begin Branch = 3'b111; ALUctr = 4'b0010; end// bge
                    3'b110: begin Branch = 3'b110; ALUctr = 4'b1010; end// bltu
                    3'b111: begin Branch = 3'b111; ALUctr = 4'b1010; end// bgeu
                    default: Branch = 3'b000;
                endcase
            end
            5'b00000: begin // loads: lb lh lw lbu lhu
                ExtOp = 3'b000; RegWr = 1'b1; MemtoReg = 1'b1; MemWr = 1'b0; ALUAsrc = 1'b0; ALUBsrc = 2'b01; ALUctr = 4'b0000;
                case (func3)
                    3'b000: MemOP = 3'b000; // lb (sign)
                    3'b001: MemOP = 3'b001; // lh
                    3'b010: MemOP = 3'b010; // lw
                    3'b100: MemOP = 3'b100; // lbu
                    3'b101: MemOP = 3'b101; // lhu
                    default: MemOP = 3'b010;
                endcase
            end
            5'b01000: begin // stores: sb sh sw
                ExtOp = 3'b010; RegWr = 1'b0; MemWr = 1'b1; ALUAsrc = 1'b0; ALUBsrc = 2'b01; ALUctr = 4'b0000;
                case (func3)
                    3'b000: MemOP = 3'b000; // sb
                    3'b001: MemOP = 3'b001; // sh
                    3'b010: MemOP = 3'b010; // sw
                    default: MemOP = 3'b010;
                endcase
            end
            default: begin
                // unknown opcode - keep defaults (NOP-ish)
                ExtOp = 3'b000; RegWr = 1'b0; Branch = 3'b000; MemtoReg = 1'b0; MemWr = 1'b0; MemOP = 3'b010;
                ALUAsrc = 1'b0; ALUBsrc = 2'b00; ALUctr = 4'b0000;
            end
        endcase
    end
endmodule
