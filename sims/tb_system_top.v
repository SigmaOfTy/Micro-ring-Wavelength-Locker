`timescale 1ns/1ps

module tb_system_top;
    reg clk;
    reg rst_n;
    
    reg signed [15:0] data_in;
    wire signed [3:0] sdm_out; 

    // 实例化顶层模块
    system_top uut (
        .clk(clk), 
        .rst_n(rst_n),
        .data_in(data_in), 
        .sdm_out(sdm_out)
    );

    // 3.2MHz 主时钟
    initial clk = 0;
    always #156.25 clk = ~clk;

    integer fp_out, fp_interp; // 增加插值输出的文件句柄
    integer cnt;

    real PI = 3.1415926535897932;
    real FS_IN = 25000.0;
    real FREQ_SIG = 10000.0;
    real AMP = 26214.0;
    
    real current_time_sec = 0.0;
    real sin_val;

    initial begin
        $dumpfile("wave_system.vcd");
        $dumpvars(0, tb_system_top);

        rst_n = 0;
        data_in = 0; 
        cnt = 0;
        current_time_sec = 0.0;
        
        // 同时打开两个记录文件
        fp_out = $fopen("sdm_output_data.txt", "w");
        fp_interp = $fopen("interp_output_data.txt", "w");
        
        #1000;
        rst_n = 1;
        $display("系统级联仿真开始...");

        repeat (2097152) begin
            @(posedge clk);
            
            if (cnt == 0) begin
                sin_val = AMP * $sin(2.0 * PI * FREQ_SIG * current_time_sec);
                data_in = $rtoi(sin_val);
                current_time_sec = current_time_sec + (1.0 / FS_IN);
            end
            
            // 记录 4-bit 最终码流
            $fdisplay(fp_out, "%d", sdm_out);
            
            // 【关键】记录插值滤波器输出的 16-bit 信号 (引用 uut 内部连线)
            // 注意：请确认 system_top 内部连接插值器和 SDM 的信号名为 interp_to_sdm
            $fdisplay(fp_interp, "%d", uut.interp_to_sdm);
            
            if (cnt == 127) cnt = 0;
            else cnt = cnt + 1;
        end

        $display("仿真结束！已生成 sdm_output_data.txt 和 interp_output_data.txt");
        $fclose(fp_out);
        $fclose(fp_interp);
        $finish;
    end
endmodule