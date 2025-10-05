`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/10/04 21:46:26
// Design Name: 
// Module Name: top_keyboard
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


module keyboard(
    input clk,
	input clrn,
	input ps2_clk,
	input ps2_data,
	output reg shift_flag,
	output reg ctrl_flag,
	output reg [7:0] seg,
	output reg [7:0] AN
);
    reg [7:0] key_count;
	reg [7:0] cur_key;
	wire [7:0] ascii_key;
    wire ready;
    reg nextdata_n;
    wire [7:0] keydata;
    reg break_flag;
    wire overflow;
    wire valid;
    reg [7:0] last_code;

    scan2ascii myascii(cur_key, shift_flag , ascii_key, valid);
    ps2_keyboard mykey(clk, clrn, ps2_clk, ps2_data, keydata, ready, nextdata_n, overflow);

    always @(negedge clk) begin
        if (!clrn) begin
            key_count <= 0;
            cur_key <= 0;
            break_flag <= 0;
            nextdata_n <= 1;
            shift_flag  <= 0;
            ctrl_flag <= 0;
            last_code <= 0;
        end else begin
            nextdata_n <= 1;
            if (ready) begin 
                nextdata_n <= 0;
                if (keydata == 8'hF0) begin
                    break_flag <= 1;
                end else begin
                    if (break_flag) begin
                        break_flag <= 0;
                        if (keydata == 8'h12 || keydata == 8'h59) begin
                            shift_flag <= 0;  // Shift 松开
                        end else if (keydata == 8'h14) begin 
                            ctrl_flag <= 0;
                        end
                        cur_key <= 8'h00;
                        // 如果松开的是上一个通码，清空 last_make_code 
                        if (keydata == last_code) begin
                         last_code <= 8'h00;
                        end
                    end else begin 
                        if (keydata == 8'h12 || keydata == 8'h59) begin
                            shift_flag <= 1;  // Shift 按下
                        end else if (keydata == 8'h14) begin
                            ctrl_flag <= 1;
                        // 检查是否是新的可计数通码
                        // 1. 不是 Shift Ctrl 键
                        // 2. 且当前通码与上一个记录的通码不同
                        end else if (keydata != last_code) begin
                            key_count <= key_count + 1;
                            last_code <= keydata;
                            cur_key <= keydata;
                        end
                    end
                end
            end
        end
    end
    
    // 数码管动态扫描
    reg [2:0] sel = 0;
    reg [16:0] cnt = 0;
    always @(posedge clk) begin
        if (cnt == 99999) begin
            cnt <= 0;
            sel <= sel + 1;
        end else begin 
            cnt <= cnt + 1;
        end
    end
    
    // 显示逻辑
    wire [7:0] keySeg0;
    wire [7:0] keySeg1;
    wire [7:0] asciiSeg0;
    wire [7:0] asciiSeg1;
    wire [7:0] cntSeg0;
    wire [7:0] cntSeg1;
    bcd7seg mykey0 (cur_key[3:0], keySeg0);
    bcd7seg mykey1 (cur_key[7:4], keySeg1);
    bcd7seg myascii0 (ascii_key[3:0], asciiSeg0);
    bcd7seg myascii1 (ascii_key[7:4], asciiSeg1);
    bcd7seg mycnt0 (key_count[3:0], cntSeg0);
    bcd7seg mycnt1 (key_count[7:4], cntSeg1);
    
    always @(posedge clk) begin
        case(sel)
            3'd0: begin AN = 8'b11111110; seg = (cur_key == 8'h00) ? 8'b11111111 : keySeg0; end
            3'd1: begin AN = 8'b11111101; seg = (cur_key == 8'h00) ? 8'b11111111 : keySeg1; end
            3'd2: begin AN = 8'b11111011; seg = (cur_key == 8'h00) ? 8'b11111111 : asciiSeg0; end
            3'd3: begin AN = 8'b11110111; seg = (cur_key == 8'h00) ? 8'b11111111 : asciiSeg1; end
            3'd4: begin AN = 8'b11101111; seg = cntSeg0; end
            3'd5: begin AN = 8'b11011111; seg = cntSeg1; end
        endcase
    end

endmodule
