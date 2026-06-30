`timescale 1ns / 1ps

module system_top (
    input  wire               clk,
    input  wire               rst_n,
    input  wire signed [15:0] data_in,
    output wire signed [3:0]  sdm_out
);

    wire signed [15:0] interp_to_sdm;

    // 128x interpolation chain, 25 kHz input to 3.2 MHz output.
    interpolation_top u_interp_filter (
        .clk        (clk),
        .rst_n      (rst_n),
        .data_in    (data_in),
        .data_out   (interp_to_sdm)
    );

    // 3rd-order 4-bit Sigma-Delta modulator.
    sdm_cifb_3rd_4bit u_sdm_core (
        .clk        (clk),
        .rst_n      (rst_n),
        .din_16     (interp_to_sdm),
        .dout       (sdm_out)
    );

endmodule
