module dac_sdm_driver (
    input  wire       Clk,
    input  wire       Rst_n,
    input  wire [3:0] sdm_in,   // 来自 SDM 模块的 4位输出 (有符号补码，范围 -8 ~ +7)
    output wire       DA_Clk,
    output reg  [7:0] DA_Data   // 去往外部 8位 DAC 芯片的数据引脚
);

  // ==================== DAC 数据处理与输出逻辑 ====================
  always @(posedge Clk or negedge Rst_n) begin
    if (!Rst_n) begin
         DA_Data <= 8'h80; 
    end else begin
       DA_Data <= { ~sdm_in[3], sdm_in[2:0], 4'b0000 };
    end
  end
  assign DA_Clk = ~Clk;

endmodule