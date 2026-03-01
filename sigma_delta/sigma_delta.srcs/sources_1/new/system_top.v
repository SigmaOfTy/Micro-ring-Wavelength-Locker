`timescale 1ns / 1ps
// ===========================================================
// Module Name: system_top
// Description: 微环调制器驱动数字前端 - 顶层级联模块
// Architecture: 
//   1. 插值滤波器链 (25kHz -> 3.2MHz, 16-bit)
//   2. 3阶 Sigma-Delta 调制器 (3.2MHz, 16-bit in -> 4-bit out)
// ===========================================================

module system_top (
    input  wire               clk,      // 3.2MHz 主时钟
    input  wire               rst_n,    // 低电平复位
    input  wire signed [15:0] data_in,  // 25kHz 原始输入信号
    output wire signed [15:0] data_out  // 适配 TB 的 16-bit 接口 (内部为 4-bit SDM 输出)
);

    // ==========================================
    // 内部连线信号声明
    // ==========================================
    // 连接插值滤波器输出与 SDM 输入的 16-bit 高速信号
    wire signed [15:0] interp_to_sdm; 
    
    // SDM 吐出的 4-bit 真实调制信号
    wire signed [3:0]  sdm_out;       

    // ==========================================
    // 1. 实例化前级：128x 插值滤波器链
    // ==========================================
    interpolation_top u_interp_filter (
        .clk        (clk),
        .rst_n      (rst_n),
        .data_in    (data_in),       // 接收 25kHz 低速输入
        .data_out   (interp_to_sdm)  // 输出 3.2MHz 高速平滑信号
    );

    // ==========================================
    // 2. 实例化后级：高精度 Sigma-Delta 调制器
    // ==========================================
    sdm_cifb_3rd_4bit u_sdm_core (
        .clk        (clk),
        .rst_n      (rst_n),
        .din_16     (interp_to_sdm), // 无缝接收滤波器的 16-bit 输出
        .dout       (sdm_out)        // 吐出 4-bit 调制码流
    );

    // ==========================================
    // 3. 接口适配逻辑 (为了完美兼容现有的 TB)
    // ==========================================
    // 将 4-bit 的 SDM 输出进行符号位扩展至 16-bit
    // 比如 SDM 输出 4'b0111 (+7)，扩展后为 16'h0007
    // 比如 SDM 输出 4'b1000 (-8)，扩展后为 16'hFFF8
    assign data_out = {{12{sdm_out[3]}}, sdm_out};

endmodule