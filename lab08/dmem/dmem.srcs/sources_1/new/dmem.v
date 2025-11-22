`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/10/29 10:30:01
// Design Name: 
// Module Name: dmem
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


module dmem(
	input  [31:0] addr,
	output reg [31:0] dataout,
	input  [31:0] datain,
	input  rdclk,
	input  wrclk,
	input [2:0] memop,
	input we);

    reg [31:0] mem [0:1023];
    reg [31:0] rdata = 0, wdata = 0;
    always @(posedge rdclk) begin
        rdata = mem[addr[31:2]];
        case (memop)
            3'b000: begin 
                        if (addr[1:0] == 2'b00)
                            dataout <= {{24{rdata[7]}}, rdata[7:0]};
                        if (addr[1:0] == 2'b01)
                            dataout <= {{24{rdata[15]}}, rdata[15:8]};
                        if (addr[1:0] == 2'b10)
                            dataout <= {{24{rdata[23]}}, rdata[23:16]};
                        if (addr[1:0] == 2'b11)
                            dataout <= {{24{rdata[31]}}, rdata[31:24]};
                    end
            3'b001: begin 
                        if (addr[1:0] == 2'b00)
                            dataout <= {{16{rdata[15]}}, rdata[15:0]};
                        if (addr[1:0] == 2'b10)
                            dataout <= {{16{rdata[31]}}, rdata[31:16]};
                    end
            3'b010: begin dataout <= rdata; end
            3'b100: begin 
                        if (addr[1:0] == 2'b00)
                            dataout <= {24'b0, rdata[7:0]};
                        if (addr[1:0] == 2'b01)
                            dataout <= {24'b0, rdata[15:8]};
                        if (addr[1:0] == 2'b10)
                            dataout <= {24'b0, rdata[23:16]};
                        if (addr[1:0] == 2'b11)
                            dataout <= {24'b0, rdata[31:24]};
                    end
            3'b101: begin 
                        if (addr[1:0] == 2'b00)
                            dataout <= {16'b0, rdata[15:0]};
                        if (addr[1:0] == 2'b10)
                            dataout <= {16'b0, rdata[31:16]};
                    end
            default: begin dataout <= 32'b0; end 
        endcase 
    end 

    always @(posedge wrclk) begin
        if (we) begin
            case (memop)
                3'b000: begin 
                        if (addr[1:0] == 2'b00)
                            wdata <= {rdata[31:8], datain[7:0]};
                        if (addr[1:0] == 2'b01)
                            wdata <= {rdata[31:16], datain[7:0], rdata[7:0]};
                        if (addr[1:0] == 2'b10)
                            wdata <= {rdata[31:24], datain[7:0], rdata[15:0]};
                        if (addr[1:0] == 2'b11)
                            wdata <= {datain[7:0], rdata[23:0]};
                    end
                3'b001: begin 
                        if (addr[1:0] == 2'b00)
                            wdata <= {rdata[31:16], datain[15:0]};
                        if (addr[1:0] == 2'b10)
                            wdata <= {datain[15:0], rdata[15:0]};
                    end
                3'b010: begin wdata <= datain; end
                default:;
            endcase
            mem[addr[31:2]] <= wdata;
        end
    end

endmodule
