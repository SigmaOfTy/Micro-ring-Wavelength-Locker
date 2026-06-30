`timescale 1ns/1ps
/*

module stimulus_gen (
    output reg clk,
    output reg rst_n,
    output reg signed [15:0] data_in
);

    integer cnt;
    real PI = 3.1415926535897932;
    real FS_IN = 25000.0;
    real FREQ_SIG = 10000.0;
    real AMP = 26214.0;
    real current_time_sec;
    real sin_val;

    // 1. 3.2MHz 
    initial begin
        clk = 0;
        forever #156.25 clk = ~clk;   // 312.5ns -> 3.2MHz
    end

    // 2. 
    initial begin
        rst_n = 0;
        data_in = 0;
        cnt = 0;
        current_time_sec = 0.0;

        #1000;          // 1us 
        rst_n = 1;

        forever begin
            @(posedge clk);
            //  128 25kHz
            if (cnt == 0) begin
                sin_val = AMP * $sin(2.0 * PI * FREQ_SIG * current_time_sec);
                data_in = $rtoi(sin_val);
                current_time_sec = current_time_sec + (1.0 / FS_IN);
            end

            if (cnt == 127)
                cnt = 0;
            else
                cnt = cnt + 1;
        end
    end

endmodule
*/
module stimulus_gen (
    output reg clk,
    output reg rst_n,
    output reg signed [15:0] data_in
);

    // =========================================================
    // 
    // =========================================================
    parameter integer MODE = 0;
    // MODE = 0 : +
    // MODE = 1 : 12bit
    // MODE = 2 : 
    // MODE = 3 :  -32768

    // =========================================================
    // 
    // =========================================================
    parameter integer INPUT_DIV = 128;   // 3.2MHz / 128 = 25kHz

    // MODE0 
    parameter integer HOLD_SAMPLES_RANGE = 50;  // 16 * 40us = 640us  5.3*tau_th

    // MODE1 / MODE2 
    parameter integer HOLD_SAMPLES = 50;        // 50 * 40us = 2ms

    // =========================================================
    // 
    // =========================================================
    parameter integer FULL_CODE = 27000;
    parameter integer ZERO_CODE =-27000;
    // =========================================================
    // MODE 0: 
    //  64  640us 640us
    // =========================================================
    parameter integer RANGE_STEPS = 2048;

    // =========================================================
    // MODE 1: 12bit
    // 5nm / 4096  1.22pm
    //   32768 / 4096 = 8
    // =========================================================
    parameter integer EQ_BITS        = 10;
    parameter integer EQ_LSB_CODE    = ((FULL_CODE + 1) >> EQ_BITS); // = 8
    parameter integer PREC_BASE_CODE = 0;
    parameter integer PREC_STEPS     = 16;
    parameter integer PREC_LSB       = EQ_LSB_CODE;

    // =========================================================
    // MODE 2: 
    // =========================================================
    parameter integer DYN_CODE_LOW  = 10000;
    parameter integer DYN_CODE_HIGH = 30000;

    integer i;
    integer tmp_code;

    // =========================================================
    // 3.2MHz 
    // =========================================================
    initial begin
        clk = 0;
        forever #156.25 clk = ~clk;   // 312.5ns -> 3.2MHz
    end

    // =========================================================
    // 25kHz
    // =========================================================
    task wait_one_input_sample;
        integer k;
        begin
            for (k = 0; k < INPUT_DIV; k = k + 1)
                @(posedge clk);
        end
    endtask

    // =========================================================
    //  data_in n 
    // =========================================================
    task hold_n_samples;
        input integer n;
        integer k;
        begin
            for (k = 0; k < n; k = k + 1)
                wait_one_input_sample;
        end
    endtask

    // =========================================================
    // 
    // =========================================================
    initial begin
        rst_n   = 0;
        data_in = ZERO_CODE;

        #1000;
        rst_n = 1;

        // 
        hold_n_samples(10);

        case (MODE)

            // -------------------------------------------------
            // MODE 0: 
            //  640us 64  64 
            //  640us
            // -------------------------------------------------
            0: begin
                // ----------  ZERO_CODE  FULL_CODE ----------
                for (i = 0; i <= RANGE_STEPS; i = i + 1) begin
                    tmp_code = ZERO_CODE + ((FULL_CODE - ZERO_CODE) * i) / RANGE_STEPS;
                    data_in  = tmp_code[15:0];
                    hold_n_samples(HOLD_SAMPLES_RANGE);
                end

                // 32767
                //  HOLD_SAMPLES_RANGE
                // 

                // ----------  FULL_CODE  ZERO_CODE ----------
                for (i = RANGE_STEPS - 1; i >= 0; i = i - 1) begin
                    tmp_code = ZERO_CODE + ((FULL_CODE - ZERO_CODE) * i) / RANGE_STEPS;
                    data_in  = tmp_code[15:0];
                    hold_n_samples(HOLD_SAMPLES_RANGE);
                end

                // 0
                hold_n_samples(HOLD_SAMPLES_RANGE);
            end

            // -------------------------------------------------
            // MODE 1: 12bit
            //  = 8 code  1.22pm
            // -------------------------------------------------
            1: begin
                for (i = 0; i < PREC_STEPS; i = i + 1) begin
                    tmp_code = PREC_BASE_CODE + i * PREC_LSB;
                    data_in  = tmp_code[15:0];
                    hold_n_samples(HOLD_SAMPLES);
                end
            end

            // -------------------------------------------------
            // MODE 2: 
            // -------------------------------------------------
            2: begin
                data_in = DYN_CODE_LOW[15:0];
                hold_n_samples(HOLD_SAMPLES * 2);

                data_in = DYN_CODE_HIGH[15:0];
                hold_n_samples(HOLD_SAMPLES * 4);

                data_in = DYN_CODE_LOW[15:0];
                hold_n_samples(HOLD_SAMPLES * 4);
            end

            // -------------------------------------------------
            // MODE 3:  -32768
            // -------------------------------------------------
            3: begin
                data_in = ZERO_CODE;   // ZERO_CODE = -32768
                // 
                forever hold_n_samples(1000);
            end

            default: begin
                data_in = 0;
                hold_n_samples(20);
            end
        endcase

        $finish;
    end

endmodule