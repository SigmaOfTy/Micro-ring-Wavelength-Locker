//Verilog HDL for "12bitDAC", "decoder3to7" "functional"


module decoder3to7 (
    input A, B, C,           // 3 (A=MSB, C=LSB)
    output VN0, VN1, VN2, VN3, VN4, VN5, VN6,  // 
    output VP0, VP1, VP2, VP3, VP4, VP5, VP6   // 
);

    reg [6:0] therm_code;
    // case
    always @(*) begin
        case ({A, B, C})
            3'b000: therm_code = 7'b0000000;
            3'b001: therm_code = 7'b0000001;
            3'b010: therm_code = 7'b0000011;
            3'b011: therm_code = 7'b0000111;
            3'b100: therm_code = 7'b0001111;
            3'b101: therm_code = 7'b0011111;
            3'b110: therm_code = 7'b0111111;
            3'b111: therm_code = 7'b1111111;
            default: therm_code = 7'b0000000;
        endcase
    end
    
    // 
    assign {VN6, VN5, VN4, VN3, VN2, VN1, VN0} = therm_code;
    assign {VP6, VP5, VP4, VP3, VP2, VP1, VP0} = ~therm_code;

endmodule
