`timescale 1ns / 1ps

module system_top (
    input  wire               clk,      
    input  wire               rst_n,    
    input  wire signed [15:0] data_in,  
    output wire signed [3:0]  sdm_out   // 【修改点】恢复成最原汁原味的 4-bit 码流输出
);

    wire signed [15:0] interp_to_sdm; 
    
    // 128x 插值滤波器链 (25kHz -> 3.2MHz)
    interpolation_top u_interp_filter (
        .clk        (clk),
        .rst_n      (rst_n),
        .data_in    (data_in),      
        .data_out   (interp_to_sdm) 
    );

    // 高精度 Sigma-Delta 调制器
    sdm_cifb_3rd_4bit u_sdm_core (
        .clk        (clk),
        .rst_n      (rst_n),
        .din_16     (interp_to_sdm), 
        .dout       (sdm_out)        
    );

endmodule