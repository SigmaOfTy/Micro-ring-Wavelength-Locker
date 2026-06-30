

clear; clc;


order = 3;        
OSR = 128;        
nlev = 16;       
form = 'CIFB';    
opt = 1;          
H_inf = 1.6;      
f0 = 0;           
xlim = 0.9;       


H0 = synthesizeNTF(order, OSR, opt, H_inf, f0);


[a, g, b, c] = realizeNTF(H0, form);


b(2:end) = 0; 

ABCD0 = stuffABCD(a, g, b, c, form);


[ABCDs, umax] = scaleABCD(ABCD0, nlev, f0, xlim);

[as, gs, bs, cs] = mapABCD(ABCDs, form);


fprintf('====================================================\n');
fprintf('  3阶 4-bit CIFB 调制器 系数计算结果\n');
fprintf('====================================================\n');
fprintf('DAC 反馈系数 (对应图中的 a1, a2, a3):\n');
for i = 1:order
    fprintf('  a%d = %12.8f\n', i, as(i));
end

fprintf('\n级间前馈系数 (对应图中的 c1, c2, c3):\n');
for i = 1:order
    fprintf('  c%d = %12.8f\n', i, cs(i));
end

fprintf('\n局部反馈系数 (用于产生谐振零点，对应图中的 g1):\n');
fprintf('  g1 = %12.8f\n', gs(1)); 

fprintf('\n输入前馈系数 (对应图中的 b1，通常 b1=a1 以节省乘法器):\n');
fprintf('  b1 = %12.8f\n', bs(1));

fprintf('\n最大稳定输入幅度 (umax): %f\n', umax);
fprintf('====================================================\n');
