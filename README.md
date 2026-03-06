a Micro-ring modulator made by ty zxy and prison boss
for the sigma_delta ,if you need to connect all the parts,remember not to use the cic fliter,just use the modulator code


# Interpolation Filter

## 目录结构

### src/ - 源代码
- **interpolation_top.v** - 滤波器顶层模块
- **fir_stage1.v** - FIR 第一级子模块
- **fir_stage2.v** - FIR 第二级子模块
- 其他文件用于 FPGA 验证

> **注意**：如果用于 Virtuoso 数字部分仿真，仅需包含 `interpolation_top.v`、`fir_stage1.v` 和 `fir_stage2.v` 即可。

### sim/ - 仿真文件
包含仿真测试相关文件
