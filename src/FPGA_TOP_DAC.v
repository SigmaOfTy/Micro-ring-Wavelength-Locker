`timescale 1ns / 1ps

module FPGA_TOP_DAC (
    input  wire       sys_clk,      // 开发板晶振输入 (例如 50MHz/100MHz)
    input  wire       rst_n,        // 复位按键 (低电平有效)
    
    // --- 新增的外部硬件 DAC 接口 ---
    output wire       DA_Clk,       // DAC 采样时钟
    output wire [7:0] DA_Data,      // DAC 8位数据引脚
    
    output wire       capture_pin   // 保留测试引脚
);

    //==============================================================
    // 1. 时钟管理模块 (Clocking Wizard)
    //==============================================================
    wire clk_32m;   // 核心工作时钟 32MHz
    wire locked;    // 时钟锁定信号
    
    clk_wiz_0 u_clk_gen (
        .clk_out1 (clk_32m),     
        .resetn   (rst_n),      
        .locked   (locked),
        .clk_in1  (sys_clk)
    );
    
    // --- 计数器分频逻辑：32MHz / 10 = 3.2MHz ---
    reg [3:0] clk_cnt;
    reg       clk_3m2_reg;
    
    always @(posedge clk_32m or negedge rst_n) begin
        if (!rst_n) begin
            clk_cnt <= 0;
            clk_3m2_reg <= 0;
        end else if (locked) begin
            if (clk_cnt == 4) begin // 每 5 个周期翻转一次 (10分频)
                clk_cnt <= 0;
                clk_3m2_reg <= ~clk_3m2_reg;
            end else begin
                clk_cnt <= clk_cnt + 1;
            end
        end
    end

    // 使用 BUFG 将分频后的信号转为全局时钟，确保时序稳定
    wire clk_3m2;
    BUFG bufg_div (
        .I(clk_3m2_reg),
        .O(clk_3m2)
    );

    // 系统内部复位：等待时钟稳定后释放复位
    wire sys_rst_n = rst_n & locked;

    //==============================================================
    // 2. 数据源控制 (BRAM 读取逻辑)
    //==============================================================
    localparam OSR = 128;
    localparam DATA_DEPTH = 8192; // 数据行数

    reg[15:0] rom_addr;
    reg [6:0]  rate_cnt;
    
    wire signed [15:0] rom_data_out;

    always @(posedge clk_3m2 or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            rate_cnt <= 0;
            rom_addr <= 0;
        end else begin
            // 速率控制：每 128 个时钟周期更新一次地址
            if (rate_cnt == OSR - 1) begin
                rate_cnt <= 0;
                // 地址循环：读完一圈后回到 0
                if (rom_addr >= DATA_DEPTH - 1)
                    rom_addr <= 0;
                else
                    rom_addr <= rom_addr + 1;
            end else begin
                rate_cnt <= rate_cnt + 1;
            end
        end
    end

    //==============================================================
    // 3. 模块例化与连接
    //==============================================================
    
    // [IP] Block Memory Generator (存放正弦波 COE)
    blk_mem_gen_0 u_rom_source (
        .clka  (clk_3m2),
        .ena   (1'b1),
        .addra (rom_addr),
        .wea   (1'b0),
        .dina  (16'b0),
        .douta (rom_data_out)
    );

    // 定义中间连接信号
    wire signed [15:0] interp_to_sdm_wire; 
    wire signed[3:0]  sdm_out_wire;       

    // [用户模块] 插值滤波器
    interpolation_top u_interp_filter (
        .clk        (clk_3m2),
        .rst_n      (sys_rst_n),
        .data_in    (rom_data_out),      
        .data_out   (interp_to_sdm_wire) 
    );

    // [用户模块] Sigma-Delta 调制器
    sdm_cifb_3rd_4bit u_sdm_core (
        .clk        (clk_3m2),
        .rst_n      (sys_rst_n),
        .din_16     (interp_to_sdm_wire), 
        .dout       (sdm_out_wire)        
    );

    // --- 新增：DAC 驱动模块例化 ---
    dac_sdm_driver u_dac_driver (
        .Clk        (clk_3m2),       // 与 SDM 保持同一时钟域
        .Rst_n      (sys_rst_n),
        .sdm_in     (sdm_out_wire),  // 接入 SDM 的 4 位输出
        .DA_Clk     (DA_Clk),        // 输出给外部 DAC 的时钟
        .DA_Data    (DA_Data)        // 输出给外部 DAC 的 8位数据
    );

    //==============================================================
    // 4. ILA 调试与探针逻辑
    //==============================================================
    
    // 产生 ILA 捕获使能信号 (每 10 个 32MHz 周期产生一次高电平脉冲)
    reg capture_en;
    always @(posedge clk_32m or negedge rst_n) begin
        if (!rst_n) begin
            capture_en <= 1'b0;
        end else begin
            if (clk_cnt == 4 && clk_3m2_reg == 1'b0)
                capture_en <= 1'b1;
            else
                capture_en <= 1'b0;
        end
    end
    assign capture_pin = capture_en;
    
    ila_0 u_ila_debug (
        .clk    (clk_32m),     // ILA 运行在快时钟域下
        .probe0 (DA_Data),     // [8位] 监测最终去往引脚的 DAC 数据
        .probe1 (clk_3m2)      // [1位] 监测 3.2M 时钟，可在 Vivado 中用于触发
    );

endmodule