# FreeRTOS STM32F429 Project

## 项目概述

本项目是基于STM32F429IGT微控制器的FreeRTOS嵌入式开发项目，支持GCov代码覆盖率统计。项目包含HAL驱动、FreeRTOS实时操作系统、以及各种BSP驱动组件。

## 目录结构

```
FreeRTOS_Gcov/
├── AutoMakeTool/          # Make构建系统（推荐）
├── AutoCMakeTool/         # CMake构建系统
├── BSP/                   # 板级支持包
│   ├── LED/              # LED驱动
│   ├── LOG/              # 日志系统
│   ├── USER_TASK/        # 用户任务
│   └── W25Q128/         # W25Q128 Flash驱动
├── Core/                  # 核心系统文件
│   ├── Inc/              # 头文件
│   ├── Src/              # 源文件
│   └── Startup/          # 启动文件
├── Drivers/               # STM32 HAL驱动
├── Middlewares/           # 中间件
│   └── Third_Party/FreeRTOS/  # FreeRTOS系统
└── README.md             # 项目说明文档
```

## 构建系统

### 1. Make构建系统（推荐）

`AutoMakeTool`目录包含基于Make的跨平台构建系统，具有以下特性：

#### 特性
- **动态源文件发现**：自动扫描项目目录，无需手动维护文件列表
- **跨平台兼容**：支持Windows和Linux环境
- **并行编译**：支持多线程编译加速构建
- **智能依赖管理**：自动处理编译依赖关系
- **详细帮助系统**：内置完整的使用说明

#### 快速开始

```bash
# 显示帮助信息
make help

# 编译项目
make all

# 清理并重新构建
make clean all

# 4线程并行编译
make -j4

# 查看内存使用情况
make info
```

#### 自定义构建

```bash
# 自定义项目名称
make PROJECT=MyCustomProject

# 使用自定义链接脚本
make LDSCRIPT=custom.ld

# 指定工具链路径
make COMPILER_DIR=/path/to/toolchain

# 指定构建输出目录
make BUILD_DIR=output
```

#### 支持的目标

| 目标 | 描述 |
|------|------|
| `make help` | 显示帮助信息 |
| `make all` | 编译所有文件并生成elf、hex、bin文件 |
| `make clean` | 清理构建目录 |
| `make distclean` | 完全清理（包括项目根目录的输出文件） |
| `make rebuild` | 清理并重新构建 |
| `make info` | 显示内存使用情况 |
| `make debug-objs` | 调试：显示对象文件路径 |
| `make print-sources` | 调试：显示发现的源文件 |

#### 工具链配置

- **Windows**: 默认使用STM32CubeIDE 1.18.1工具链
- **Linux**: 默认使用/opt/st/stm32cubeide_1.18.1工具链

可通过环境变量或命令行参数覆盖工具链路径：

```bash
# Windows
make COMPILER_DIR=C:/Custom/Toolchain/Path

# Linux
make COMPILER_DIR=/custom/toolchain/path
```

### 2. CMake构建系统

`AutoCMakeTool`目录包含基于CMake的构建系统：

```bash
# 使用Build.bat构建（Windows）
.\Build.bat [param1]

# 参数说明
# param1: bankname，可选A, B, ALL
```

#### CMake工具说明

| 工具 | 功能 |
|------|------|
| `Build.bat` | 构建入口程序 |
| `download.bat` | JLink下载脚本 |
| `gen_cmake.py` | 自动生成CMakeLists.txt |
| `merge_hex.py` | 合并A/B分区hex文件 |
| `arm-gcc-toolchain.cmake` | CMake工具链定义 |

## 硬件平台

- **微控制器**: STM32F429IGT6
- **内核**: ARM Cortex-M4
- **主频**: 180MHz
- **Flash**: 1MB (双Bank)
- **RAM**: 256KB
- **FPU**: 单精度浮点单元

## 开发环境

### 推荐工具

1. **IDE**: STM32CubeIDE 1.18.1+
2. **工具链**: ARM GNU Toolchain 13.3+
3. **调试器**: ST-Link V2/V3 或 JLink
4. **终端**: Windows PowerShell / Linux Bash

### 系统要求

- **Windows**: Windows 10/11, STM32CubeIDE 1.18.1+
- **Linux**: Ubuntu 20.04+, ARM GCC Toolchain

## 功能特性

- **实时操作系统**: FreeRTOS v10.3.2
- **HAL驱动**: STM32F4xx HAL Driver
- **代码覆盖率**: Gcov集成支持
- **多任务**: 支持多任务并发执行
- **设备驱动**: LED, UART, SPI, Flash等
- **日志系统**: 集成调试日志输出

## 注意事项

1. **内存配置**: 项目使用Bank A作为默认启动区域
2. **时钟配置**: 外部晶振25MHz，系统时钟180MHz
3. **调试串口**: USART1 (PA9/PA10)
4. **Flash**: W25Q128通过SPI5接口连接

## 故障排除

### 常见问题

1. **编译错误**: 检查工具链路径是否正确
2. **链接错误**: 确认FreeRTOS port文件已包含
3. **下载失败**: 检查调试器连接和目标板电源

### 调试命令

```bash
# 查看发现的源文件
make print-sources

# 查看对象文件路径
make debug-objs

# 检查内存占用
make info | grep -E "(text|data|bss)"
```

## 版本历史

- v1.0.0: 初始版本，基本FreeRTOS功能
- v1.1.0: 添加Make构建系统
- v1.2.0: 跨平台兼容性改进

## 许可证

本项目采用MIT许可证，详见LICENSE文件。

## 贡献

欢迎提交Issue和Pull Request来改进项目。
