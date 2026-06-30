//Verilog HDL for "12bitDAC", "sdm_cifb_3rd_4bit" "functional"
`timescale 1ns / 1ps

module sdm_cifb_3rd_4bit(
    input  wire        clk,        // 3.2 MHz
    input  wire        rst_n,      
    input  wire signed [15:0] din_16, //  16 
    output wire signed [3:0]  dout    // 4-bit  DAC
    );

    //=======================================================
    // 1. 
    //=======================================================
    
    //  16  Q8.24 
    // :  7  + 16  +  9  0
    //  din_16  32767  1.0 (2^24)
    wire signed [31:0] din = {{7{din_16[15]}}, din_16, 9'd0}; 
    
    reg signed [31:0] int1, int2, int3;
    wire signed [31:0] v_fb;
    
    // DAC  8  dout=8  1.0
    assign v_fb = {{7{dout[3]}}, dout, 21'd0}; 

    //=======================================================
    // 2.  CSD  ( 16.95 bits )
    //=======================================================
    
    // a1 = b1  0.01025 
    wire signed [31:0] term_a1_din = (din >>> 7)  + (din >>> 9)  + (din >>> 11);
    wire signed [31:0] term_a1_fb  = (v_fb >>> 7) + (v_fb >>> 9) + (v_fb >>> 11);

    // a2  0.0239 
    wire signed [31:0] term_a2 = (v_fb >>> 5) - (v_fb >>> 7) + (v_fb >>> 11);

    // c1  0.39746 
    wire signed [31:0] term_c1 = (int1 >>> 1) - (int1 >>> 3) + (int1 >>> 6) + (int1 >>> 7) - (int1 >>> 10);

    // c2  0.80468 
    wire signed [31:0] term_c2 = int2 - (int2 >>> 2) + (int2 >>> 4) - (int2 >>> 7);

    // g1  0.0004958 
    wire signed [31:0] term_g1 = (int3 >>> 11) + (int3 >>> 17);

    // a3  0.046875 
    wire signed [31:0] term_a3 = (v_fb >>> 4) - (v_fb >>> 6);

    // c3  19.75 
    wire signed [31:0] term_c3 = (int3 << 4) + (int3 << 2) - (int3 >>> 2);

    //=======================================================
    // 3.  (CRFB )
    //=======================================================
    wire signed [31:0] sum_int1 = term_a1_din - term_a1_fb;
    wire signed [31:0] sum_int2 = term_c1 - term_a2 - term_g1;
    wire signed [31:0] sum_int3 = term_c2 - term_a3;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            int1 <= 32'd0; int2 <= 32'd0; int3 <= 32'd0;
        end else begin
            int1 <= int1 + sum_int1;
            int2 <= int2 + sum_int2;
            int3 <= int3 + sum_int3;
        end
    end

    //=======================================================
    // 4.  ()
    //=======================================================
    wire signed [31:0] quantizer_in = term_c3;
    
    //  8  4-bit 
    wire signed [7:0]  int_part = quantizer_in >>> 21;

    assign dout = (int_part > 8'sd7)  ? 4'sd7 :
                  (int_part < -8'sd8) ? -4'sd8 :
                  int_part[3:0];

endmodule
