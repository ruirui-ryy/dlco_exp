`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/16 21:11:19
// Design Name: 
// Module Name: char_display
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

// ============================================================================
// char_display.v   (FULL SYNTHESIZABLE VERSION)
// VGA pixel -> char grid -> char ROM -> pixel output
// Includes:
//   - cursor blink
//   - keyboard ASCII write
//   - ENTER / BACKSPACE
//   - auto line wrap
//   - scrolling with FSM (NO for-loops, NO illegal declarations)
// ============================================================================

module char_display(
    input  wire        pclk,
    input  wire        reset,
    input  wire        valid,          // VGA active
    input  wire [9:0]  h_addr,
    input  wire [9:0]  v_addr,

    // pixel output: 12-bit RGB
    output wire [11:0] vga_data,

    // from keyboard
    input  wire [7:0]  kbd_ascii,
    input  wire        kbd_ascii_valid,
    input  wire        backspace,
    input  wire        enter,

    // cursor output (optional)
    output reg  [10:0] cursor_x,
    output reg  [4:0]  cursor_y
);

    // ==============================
    // Parameters
    // ==============================
    localparam CHAR_W = 9;
    localparam CHAR_H = 16;
    localparam COLS = 70;
    localparam ROWS = 30;
    localparam VRAM_SIZE = COLS * ROWS;

    // ==============================
    // Character coordinate
    // ==============================
    wire [6:0] char_x = h_addr / CHAR_W;      
    wire [4:0] char_y = v_addr / CHAR_H;
    wire [3:0] row_in_char = v_addr - (char_y * CHAR_H);
    wire [3:0] col_in_char = h_addr - (char_x * CHAR_W);

    // ==============================
    // VRAM interface
    // ==============================
    wire [11:0] vram_rd_addr = char_y * COLS + char_x;
    wire [7:0]  vram_rd_data;

    reg         vram_we;
    reg [11:0]  vram_wr_addr;
    reg [7:0]   vram_wr_data;

    char_vram VRAM (
        .clk(pclk),
        .rd_addr(vram_rd_addr),
        .rd_data(vram_rd_data),
        .we(vram_we),
        .wr_addr(vram_wr_addr),
        .wr_data(vram_wr_data)
    );

    // ==============================
    // Character ROM
    // ==============================
    wire [11:0] rom_rowdata;
    char_rom CROM (
        .clk(pclk),
        .char_code(vram_rd_data),
        .row(row_in_char),
        .rowdata(rom_rowdata)
    );

    wire pixel_bit = rom_rowdata[col_in_char];

    // ==============================
    // Cursor blink (0.5s)
    // ==============================
    reg [24:0] blink_cnt;
    reg blink;

    always @(posedge pclk or posedge reset) begin
        if (reset) begin
            blink_cnt <= 0;
            blink <= 0;
        end else begin
            if (blink_cnt == 12_500_000) begin
                blink_cnt <= 0;
                blink <= ~blink;
            end else begin
                blink_cnt <= blink_cnt + 1;
            end
        end
    end

    // ==============================
    // Cursor registers
    // ==============================
    reg [6:0] col;  // 0..69
    reg [4:0] row;  // 0..29

    always @(posedge pclk or posedge reset) begin
        if (reset) begin
            row <= 0;
            col <= 0;
            cursor_x <= 0;
            cursor_y <= 0;
        end else begin
            cursor_x <= col;
            cursor_y <= row;
        end
    end

    // ==============================
    // Scroll FSM
    // ==============================
    localparam S_IDLE   = 0;
    localparam S_COPY   = 1;
    localparam S_CLEAR  = 2;

    reg [1:0] scroll_state;
    reg [11:0] copy_src;
    reg [11:0] copy_dst;
    reg [11:0] copy_cnt;
    reg [6:0] clear_cnt;

    reg scroll_request;

    always @(posedge pclk or posedge reset) begin
        if (reset) begin
            scroll_state <= S_IDLE;
            scroll_request <= 0;
            vram_we <= 0;
        end else begin
            vram_we <= 0;

            case (scroll_state)
            // ------------------------------
            S_IDLE: begin
                if (scroll_request) begin
                    // start copying rows 1..29 to rows 0..28
                    copy_src <= COLS;          // source start
                    copy_dst <= 0;             // dest start
                    copy_cnt <= COLS*(ROWS-1); // total bytes to copy
                    scroll_state <= S_COPY;
                    scroll_request <= 0;
                end
            end
            // ------------------------------
            S_COPY: begin
                // read from src (vram_rd_addr must match):
                vram_wr_addr <= copy_dst;
                vram_wr_data <= vram_rd_data;
                vram_we <= 1;

                // next src/dst
                copy_src <= copy_src + 1;
                copy_dst <= copy_dst + 1;
                copy_cnt <= copy_cnt - 1;

                if (copy_cnt == 1) begin
                    // now clear last row
                    clear_cnt <= 0;
                    scroll_state <= S_CLEAR;
                end
            end
            // ------------------------------
            S_CLEAR: begin
                vram_wr_addr <= (ROWS-1)*COLS + clear_cnt;
                vram_wr_data <= 8'h20;
                vram_we <= 1;

                clear_cnt <= clear_cnt + 1;
                if (clear_cnt == COLS-1) begin
                    scroll_state <= S_IDLE;
                end
            end
            endcase
        end
    end

    // ==============================
    // Keyboard write logic
    // ==============================

    always @(posedge pclk or posedge reset) begin
        if (reset) begin
            vram_we <= 0;
            vram_wr_addr <= 0;
            vram_wr_data <= 0;
            row <= 0;
            col <= 0;
        end else if (scroll_state == S_IDLE) begin
            vram_we <= 0;

            // ------------------------------
            // ASCII input
            // ------------------------------
            if (kbd_ascii_valid) begin
                vram_wr_addr <= row * COLS + col;
                vram_wr_data <= kbd_ascii;
                vram_we <= 1;

                if (col == COLS-1) begin
                    col <= 0;
                    if (row == ROWS-1)
                        scroll_request <= 1;
                    else
                        row <= row + 1;
                end else begin
                    col <= col + 1;
                end
            end

            // ------------------------------
            // BACKSPACE
            // ------------------------------
            else if (backspace) begin
                if (col != 0) begin
                    col <= col - 1;
                end else if (row != 0) begin
                    row <= row - 1;
                    col <= COLS-1;
                end

                vram_wr_addr <= row * COLS + col;
                vram_wr_data <= 8'h20;
                vram_we <= 1;
            end

            // ------------------------------
            // ENTER
            // ------------------------------
            else if (enter) begin
                col <= 0;
                if (row == ROWS-1)
                    scroll_request <= 1;
                else
                    row <= row + 1;
            end
        end
    end

    // ==============================
    // Pixel output
    // ==============================
    reg [11:0] rgb;

    assign vga_data = rgb;

    always @(posedge pclk) begin
        if (!valid) begin
            rgb <= 12'h000;
        end else begin
            // cursor draw (vertical bar in column 4)
            if ((char_x == cursor_x) && (char_y == cursor_y) && blink) begin
                if (col_in_char == 4)
                    rgb <= 12'hFFF;
                else
                    rgb <= pixel_bit ? 12'hFFF : 12'h000;
            end else begin
                rgb <= pixel_bit ? 12'hFFF : 12'h000;
            end
        end
    end

endmodule

