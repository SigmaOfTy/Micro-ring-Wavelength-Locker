`timescale 1ns/1ps

module tb_system_top;
    reg clk;
    reg rst_n;
    reg signed [15:0] data_in;
    wire signed [15:0] data_out; // 虽然是16位，但里面装的是扩展后的 4-bit 码流 (-8 到 +7)

    // ==========================================
    // 实例化整个系统顶层 (插值滤波器 + SDM 调制器)
    // ==========================================
    system_top uut (
        .clk(clk), 
        .rst_n(rst_n),
        .data_in(data_in), 
        .data_out(data_out)
    );

    // ==========================================
    // 3.2MHz 主时钟 (周期 312.5ns)
    // ==========================================
    initial clk = 0;
    always #156.25 clk = ~clk;

    integer fp_in, fp_out, r, cnt;

    initial begin
        // 用于抓取波形
        $dumpfile("wave_system.vcd");
        $dumpvars(0, tb_system_top);

        rst_n = 0;
        data_in = 0; 
        cnt = 0;
        
        // 读取 25kHz 的低速测试激励数据
        fp_in = $fopen("din_fixed.txt", "r");
        if (fp_in == 0) begin
            $display("ERROR: 找不到 din_fixed.txt，请确认文件在仿真目录下！");
            $finish;
        end
        
        // 【关键】输出文件名严格匹配你的 MATLAB 脚本
        fp_out = $fopen("sdm_output_data.txt", "w");
        
        #1000;
        rst_n = 1;
        $display("系统级联仿真开始...");

        // 持续仿真直到读完输入文件
        while (!$feof(fp_in)) begin
            @(posedge clk);
            
            // 只有在 25kHz 周期（128个 clk）的起点，才读取下一个输入点
            if (cnt == 0) begin
                r = $fscanf(fp_in, "%d\n", data_in);
            end
            
            // 每个时钟周期 (3.2MHz) 都将 SDM 的调制结果写入 txt 文件
            // 用 $fdisplay 自动换行，方便 MATLAB 的 load 函数直接读取
            $fdisplay(fp_out, "%d", data_out);
            
            // 128x 插值计数器控制
            if (cnt == 127) 
                cnt = 0;
            else 
                cnt = cnt + 1;
        end

        $display("仿真结束！码流文件已生成: sdm_output_data.txt");
        $fclose(fp_in); 
        $fclose(fp_out);
        $finish;
    end
endmodule