`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/09/11 19:43:50
// Design Name: 
// Module Name: counter60_test
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

module counter60_test;

    // Testbench �ź�
    reg CLK100MHZ;
    reg sw_en;
    reg btn_start;
    reg btn_pause;
    reg btn_reset;
    wire [6:0] seg;
    wire [7:0] an;
    wire led;

    // ʵ��������ģ��
    top_timer uut (
        .CLK100MHZ(CLK100MHZ),
        .btn_start(btn_start),
        .btn_pause(btn_pause),
        .btn_reset(btn_reset),
        .seg(seg),
        .an(an),
        .led(led)
    );

    // ����ʱ�ӣ�10ns���� = 100MHz
    initial begin
        CLK100MHZ = 0;
        forever #5 CLK100MHZ = ~CLK100MHZ; 
    end

    // ���漤��
    initial begin
        // ��ʼ��
        sw_en = 1;
        btn_start = 0;
        btn_pause = 0;
        btn_reset = 0;
        
        // �ϵ縴λ
        #200 btn_reset = 1;
        #1_000_000; btn_reset = 0;
        
        #200 btn_start = 1;
        
        #1_000_000_000;

        $stop; // ��������
    end
endmodule
