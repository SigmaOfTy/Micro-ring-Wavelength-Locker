`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: sdm_cifb_3rd_4bit
// Description: 3rd Order 4-bit SDM (CRFB Topology)
//              Adapted for 16-bit input from Interpolation Filter
//              Maintains Q8.24 internal format and 16.95 bits ENOB performance
//////////////////////////////////////////////////////////////////////////////////

module sdm_cifb_3rd_4bit(
    input  wire        clk,        // 3.2 MHz
    input  wire        rst_n,      
    input  wire signed [15:0] din_16, // 【修改点】接收前级插值滤波器的 16 位输出
    output wire signed [3:0]  dout    // 4-bit 输出到 DAC
    );

    //=======================================================
    // 1. 输入与反馈的位宽与量程对齐
    //=======================================================
    
    // 【核心对齐逻辑】将 16 位输入完美映射到内部的 Q8.24 格式
    // 原理: 符号位扩展 7 位 + 16 位数据 + 低位补 9 个 0
    // 这样当 din_16 为 32767 时，内部数值正好接近 1.0 (2^24)
    wire signed [31:0] din = {{7{din_16[15]}}, din_16, 9'd0}; 
    
    reg signed [31:0] int1, int2, int3;
    wire signed [31:0] v_fb;
    
    // DAC 反馈符号位扩展：缩小 8 倍，让 dout=8 时内部才等于 1.0
    assign v_fb = {{7{dout[3]}}, dout, 21'd0}; 

    //=======================================================
    // 2. 高精度 CSD 系数计算 (保持 16.95 bits 性能的最优参数)
    //=======================================================
    
    // a1 = b1 ≈ 0.01025 
    wire signed [31:0] term_a1_din = (din >>> 7)  + (din >>> 9)  + (din >>> 11);
    wire signed [31:0] term_a1_fb  = (v_fb >>> 7) + (v_fb >>> 9) + (v_fb >>> 11);

    // a2 ≈ 0.0239 
    wire signed [31:0] term_a2 = (v_fb >>> 5) - (v_fb >>> 7) + (v_fb >>> 11);

    // c1 ≈ 0.39746 
    wire signed [31:0] term_c1 = (int1 >>> 1) - (int1 >>> 3) + (int1 >>> 6) + (int1 >>> 7) - (int1 >>> 10);

    // c2 ≈ 0.80468 
    wire signed [31:0] term_c2 = int2 - (int2 >>> 2) + (int2 >>> 4) - (int2 >>> 7);

    // g1 ≈ 0.0004958 
    wire signed [31:0] term_g1 = (int3 >>> 11) + (int3 >>> 17);

    // a3 ≈ 0.046875 
    wire signed [31:0] term_a3 = (v_fb >>> 4) - (v_fb >>> 6);

    // c3 ≈ 19.75 
    wire signed [31:0] term_c3 = (int3 << 4) + (int3 << 2) - (int3 >>> 2);

    //=======================================================
    // 3. 环路累加逻辑 (CRFB 结构)
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
    // 4. 量化器 (带饱和截断)
    //=======================================================
    wire signed [31:0] quantizer_in = term_c3;
    
    // 提取整数部分并放大 8 倍，对齐 4-bit 量程
    wire signed [7:0]  int_part = quantizer_in[28:21];

    assign dout = (int_part > 8'sd7)  ? 4'sd7 :
                  (int_part < -8'sd8) ? -4'sd8 :
                  int_part[3:0];

endmodule