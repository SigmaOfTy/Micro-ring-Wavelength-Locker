//Verilog HDL for "12bitDAC", "decoder4to15" "functional"


module decoder4to15 (
    input A, B, C, D,          // 4-bit input, A=MSB, D=LSB
    output VN0, VN1, VN2, VN3, VN4, VN5, VN6, VN7, VN8, VN9, VN10, VN11, VN12, VN13, VN14,
    output VP0, VP1, VP2, VP3, VP4, VP5, VP6, VP7, VP8, VP9, VP10, VP11, VP12, VP13, VP14
);

reg [14:0] therm_code;         // 15-bit thermometric code

// Generate thermometric code based on input
always @(*) begin
    case ({A, B, C, D})
        4'b0000: therm_code = 15'b000000000000000;
        4'b0001: therm_code = 15'b000000000000001;
        4'b0010: therm_code = 15'b000000000000011;
        4'b0011: therm_code = 15'b000000000000111;
        4'b0100: therm_code = 15'b000000000001111;
        4'b0101: therm_code = 15'b000000000011111;
        4'b0110: therm_code = 15'b000000000111111;
        4'b0111: therm_code = 15'b000000001111111;
        4'b1000: therm_code = 15'b000000011111111;
        4'b1001: therm_code = 15'b000000111111111;
        4'b1010: therm_code = 15'b000001111111111;
        4'b1011: therm_code = 15'b000011111111111;
        4'b1100: therm_code = 15'b000111111111111;
        4'b1101: therm_code = 15'b001111111111111;
        4'b1110: therm_code = 15'b011111111111111;
        4'b1111: therm_code = 15'b111111111111111;
        default: therm_code = 15'b000000000000000;
    endcase
end

// Assign outputs: VNx = therm_code bit (VN0 = LSB, VN14 = MSB)
assign {VN14, VN13, VN12, VN11, VN10, VN9, VN8, VN7, VN6, VN5, VN4, VN3, VN2, VN1, VN0} = therm_code;

// VPx = complement of therm_code
assign {VP14, VP13, VP12, VP11, VP10, VP9, VP8, VP7, VP6, VP5, VP4, VP3, VP2, VP1, VP0} = ~therm_code;

endmodule
