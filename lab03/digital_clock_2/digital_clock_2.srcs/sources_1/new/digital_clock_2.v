`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/09/12 08:58:03
// Design Name: 
// Module Name: lab03
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
module clock(
    input clk,
    input [31:0]limit,
    output reg clk_d = 0
    );
    reg [31:0]cnt = 0;
    always @(posedge clk) begin
        if (cnt == limit - 1) begin
            cnt <= 0;
            clk_d <= ~clk_d;
        end else begin
            cnt <= cnt + 1;
        end
    end
endmodule

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

module count60(
    input clk_1cs, // 100Hz
    input reset,
    input pause,
    input mode,
    input [5:0]set,
    input [1:0]id,
    output reg [3:0] s1,
    output reg [3:0] s2,
    output reg [3:0] m1,
    output reg [3:0] m2,
    output reg [3:0] h1,
    output reg [3:0] h2,
    output reg led
    );

    // 时钟寄存器 
    reg [6:0] time_sec = 0;
    reg [6:0] time_min = 0;
    reg [6:0] time_hour = 0;
    reg [31:0] countcs = 0;


    // 闹钟寄存器
    reg [6:0] alarm_sec = 0;
    reg [6:0] alarm_min = 0;
    reg [6:0] alarm_hour = 0;
    
    // 秒表寄存器
    reg [6:0] sw_cs = 0;
    reg [6:0] sw_sec = 0;
    

    always @(posedge clk_1cs) begin
        led = (time_sec == alarm_sec && time_min == alarm_min && time_hour == alarm_hour);
        if (mode == 0 && pause == 1) begin
            // 调整时间
            case (id)
                2'b00: time_sec <= (set > 59) ? 59 : {1'b0, set};
                2'b01: time_min <= (set > 59) ? 59 : {1'b0, set};
                2'b10: time_hour <= (set > 23) ? 23 : {1'b0, set};
                2'b11: ;
            endcase
        end else begin
            // 时钟模式
            if (countcs == 99) begin
                countcs <= 0;
                if (time_sec == 59) begin
                    time_sec <= 0;
                    if (time_min == 59) begin
                        time_min <= 0;
                        if (time_hour == 23) time_hour <= 0;
                        else time_hour <= time_hour + 1;
                    end else begin
                        time_min <= time_min + 1;
                    end
                end else time_sec <= time_sec + 1;
            end else countcs <= countcs + 1;
        end
        // 闹钟模式 
        if (mode == 0 && pause == 0 && reset == 1) begin
            case (id)
                2'b00: alarm_sec <= (set > 59) ? 59 : {1'b0, set};
                2'b01: alarm_min <= (set > 59) ? 59 : {1'b0, set};
                2'b10: alarm_hour <= (set > 23) ? 23 : {1'b0, set};
                2'b11: ;
            endcase
        end 
        // 秒表模式 
        if (mode == 1) begin
            if (reset == 1) begin
                sw_cs <= 0; sw_sec <= 0;
            end else if (pause == 0) begin
                if (sw_cs == 99) begin
                    sw_cs <= 0;
                    if (sw_sec == 59) sw_sec <= 0;
                    else sw_sec <= sw_sec + 1;
                end else sw_cs <= sw_cs + 1;
            end
        end
    end

    always @(*) begin
        if (mode == 0) begin
            if (pause == 0 && reset == 1) begin
                s1 = alarm_sec % 10;
                s2 = alarm_sec / 10;
                m1 = alarm_min % 10;
                m2 = alarm_min / 10;
                h1 = alarm_hour % 10;
                h2 = alarm_hour / 10;
            end else begin
                s1 = time_sec % 10;
                s2 = time_sec / 10;
                m1 = time_min % 10;
                m2 = time_min / 10;
                h1 = time_hour % 10;
                h2 = time_hour / 10;
            end
        end else begin
            s1 = sw_cs % 10;
            s2 = sw_cs / 10;
            m1 = sw_sec % 10;
            m2 = sw_sec / 10;
            h1 = 4'b1111; 
            h2 = 4'b1111; 
        end
    end

endmodule


module digital_clock_2(
    input reset,
    input pause,
    input mode,
    input CLK100MHZ,
    input [5:0]set,
    input [1:0]id,
    output reg [7:0] h,
    output reg [7:0] AN,
    output wire led
);
    
    wire clk_100hz;
    wire [3:0] s1, s2, m1, m2, h1, h2;
    clock u1hz(
        .clk(CLK100MHZ),
        .limit(500000),
        .clk_d(clk_100hz)
    );
    count60 count(
        .clk_1cs(clk_100hz),
        .reset(reset),
        .pause(pause),
        .mode(mode),
        .set(set),
        .id(id),
        .s1(s1),
        .s2(s2),
        .m1(m1),
        .m2(m2),
        .h1(h1),
        .h2(h2),
        .led(led)
    );
    wire [7:0]segs1, segs2, segm1, segm2, segh1, segh2;
    bcd7seg disp_s1(s1, segs1);
    bcd7seg disp_s2(s2, segs2);
    bcd7seg disp_m1(m1, segm1);
    bcd7seg disp_m2(m2, segm2);
    bcd7seg disp_h1(h1, segh1);
    bcd7seg disp_h2(h2, segh2);
    reg [2:0] select = 3'b000;
    reg [31:0] display = 0;
    always @(posedge CLK100MHZ) begin
        display <= display + 1;
        if (display == 99999) begin
            display <= 0;
            select <= select + 1;
        end
        case (select)
            3'b000: begin h = segs1; AN = 8'b11111110; end
            3'b001: begin h = segs2; AN = 8'b11111101; end
            3'b010: begin h = 8'b10111111; AN = 8'b11111011; end
            3'b011: begin h = segm1; AN = 8'b11110111; end
            3'b100: begin h = segm2; AN = 8'b11101111; end
            3'b101: begin h = 8'b10111111; AN = 8'b11011111; end
            3'b110: begin h = segh1; AN = 8'b10111111; end
            3'b111: begin h = segh2; AN = 8'b01111111; end
        endcase
    end
    
endmodule