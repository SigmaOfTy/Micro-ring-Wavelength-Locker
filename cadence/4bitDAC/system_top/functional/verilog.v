//Verilog HDL for "12bitDAC", "system_top" "functional"
`timescale 1ns / 1ps

module system_top (
    input  wire               clk,      
    input  wire               rst_n,    
    input  wire signed [15:0] data_in,  
    output wire signed [3:0]  sdm_out   //  4-bit 
);

	wire [3:0] sdm_out_temp;
    wire signed [15:0] interp_to_sdm; 
    assign sdm_out = { ~ sdm_out_temp[3],  sdm_out_temp[2:0] };
    // 128x  (25kHz -> 3.2MHz)
    interpolation_top u_interp_filter (
        .clk        (clk),
        .rst_n      (rst_n),
        .data_in    (data_in),      
        .data_out   (interp_to_sdm) 
    );

    //  Sigma-Delta 
    sdm_cifb_3rd_4bit u_sdm_core (
        .clk        (clk),
        .rst_n      (rst_n),
        .din_16     (interp_to_sdm), 
        .dout       (sdm_out_temp)        
    );

endmodule
