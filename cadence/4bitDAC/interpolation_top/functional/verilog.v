//Verilog HDL for "12bitDAC", "interpolation_top" "functional"

`timescale 1ns / 1ps

module interpolation_top (
    input  wire                   clk,      // 3.2MHz 
    input  wire                   rst_n,
    input  wire signed [15:0]    data_in,  //  25kHz 
    output wire signed [15:0]    data_out  //  3.2MHz 
);

    // --- 1.  (0-127 ) ---
    reg [6:0] cnt;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) cnt <= 7'd0;
        else cnt <= cnt + 7'd1;
    end

    // 
    wire en_50k  = (cnt[5:0] == 6'd0);   //  64  clk  (Stage-1 )
    wire en_200k = (cnt[3:0] == 4'd0);   //  16  clk  (Stage-2 )

    // --- 2. Stage-1 (2x FIR)  ---
    //  25kHz ->  50kHz. 
    //  50kHz 1 data_in2 0.
    reg signed [15:0] s1_input;
    always @(*) begin
        if (cnt == 7'd0)      s1_input = data_in; // 
        else if (cnt == 7'd64) s1_input = 16'd0;   // 
        else                   s1_input = 16'd0;
    end

    wire signed [15:0] s1_out;
    fir_stage1 u_stage1 (
        .clk(clk),
        .rst_n(rst_n),
        .en(en_50k),
        .data_in(s1_input),
        .data_out(s1_out)
    );

    // --- 3. Stage-2 (4x FIR)  ---
    //  50kHz ->  200kHz.
    //  200kHz 1 s1_out3 0.
    reg signed [15:0] s2_input;
    always @(*) begin
        // Stage-1  cnt=0  cnt=64 
        if (cnt == 7'd0 || cnt == 7'd64) 
            s2_input = s1_out;
        else if (cnt[3:0] == 4'd0)       
            s2_input = 16'd0; //  200kHz 
        else                             
            s2_input = 16'd0;
    end

    wire signed [15:0] s2_out;
    fir_stage2 u_stage2 (
        .clk(clk),
        .rst_n(rst_n),
        .en(en_200k),
        .data_in(s2_input),
        .data_out(s2_out)
    );

    // --- 4. Stage-3 (16x Repeat)  ---
    //  200kHz ->  3.2MHz.
    //  200kHz  16 
    reg signed [15:0] s3_hold;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) s3_hold <= 16'd0;
        else if (en_200k) s3_hold <= s2_out; //  Stage-2 
    end

    assign data_out = s3_hold;

endmodule
