`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/09/16 15:32:57
// Design Name: 
// Module Name: btn_add
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


module btn_add(
    input CLK100MHZ,
    input btn,
    output [7:0] seg,
    output [7:0] AN
    );
    // 时钟脉冲
    reg [31:0] cnt = 0;
    reg tick_1s = 0;
    always @(posedge CLK100MHZ) begin
        if (cnt == 99999999) begin
            cnt <= 0;
            tick_1s <= 1;  // 只拉高一个周期
        end else begin
            cnt <= cnt + 1;
            tick_1s <= 0;
        end
    end
    // 按钮脉冲
    reg btn_sync0, btn_sync1;
    always @(posedge CLK100MHZ) begin
        btn_sync0 <= btn;
        btn_sync1 <= btn_sync0;
    end
    wire btn_rising = btn_sync0 & ~btn_sync1;  // 检测上升沿

    wire tick_add = tick_1s | btn_rising;

    reg [3:0] outp = 0;
    always @(posedge CLK100MHZ) begin
        if (tick_add)
            outp <= (outp == 9) ? 0 : outp + 1;
    end
    
    // 显示
    bcd7seg u_bcd(
        .b(outp),
        .h(seg)
    );
    assign AN = 8'b11111110;
endmodule
