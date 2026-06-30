%% -------------------- 系统采样率配置 -----------------------
BW      = 10e3;            
OSR     = 128;             
fs_out  = 3.2e6;           
fs_in   = fs_out/OSR;      
L1=2; L2=4; L3=16;         
fs1 = fs_in * L1;          
fs2 = fs1   * L2;          
fprintf('fs_in=%.3f kHz, fs1=%.3f kHz, fs2=%.3f kHz, fs_out=%.3f MHz\n', ...
        fs_in/1e3,fs1/1e3,fs2/1e3,fs_out/1e6);

%% ============================================================
%  Stage-1 : 2× Halfband FIR 
% ============================================================
Ap1_dB = 0.00024; 
As1_dB = 100;               
devp1 = (10^(Ap1_dB/20)-1)/(10^(Ap1_dB/20)+1); devs1 = 10^(-As1_dB/20);
fp1 = 0.44*(fs1/2); fsb1= 0.56*(fs1/2);        

[n1,fo1,ao1,w1_vals] = firpmord([fp1 fsb1]/(fs1/2), [1 0], [devp1 devs1]);
h1 = firpm(101, fo1, ao1, [1.2 1]); 
h1 = h1/abs(sum(h1)); % 归一化

spec1 = measure_specs_fir(h1,fs1,11.0125e3,13.9875e3,'Stage-1 半带滤波器');
print_spec_table(spec1,0.000250,90);

%% ============================================================
%  Stage-2 : 4× 低通 FIR 
% ============================================================
fp2=11e3; fsb2=38e3; Ap2_dB=0.002; As2_dB=100;
devp2=(10^(Ap2_dB/20)-1)/(10^(Ap2_dB/20)+1); devs2=10^(-As2_dB/20);
h2 = firpm(41, [0 fp2*2/fs2 fsb2*2/fs2 1], [1 1 0 0]);
h2 = h2/abs(sum(h2)); 

spec2 = measure_specs_fir(h2,fs2,fp2,fsb2,'Stage-2 1/4带低通');
print_spec_table(spec2,0.002,70);

%% ============================================================
%  级联整体
% ============================================================
Nw = 2^15; w = linspace(0,pi,Nw);
Htot = polyval(h1,exp(1j*w/4).^(-1)) .* polyval(h2,exp(1j*w).^(-1)); fHz = w/(2*pi)*fs2;
pb=fHz<=10e3; sb=fHz>=40e3 & fHz<=fs2/2;
Htot_mag = abs(Htot) / abs(Htot(1));
fprintf('\n---------------- 级联整体 ----------------\n');
fprintf('通带(0-10 kHz) 纹波 : %.4f dB\n',20*log10(max(Htot_mag(pb))/min(Htot_mag(pb))));
fprintf('阻带(>=40 kHz) 最大抑制 : %.1f dB\n',-20*log10(min(Htot_mag(sb))));
fprintf('阻带(>=40 kHz) 最差抑制 : %.1f dB\n',-20*log10(max(Htot_mag(sb))));

[~,h1_hex]=quantize_to_q15_hex(h1);
[~,h2_hex]=quantize_to_q15_hex(h2);
writelines(h1_hex,'coeff_hbf_int16.hex'); writelines(h2_hex,'coeff_qbf_int16.hex');
fprintf('\nExported: coeff_hbf_int16.hex, coeff_qbf_int16.hex\n');

%% ============================================================
%  时域仿真与高性能 SNR 引擎 (保留 114dB 逻辑)
% ============================================================
Nfft_out = 2^18;
dur = 0.5; t_in = (0:round(dur*fs_in)-1)'/fs_in;
k_bin_ideal = 819; % 针对 2^18 的相干点
f_tone = k_bin_ideal * (fs_out / Nfft_out); 
Ain = 0.88; 
x_in = Ain * sin(2*pi*f_tone*t_in);

y1 = upfirdn(x_in, h1*L1, L1, 1);
y2 = upfirdn(y1, h2*L2, L2, 1);

yy_target = y2;
fs_snr = fs2;
Nfft_snr = round(Nfft_out / L3); 
theory_delay = (101/2 * L2) + (41/2);
yy = yy_target(ceil(theory_delay) + 2000 + (1:Nfft_snr));

% --- FFT 法 (Bin 修正版) ---
Y = fft(yy .* blackman(Nfft_snr), Nfft_snr);
P = abs(Y(1:Nfft_snr/2+1)).^2;
% 在 1kHz-12kHz 内重新检索最强 Bin
[~, max_idx] = max(P(floor(1000/fs_snr*Nfft_snr):floor(12000/fs_snr*Nfft_snr)));
sig_bin = max_idx + floor(1000/fs_snr*Nfft_snr) - 1;
sig_range = sig_bin-2:sig_bin+2;
P_sig = sum(P(sig_range));
Kbw = floor(BW/fs_snr*Nfft_snr);
noise_bins = setdiff(2:Kbw, sig_range); 
snr_fft = 10*log10(P_sig / (sum(P(noise_bins)) + eps));

% --- Fit Residual 法 ---
n_idx = (0:Nfft_snr-1)'; 
X_fit = [sin(2*pi*f_tone/fs_snr*n_idx), cos(2*pi*f_tone/fs_snr*n_idx), ones(size(n_idx))];
ab = X_fit \ yy;
y_hat = X_fit * ab;
snr_fit = 10*log10(mean(y_hat.^2)/mean((yy - y_hat).^2));

% --- 16-bit 定点 SNR ---
yq = round(yy * 8388608) / 8388608;
snr_q15 = 10*log10(mean(y_hat.^2)/mean((yq - y_hat).^2));

fprintf('\nIn-band SNR (FFT method): %.2f dB\n', snr_fft);
fprintf('In-band SNR (Fit Residual): %.2f dB\n', snr_fit);
fprintf('SNR with 16-bit Quantization: %.2f dB\n', snr_q15);
fprintf('All done.\n');






yq = round(yy * 32768) / 32768; 
[b_eval, a_eval] = butter(6, 10e3/(fs_snr/2)); % 设计一个 10kHz 的理想低通评估滤波器
yq_inband = filter(b_eval, a_eval, yq);
y_hat_inband = filter(b_eval, a_eval, y_hat);

% --- 3. 计算带内信噪比 (In-band SNR) ---
% 此时噪声只计入 0-10kHz 范围内的量化噪声
err_inband = yq_inband - y_hat_inband;
% 去掉滤波器的暂态响应（前几百个点）
snr_inband = 10*log10(var(y_hat_inband(500:end)) / var(err_inband(500:end)));

fprintf('\n16位输出下的 全带宽 SNR (包含带外噪声): %.2f dB', snr_fit);
fprintf('\n16位输出下的 带内(0-10kHz) SNR: %.2f dB', snr_inband);
%% ============================================================
%  可视化部分：生成 3-3, 3-4, 3-5 图表
% ============================================================

% --- 图 3-3: Stage-1 Halfband ---
figure('Color','w','Name','Stage-1 Response');
[H1_fig, w1_fig] = freqz(h1, 1, 1024);
plot(w1_fig/pi, 20*log10(abs(H1_fig)), 'LineWidth', 0.8);
grid on; hold on;
line([0.5 0.5], [-120 10], 'Color', 'r', 'LineStyle', '--');
text(0.5, 0, '\pi/2', 'Color', 'r', 'Rotation', 90, 'VerticalAlignment', 'bottom');
xlabel('Normalized Frequency (\times \pi rad/sample)');
ylabel('Magnitude (dB)');
title('Stage-1 Halfband | N=101');
axis([0 1 -120 5]);

% --- 图 3-4: Stage-2 Lowpass ---
figure('Color','w','Name','Stage-2 Response');
[H2_fig, f2_fig] = freqz(h2, 1, 1024, fs2);
plot(f2_fig/1e3, 20*log10(abs(H2_fig)), 'LineWidth', 0.8);
grid on; hold on;
line([11.0125 11.0125], [-120 10], 'Color', 'r', 'LineStyle', '--');
line([38 38], [-120 10], 'Color', 'r', 'LineStyle', '--');
text(11.0125, -5, '11.0125 kHz', 'Color', 'r', 'Rotation', 90);
text(38, -5, '38 kHz', 'Color', 'r', 'Rotation', 90);
xlabel('Frequency (kHz)');
ylabel('Magnitude (dB)');
title('Stage-2 LP (4\times) | N=41');
axis([0 100 -120 5]);

% --- : 级联整体与纹波放大 ---
figure('Color','w','Name','Cascade Response');
subplot(2,1,1);
plot(fHz/1e3, 20*log10(Htot_mag), 'LineWidth', 0.8);
grid on;
xlabel('Frequency (kHz)');
ylabel('Magnitude (dB)');
title('级联滤波器整体幅频特性');
axis([0 100 -180 10]);

subplot(2,1,2);
plot(fHz/fs2, 20*log10(Htot_mag), 'LineWidth', 0.8);
grid on;
xlabel('frequency (f/fs)');
ylabel('Gain (dB)');
title('通带纹波放大图');
axis([0 0.1 -1.5 0.1]); % 对应图中 0 到 0.1 的归一化频率范围


%% ============================================================
%  辅助函数
% ============================================================
function spec=measure_specs_fir(h,fs,fp,fsb,label)
    [H,w]=freqz(h,1,65536,fs); Habs=abs(H);
    ip=w<=fp; is=(w>=fsb)&(w<=fs/2);
    spec.ripple_dB=20*log10(max(Habs(ip))/min(Habs(ip))+eps);
    spec.stop_dB=-20*log10(max(Habs(is))+1e-15);
    spec.label=label; spec.fs=fs; spec.N=length(h)-1;
    spec.fp_Hz=fp; spec.fsb_Hz=fsb;
    spec.fp_norm=fp/(fs/2); spec.fsb_norm=fsb/(fs/2);
end

function print_spec_table(spec,pr,ps)
    fprintf('\n---------------- %s ----------------\n',spec.label);
    fprintf('采样率 fs : %8.3f kHz\n',spec.fs/1e3);
    fprintf('滤波器阶数 (N) : %d\n',spec.N);
    fprintf('通带截止 (Hz) : %8.3f kHz (归一化 %.6f)\n',spec.fp_Hz/1e3,spec.fp_norm);
    fprintf('阻带起始 (Hz) : %8.3f kHz (归一化 %.6f)\n',spec.fsb_Hz/1e3,spec.fsb_norm);
    pass_str = 'FAIL'; if spec.ripple_dB <= pr + 1e-10, pass_str = 'PASS'; end
    fprintf('通带纹波 (峰-峰) : %.6f dB [%s 目标=±%.6f dB]\n',spec.ripple_dB,pass_str,pr);
    pass_str2 = 'FAIL'; if spec.stop_dB >= ps, pass_str2 = 'PASS'; end
    fprintf('阻带最小抑制 : %.2f dB [%s 目标>=%.1f dB]\n',spec.stop_dB,pass_str2,ps);
end

function s=ternary(cond,a,b)
    if cond, s=a; else, s=b; end
end

function [hq,hex]=quantize_to_q15_hex(h)
    hq=round(h*32767);
    hex=arrayfun(@(v) sprintf('%04X', typecast(int16(v), 'uint16')), hq, 'UniformOutput', false);
end
