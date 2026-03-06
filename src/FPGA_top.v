`timescale 1ns / 1ps

module FPGA_top (
    input  wire       sys_clk,      // 开发板晶振输入 (例如 50MHz/100MHz)
    input  wire       rst_n,        // 复位按键 (低电平有效)
    output wire [3:0] sdm_out_pin,   // 物理输出引脚 (防止逻辑被优化)
    output wire capture_pin
);

    //==============================================================
    // 1. 时钟管理模块 (Clocking Wizard)
    //==============================================================
    wire clk_32m;   // 核心工作时钟 3.2MHz
    wire locked;    // 时钟锁定信号
    
    // 生成 32MHz 时钟
    // 注意：请根据你的 clk_wiz_0 的实际配置确认 reset 是高电平还是低电平有效
    // 大多数 clk_wiz IP 默认 reset 是高电平有效，所以这里用了 !rst_n
    clk_wiz_0 u_clk_gen (
        .clk_out1 (clk_32m),     
        .resetn    (rst_n),      
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

    // 非常重要：使用 BUFG 将分频后的信号转为全局时钟，确保时序稳定
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
    // 目的：模拟 25kHz 的输入信号。 
    // 计算：3.2MHz / 25kHz = 128 (OSR)
    localparam OSR = 128;
    localparam DATA_DEPTH = 8192; // 数据行数

    reg [15:0] rom_addr;
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
    // [IP] Block Memory Generator (存放正弦波 COE)
    blk_mem_gen_0 u_rom_source (
        .clka  (clk_3m2),
        .ena   (1'b1),          // 必须使能，否则不输出数据
        .addra (rom_addr),
        .wea   (1'b0),          // ROM 模式写使能为 0
        .dina  (16'b0),         // 数据输入为 0
        .douta (rom_data_out)
    );

    // 定义中间连接信号
    wire signed [15:0] interp_to_sdm_wire; // 插值模块 -> SDM 模块
    wire signed [3:0]  sdm_out_wire;       // SDM 模块 -> 输出

    // [用户模块] 插值滤波器
    // 直接例化 interpolation_top，而不是 system_top，这样我们可以探测中间信号
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

    // 将输出连接到物理引脚
    assign sdm_out_pin = sdm_out_wire;

    //==============================================================
    // 4. ILA 调试探针连接
    
    // --- 增加一个采样使能脉冲 ---
    reg capture_en;
    wire capture_pin;
    always @(posedge clk_32m or negedge rst_n) begin
        if (!rst_n) begin
            capture_en <= 1'b0;
        end else begin
            // 只有当计数器快要到头，且当前时钟电平为低时，产生一个脉冲
            // 这样这个脉冲每 10 个 clk_32m 周期才出现一次
            if (clk_cnt == 4 && clk_3m2_reg == 1'b0)
                capture_en <= 1'b1;
            else
                capture_en <= 1'b0;
        end
    end
        assign capture_pin = capture_en;
    
    //==============================================================
    // 确保 ILA 配置为：Depth=65536, Probes=3 (Width: 16, 16, 4)
    ila_0 u_ila_debug (
        .clk    (clk_32m),
        .probe0 (rom_data_out),        // 观察源数据
        .probe1 (interp_to_sdm_wire),  // 观察中间插值结果 (system_top里看不到这个)
        .probe2 (sdm_out_wire),         // 观察最终输出 (用于 MATLAB 分析)
        .probe3 (clk_3m2) 
    );

endmodule
