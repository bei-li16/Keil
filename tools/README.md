# STM32 调试工具

入口按终端选择，参数相同：CMD 用 `dt.bat`，PowerShell 用 `dt.ps1`，Git Bash / WSL 用 `dt.sh`。入口使用随附的 Windows x64 Python 和 pyserial，无需另装 Python 或执行 pip。仅随附调试所需的 GDB、J-Link 命令行组件、STM32F4/J-Link 用 OpenOCD 和精简 Python 运行时。

## 整体迁移

整体复制 `tools`，或解压仓库外置归档目录 `debug_artifacts/stm32-debug-minimal-windows-x64.zip`。在新位置先运行：

```bat
tools\verify_tools.bat --full
tools\dt.bat uart --list
tools\dt.bat check
tools\dt.bat read "firmware\app.elf" xTickCount
```

`verify_tools` 仅检查软件，不连接探针；`check` 会连接并暂停、恢复目标。ELF/HEX 是用户工程产物，请另外携带。调试程序和资源固定从当前 tools 读取，缺少文件会报错；不搜索系统安装目录，不接受外部工具路径覆盖，无需配置系统 PATH 或联网下载。推荐 Windows 10/11 x64。USB 探针和 USB 串口驱动仍属于系统依赖，完整依赖清单、原始许可证和迁移限制见 [DEPENDENCIES.md](DEPENDENCIES.md)。

二进制目录和分发 ZIP 使用 Git 忽略规则，普通 `git clone` 不包含这些文件；迁移时应使用完整 ZIP 或目录副本。

Git 仅维护入口、脚本、配置、文档、依赖校验清单和 tools 自身的回归测试。`bin/`、`xpack-openocd/`、运行日志/状态、缓存、固件产物及压缩包保留在本地，不提交。`.gitattributes` 固定脚本和配置换行，确保重新检出后配置文件 SHA-256 不变。

## 快速开始（PowerShell，仓库根目录）

```powershell
$elf = './STM32_CubeIDE/FreeRTOS_Project/Debug/FreeRTOS_Project.elf'
./tools/dt.ps1 check
./tools/dt.ps1 flash './STM32_CubeIDE/FreeRTOS_Project/Debug/FreeRTOS_Project.hex'
./tools/dt.ps1 read $elf xTickCount g_w25q_device_id g_w25q_jedec_id
./tools/dt.ps1 gdb $elf 'compare-sections' 'x/4xw &Log_Tx_En'
./tools/dt.ps1 uart --duration 10 --out uart.log --count 'Task100ms'
```

PowerShell 中含 `&`、`>`、`|` 的表达式应通过 `dt.ps1` 或 `tools/bin/python/python.exe tools/dt.py` 传递。CMD 中每个 GDB 表达式用双引号包住；不能把 PowerShell 的单引号规则套到 CMD。

`read/gdb/watch` 默认自动创建并清理独立 GDB Server，无需先执行 `server`。此流程连接时暂停、刷新寄存器缓存，正常结束时显式恢复 CPU，再断开；不会复位 MCU。本机旧 J-Link V8 在持续运行的 Server 中隔一段时间重连会失效，降低 SWD 速度也未解决，独立会话避开了该问题。

## 命令

| 命令 | 用法 / 行为 |
|---|---|
| check | 连接、暂停、打印寄存器后恢复运行 |
| flash | `flash [--hold] IMAGE [BIN_ADDRESS]`；校验、复位；`--hold` 保持暂停 |
| read | `read [--backend jlink\|openocd] ELF EXPR...`；打印每个表达式 |
| gdb | `gdb ELF 'COMMAND'...`；每个参数一条 GDB 命令 |
| watch | `watch [--duration SECONDS] ELF EXPR...`；硬件观察点、数值和 3 层调用栈 |
| halt | 暂停并跨 Commander 会话保持 |
| step | 执行一条机器指令并保持暂停；不是源码行级 step |
| bp | `bp ADDRESS [WAIT_MS]`；复位运行到指定地址；未命中返回失败并暂停 |
| go | 保留 RAM 现场恢复运行 |
| run | 复位、清除 STM32F429 Cortex-M4 的 6 个代码断点及 4 个 DWT 观察点、恢复运行 |
| probe-reset | 以 PROBE_SPEED 重新连接并复位运行，不清所有观察点 |
| server | 持续 J-Link GDB Server，供外部调试器或 `--reuse-server` 使用 |
| ocd-server | 持续 OpenOCD GDB Server |
| server-stop | 只停止此 tools 副本登记且 PID、创建时间、程序路径均匹配的 Server |
| ocd-flash | `ocd-flash IMAGE [BIN_ADDRESS]`；OpenOCD 编程、验证、复位 |
| rtt | `rtt [OUTPUT] [--timeout SECONDS]`；需固件实现 SEGGER RTT 控制块 |
| uart | `uart --list` 或 `uart --port COM3 --baud 115200 --duration 10 --out uart.log --count REGEX` |

- **BIN 必须显式填写地址**，如 `flash app.bin 0x08000000`。HEX/ELF/SREC 自带地址，禁止再传偏移，避免错误搬移镜像。
- `read/gdb/watch` 支持 `--port N` 和 `--reuse-server`。后者直接连接现有 Server，并由调用者负责 Server 生命周期。本机旧探针长时间复用会话的限制仍适用于此选项。
- 其他一次性调试命令默认超时 30 秒，OpenOCD 烧录 60 秒，可用 `--timeout` 调整。`watch --duration` 到时返回 **124**，Ctrl+C 返回 **130**；随后执行 `run` 清除可能残留的硬件观察点。观察点会暂停 CPU，不应用来测量实时任务周期。
- `check/go` 会让 CPU 运行，`bp/run/probe-reset/flash` 会复位；据此选择是否保留现场。
- Commander、独立 GDB 会话、RTT 操作会释放本副本登记的 Server。工具不按进程名批量终止其他调试会话。已有外部 Server 占用端口时，独立会话报错；可显式选择 `--reuse-server`。
- GDB 命令及恢复清理均有完成标记；即使 GDB 后续命令把退出码覆盖成 0，前面的符号错误、内存访问失败仍会判为失败。
- 每次调试输出独立日志目录（默认 `tools/runtime/logs`），Server 身份登记在 `tools/runtime/state`。`DT_LOG_DIR`、`DT_STATE_DIR` 仅用于显式选择输出位置，不参与程序或资源查找；目录需要可写。

## 串口统计

`--count` 可重复；各正则独立计数，一行能匹配多个规则。按完整行添加主机单调时钟时间戳，串口分包不会在行中插入时间。结束时输出未完成的尾行，但不计数。`--count` 默认采集 15 秒，普通采集未给 `--duration` 时持续运行。

日志追加保存接收内容、统计和样例；配置中的端口、波特率均生效。首次打开运行中的串口可能接到半行，主机时钟与 MCU 的 HSI 时钟也存在偏差，行数不能直接等同于严格的实际时间精度。

## 配置

`config/paths.bat` 是统一配置入口。软件目录始终指向当前 tools，覆盖继承的 JLINK_DIR、GDB_DIR、OPENOCD_DIR、OPENOCD_SCRIPTS；不使用 TOOLCHAIN_DIR 查找 GDB。器件、速度、端口等非路径参数仍可用环境变量覆盖。直接调用 dt.py 使用同一规则，缺少内置程序或资源时立即报错。

| 配置 | 默认 |
|---|---|
| JLINK_DIR / GDB_DIR / OPENOCD_DIR | 固定为 tools 下 bin/jlink、bin/gdb/bin、xpack-openocd/bin |
| JLINK_DEVICE / JLINK_IF | STM32F429IG / SWD |
| JLINK_SPEED / PROBE_SPEED | 4000 / 1000 kHz |
| GDB_PORT / OPENOCD_PORT | 3333 / 3334，仅本机 |
| DEBUG_BACKEND | jlink |
| OPENOCD_IF / OPENOCD_TRANSPORT | jlink.cfg / swd |
| OPENOCD_TARGET / OPENOCD_SPEED | target/stm32f4x.cfg / 4000 kHz |
| OPENOCD_SCRIPTS | 固定为 tools/xpack-openocd/openocd/scripts |
| UART_PORT / UART_BAUD | COM3 / 115200 |

换芯片时要同时检查 `run` 的 FPB/DWT 寄存器数量；当前清理实现针对 STM32F429 Cortex-M4。

GDB 使用标准可迁移布局：程序位于 `bin/gdb/bin`，数据位于 `bin/gdb/arm-none-eabi/share/gdb`，独立符号位于 `bin/gdb/lib/debug`。dt 启动时使用 `-nx` 忽略系统和用户初始化脚本，并明确设置内部数据、符号和自动加载目录。直接检查原厂 EXE 的默认资源目录也会指向当前 tools；`show configuration` 中的原厂编译路径是构建元数据，不是生效的资源路径。

OpenOCD 顶层配置和嵌套 `find` 引用仅允许随附脚本目录中的文件；当前工作目录或外部 OPENOCD_SCRIPTS 不能替代它们。其他芯片/探针的配置应添加到 tools 内。调试子进程 PATH 仅含内置工具目录及 Windows 系统目录。

ELF 及源码是用户输入，允许位于 tools 外。若 ELF 的编译目录来自另一台电脑，使用 GDB `set substitute-path` 映射到新的源码位置，或在新位置重新编译；tools 不改写 ELF 的调试信息。

## 工程构建属于外部依赖

本目录只提供调试工具，不包含 GCC、CMake、Make、头文件或目标运行库。工程中的 AutoCMakeTool/Build.bat 属于工程构建流程，由调用方另行提供编译环境和 TOOLCHAIN_DIR、CMAKE_DIR、MAKE_DIR；调试配置不再自动发现或填写编译器路径，也不会把编译环境变量用于调试程序查找。

## 回归与实测范围

```powershell
./tools/bin/python/python.exe -B -m unittest discover -s tools/tests -v
```

20 项离线测试不连接板卡，覆盖参数/镜像地址、失败传播、进程身份、锁和自动清理、串口分包与统计，以及外部工具覆盖、缺失内置程序、GDB 资源目录、OpenOCD 外部脚本回退。测试只需要完整 tools 包，不再依赖工程源码、工程构建脚本或主机 GCC。测试报告保存在仓库 `debug_artifacts`，不随调试目录携带。

本机 OpenOCD 使用现有 J-Link 驱动时返回 `LIBUSB_ERROR_NOT_SUPPORTED`，因此其硬件烧录链路未通过；没有修改系统 USB 驱动。固件目前没有 RTT 控制块。WSL 入口已支持 wslpath，但本次只实测了 CMD、PowerShell 和 Git Bash。
