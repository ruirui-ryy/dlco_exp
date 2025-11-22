`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/16 21:04:29
// Design Name: 
// Module Name: kbd_mod
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


// kbd_mod.v
// wrapper around ps2_keyboard + scan2ascii
module kbd_mod(
    input clk,
    input clrn,
    input ps2_clk,
    input ps2_data,
    output reg shift_flag,
    output reg ctrl_flag,
    output reg [7:0] ascii,       // ascii code
    output reg ascii_valid,       // one-clock pulse when ascii is valid (key make)
    output reg backspace,
    output reg enter,
    output reg left,
    output reg right,
    output reg up,
    output reg down
);
    // instantiate lower modules (assume scan2ascii exists and maps make codes to ascii)
    wire [7:0] keydata;
    wire ready;
    reg nextdata_n;
    wire overflow;

    // instantiate original ps2_keyboard (from your code)
    ps2_keyboard ps2(
        .clk(clk),
        .clrn(clrn),
        .ps2_clk(ps2_clk),
        .ps2_data(ps2_data),
        .data(keydata),
        .ready(ready),
        .nextdata_n(nextdata_n),
        .overflow(overflow)
    );

    reg break_flag;
    reg [7:0] last_make;
    wire [7:0] ascii_from_scan;
    wire ascii_ok;
    // scan2ascii should map scan code + shift -> ascii. If you have existing scan2ascii, use it.
    // Here we instantiate a presumed module scan2ascii(scan_code, shift, ascii_out, valid)
    // If your scan2ascii has different interface, adapt accordingly.
    scan2ascii sc(
        .scan(keydata),
        .shift(shift_flag),
        .ascii(ascii_from_scan),
        .valid(ascii_ok)
    );

    always @(posedge clk) begin
        if (!clrn) begin
            nextdata_n <= 1;
            break_flag <= 0;
            last_make <= 8'h00;
            shift_flag <= 0;
            ctrl_flag <= 0;
            ascii <= 8'h00;
            ascii_valid <= 0;
            backspace <= 0; enter <= 0;
            left <= 0; right <= 0; up <= 0; down <= 0;
        end else begin
            ascii_valid <= 0;
            backspace <= 0; enter <= 0;
            left <= 0; right <= 0; up <= 0; down <= 0;
            if (ready) begin
                nextdata_n <= 0; // read it
                // we process keydata
                if (keydata == 8'hF0) begin
                    break_flag <= 1;
                end else begin
                    if (break_flag) begin
                        // release code
                        break_flag <= 0;
                        if (keydata == 8'h12 || keydata == 8'h59) shift_flag <= 0;
                        if (keydata == 8'h14) ctrl_flag <= 0;
                        if (keydata == last_make) last_make <= 8'h00;
                    end else begin
                        // make code
                        if (keydata == 8'h12 || keydata == 8'h59) begin
                            shift_flag <= 1;
                        end else if (keydata == 8'h14) begin
                            ctrl_flag <= 1;
                        end else begin
                            // map special control/scancodes to actions
                            // common scan codes (set 2):
                            // Backspace (0x66), Enter (0x5A), Arrow keys: extended codes start with E0
                            // Here we use basic mapping for make codes (might need extension handling)
                            // For simplicity assume:
                            // 0x66 -> backspace, 0x5A -> enter
                            if (keydata == 8'h66) begin
                                backspace <= 1;
                            end else if (keydata == 8'h5A) begin
                                enter <= 1;
                            end else begin
                                // arrow keys often use extended sequences (E0 6B 74 72 75)
                                // if your ps2 module doesn't produce E0 handling, you may not get arrows.
                                // For now, try ascii mapping first
                                if (ascii_ok) begin
                                    ascii <= ascii_from_scan;
                                    ascii_valid <= 1;
                                end
                            end
                            last_make <= keydata;
                        end
                    end
                end
            end else begin
                nextdata_n <= 1;
            end
        end
    end

endmodule
