# Micro-ring Wavelength Locker

微环调制器波长调节驱动器设计结题资料归档仓库。

本仓库整理了项目结题阶段的报告、答辩材料、FPGA 数字链路源码、MATLAB 设计脚本以及 Cadence/OpenAccess 模拟电路工程文件。仓库根目录已经按工程资料类型重新组织，旧项目文件在本次归档分支中被结题资料替换。

## Project Scope

项目面向微环调制器波长调节驱动器设计，主要资料包括：

- 基于 128x 插值链路和 3 阶 4-bit Sigma-Delta Modulator 的 FPGA 数字验证源码；
- 商用 DAC 联调接口相关 Verilog 顶层与驱动模块；
- 插值滤波器与 Sigma-Delta 参数计算 MATLAB 脚本；
- 4-bit DAC 相关 Cadence/OpenAccess 原理图、符号、Verilog-A/Verilog functional view 与 Maestro 配置；
- 结题报告和答辩文档。

## Repository Layout

```text
.
|-- cadence/
|   `-- 4bitDAC/              # Cadence/OpenAccess library archive
|-- docs/
|   |-- defense/              # Defense slides and presentation materials
|   `-- report/               # Final report
|-- hardware/
|   `-- fpga/                 # FPGA Verilog source, ROM data, utility script
|-- models/
|   `-- matlab/               # MATLAB design and parameter calculation scripts
|-- .gitignore
`-- README.md
```

## FPGA Design

`hardware/fpga/` 中的数字链路为：

```text
low-rate input -> 128x interpolation filter -> 3rd-order 4-bit Sigma-Delta modulator -> DAC interface / debug output
```

关键模块：

| Path | Description |
| --- | --- |
| `hardware/fpga/system_top.v` | 纯数字功能顶层，连接插值滤波器和 Sigma-Delta Modulator。 |
| `hardware/fpga/FPGA_top.v` | FPGA 板级验证顶层，包含时钟、ROM 数据源和 ILA 观测逻辑。 |
| `hardware/fpga/FPGA_TOP_DAC.v` | FPGA + 商用 DAC 联调顶层。 |
| `hardware/fpga/dac_sdm_driver.v` | 将 4-bit SDM 输出映射到 DAC 所需数据/时钟格式。 |
| `hardware/fpga/interpolation_filter/` | 2x FIR、4x FIR 和 16x repeat/hold 组成的 128x 插值链路。 |
| `hardware/fpga/sigma_delta/sdm_cifb_3rd_4bit.v` | 3 阶 CIFB 4-bit Sigma-Delta Modulator 核心。 |
| `hardware/fpga/data_sin/` | 正弦输入数据、定点输入数据、Vivado COE 文件和转换脚本。 |

更多 FPGA 目录说明见 [`hardware/fpga/README.md`](hardware/fpga/README.md)。

## MATLAB Models

`models/matlab/` 包含：

| File | Purpose |
| --- | --- |
| `Filter.m` | 插值滤波器参数、频响、SNR 评估和系数量化导出脚本。 |
| `dsm_parameter_cal.m` | 3 阶 CIFB Sigma-Delta Modulator 参数计算脚本。 |

脚本依赖 MATLAB 及 Delta-Sigma Toolbox / Signal Processing Toolbox 中的相关函数，例如 `synthesizeNTF`、`realizeNTF`、`firpm`、`freqz`。

## Cadence Archive

`cadence/4bitDAC/` 保留 4-bit DAC、解码器、电流源、switch buffer、微环行为模型、testbench、symbol、schematic、functional 和 Maestro 配置等 OpenAccess 工程文件。

本次归档已排除下列临时文件：

- Cadence 锁文件：`*.cdslck`、`*.cdslck.*`；
- 备份文件：`*.bak`、`*.oa-`、`*.cfg%`；
- 仿真运行日志和缓存：`*.log`、`*.rdb`、`*.pak`、`*.db`。

## Documents

| Path | Description |
| --- | --- |
| `docs/report/微环调制器波长调节驱动器设计-张祥云-毕晓君.pdf` | 项目结题报告。 |
| `docs/defense/答辩稿.pdf` | 答辩稿。 |
| `docs/defense/微环调制器波长调节驱动器设计.pdf` | 答辩展示材料。 |

## Recommended Workflow

1. 阅读 `docs/report/` 理解系统指标、设计背景和实现结果。
2. 使用 `models/matlab/` 复现实验参数、滤波器设计和 Sigma-Delta 参数计算。
3. 使用 `hardware/fpga/system_top.v` 进行数字链路仿真。
4. 使用 `hardware/fpga/FPGA_top.v` 做 FPGA 板级数字验证。
5. 使用 `hardware/fpga/FPGA_TOP_DAC.v` 和 `dac_sdm_driver.v` 做 FPGA + DAC 联调。
6. 在 Cadence 环境中打开 `cadence/4bitDAC/` 继续模拟电路和 testbench 验证。

## Notes

- `hardware/fpga/` 源码保留了结题资料中的原始注释和编码状态；本次仅修复了 `system_top.v` 中会导致 SDM 实例化失效的明确语法问题。
- Cadence/OpenAccess 文件建议在原设计环境或兼容版本中打开，跨平台查看时不要批量改写二进制 OA 文件。
- 仓库用于结题资料归档和后续复现实验，不包含 Vivado 工程生成目录、仿真缓存或本地工具锁文件。
