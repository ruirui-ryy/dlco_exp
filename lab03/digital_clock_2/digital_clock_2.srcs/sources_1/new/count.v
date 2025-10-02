`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/09/13 10:51:46
// Design Name: 
// Module Name: count
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

    // -------- 时钟寄存器 --------
    reg [6:0] time_sec = 0;
    reg [6:0] time_min = 0;
    reg [6:0] time_hour = 0;
    reg [31:0] countcs = 0;

    // -------- 秒表寄存器 --------
    reg [6:0] sw_cs = 0;
    reg [6:0] sw_sec = 0;
    
    //--------- 闹钟寄存器 --------
    reg [6:0] alarm_sec = 0;
    reg [6:0] alarm_min = 0;
    reg [6:0] alarm_hour = 0;

    always @(posedge clk_1cs) begin
        led = (time_sec == alarm_sec && time_min == alarm_min && time_hour == alarm_hour);
        if (mode == 0 && pause == 1) begin
            // ---------- 调整时间 ----------
            case (id)
                2'b00: time_sec <= (set > 59) ? 59 : {1'b0, set};
                2'b01: time_min <= (set > 59) ? 59 : {1'b0, set};
                2'b10: time_hour <= (set > 23) ? 23 : {1'b0, set};
                2'b11: ;
            endcase
        end else begin
            // ---------- 时钟模式 ----------
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
        // ---------- 闹钟模式 ----------
        if (mode == 0 && pause == 0 && reset == 1) begin
            case (id)
                2'b00: alarm_sec <= (set > 59) ? 59 : {1'b0, set};
                2'b01: alarm_min <= (set > 59) ? 59 : {1'b0, set};
                2'b10: alarm_hour <= (set > 23) ? 23 : {1'b0, set};
                2'b11: ;
            endcase
        end 
        // ---------- 秒表模式 ----------
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
        // ------------------------------
    end

    // -------- 输出给数码管 --------
    always @(*) begin
        if (mode == 0) begin
            if (pause == 0 && reset == 1) begin
                // 闹钟显示 hh:mm:ss
                s1 = alarm_sec % 10;
                s2 = alarm_sec / 10;
                m1 = alarm_min % 10;
                m2 = alarm_min / 10;
                h1 = alarm_hour % 10;
                h2 = alarm_hour / 10;
            end else begin
                // 时钟显示 hh:mm:ss
                s1 = time_sec % 10;
                s2 = time_sec / 10;
                m1 = time_min % 10;
                m2 = time_min / 10;
                h1 = time_hour % 10;
                h2 = time_hour / 10;
            end
        end else begin
            // 秒表显示 ss:cc
            s1 = sw_cs % 10;
            s2 = sw_cs / 10;
            m1 = sw_sec % 10;
            m2 = sw_sec / 10;
            h1 = 4'b1111; // 熄灭
            h2 = 4'b1111; // 熄灭
        end
    end

endmodule
