# FPGA Design

本目录保存微环调制器波长调节驱动器的 FPGA 数字链路源码、输入数据和辅助脚本。

## Signal Chain

```text
low-rate input -> 128x interpolation -> 3rd-order 4-bit Sigma-Delta modulator -> digital output / DAC driver
```

插值链路由 2x FIR、4x FIR 和 16x repeat/hold 组成，将低速输入样本提升到 Sigma-Delta Modulator 所需的工作速率。

## Files

| File | Description |
| --- | --- |
| `system_top.v` | 纯数字系统顶层，用于功能仿真和链路级验证。 |
| `FPGA_top.v` | FPGA 板级验证顶层，包含时钟生成、ROM 数据源和 ILA 观测逻辑。 |
| `FPGA_TOP_DAC.v` | FPGA + 商用 DAC 联调顶层。 |
| `dac_sdm_driver.v` | DAC 输出接口驱动，将 SDM 4-bit 输出转换为 DAC 数据/时钟格式。 |
| `interpolation_filter/interpolation_top.v` | 128x 插值链路顶层。 |
| `interpolation_filter/fir_stage1.v` | Stage-1 2x FIR 插值滤波器。 |
| `interpolation_filter/fir_stage2.v` | Stage-2 4x FIR 插值滤波器。 |
| `interpolation_filter/repeat_16x.v` | Stage-3 16x repeat/hold 逻辑。 |
| `interpolation_filter/fpga_verification_top.v` | 早期/独立 FPGA 验证顶层示例。 |
| `sigma_delta/sdm_cifb_3rd_4bit.v` | 3 阶 CIFB 4-bit Sigma-Delta Modulator。 |
| `data_sin/perfect_sine.txt` | 参考正弦输入数据。 |
| `data_sin/din_fixed.txt` | 定点输入数据。 |
| `data_sin/din_fixed.coe` | Vivado ROM/IP 初始化文件。 |
| `data_sin/txt_to_coe.py` | 文本数据到 COE 的转换脚本。 |

## Suggested Verification Order

1. 从 `system_top.v` 开始做纯数字仿真，确认插值链路和 SDM 功能。
2. 使用 `FPGA_top.v` 做板级数字链路验证，通过 ILA 观察输入、插值输出和 SDM 输出。
3. 使用 `FPGA_TOP_DAC.v` 与 `dac_sdm_driver.v` 做商用 DAC 联调。

## External IP Notes

板级顶层中引用了 Vivado 工程内的外部 IP，例如 clock wizard、block memory generator 和 ILA。仓库归档的是手写源码和初始化数据，不包含 Vivado 生成目录；复现时需要在 Vivado 工程中按顶层端口重新创建或绑定这些 IP。
