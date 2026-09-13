# tools — STM32 控制台/AI 调试工具集

纯脚本工具集,不绑定任何工程:固件文件、elf、变量名全部作参数传入。
**单一入口 `dt.bat`**,9 个子命令覆盖 J-Link 烧录/自检/GDB Server/RTT、gdb 变量观察、
OpenOCD 替代方案、串口抓取。依赖的可执行文件不用装在本目录(三级查找,见下)。

## 文件树(仅 5 个文件)

```
tools/
├── dt.bat                 ★ 唯一入口:9 个子命令分发
├── uart_capture.py        串口抓取(dt uart 的实现本体)
├── config/
│   └── paths.bat          唯一配置点:工具路径 + 器件/接口/端口/串口
├── bin/                   (可选)放便携版 exe,如 openocd.exe、arm-none-eabi-gdb.exe
└── README.md              本文件
```

## 命令参考(dt <子命令>)

| 子命令 | 用法 | 功能 | 形态 |
|---|---|---|---|
| `check` | `dt check` | J-Link 链路自检(连接+打印寄存器) | 一次性 |
| `flash` | `dt flash <固件.hex\|.bin>` | 烧录并复位运行 | 一次性 |
| `server` | `dt server` | J-Link GDB Server(端口 %GDB_PORT%) | 常驻 |
| `rtt` | `dt rtt [输出文件]` | 抓 RTT 输出(缺省 rtt.log) | 常驻 |
| `read` | `dt read <elf> <变量...>` | 一次性读变量值 | 一次性 |
| `watch` | `dt watch <elf> <变量...>` | 硬件观察点盯变量(新值+调用栈) | 常驻 |
| `ocd-server` | `dt ocd-server` | OpenOCD GDB Server(端口 3333) | 常驻 |
| `ocd-flash` | `dt ocd-flash <固件> [地址]` | OpenOCD 烧录(bin 必须给地址) | 一次性 |
| `uart` | `dt uart [--port COM7] ...` | 串口抓取(uart_capture.py 参数透传) | 常驻 |

典型流程:

```
dt check
dt flash <你的工程>\build\app.hex
dt server &                            # 后台
dt watch <你的工程>\build\app.elf g_counter &   # 后台盯变量
dt read  <你的工程>\build\app.elf g_counter     # 随手查值
dt rtt &                               # 后台抓 RTT(固件需实现 RTT)
dt uart --list                         # 串口抓取(需 pip install pyserial)
```

## 架构(为什么能"控制台调试")

```
 gdb(read/watch) ──TCP──► J-Link GDB Server(dt server)──SWD──► MCU
 JLink.exe(flash/check)  ──────► J-Link 硬件 ─────────────► MCU
 JLinkRTTLogger(rtt)     ◄──RAM 环形缓冲(固件内 RTT 控制块)──► MCU
 pyserial(uart)          ◄──COM 口◄── 固件 USART1 打印
```

- **停机式变量观察**(`watch`):CPU 硬件观察点,任何路径(含 ISR)写入即停,
  输出 `>>> [watch] 变量 = 新值` + 3 层调用栈——"counter 被谁改的"的直接答案
- **RTT**(`rtt`):不停机、不占串口,适合中断打点;要求固件实现 SEGGER RTT 兼容控制块
- **串口**(`uart`):无需调试器的日志通道

## 配置:config/paths.bat(唯一需要按机器修改的文件)

| 变量 | 默认 | 说明 |
|---|---|---|
| `JLINK_DIR` / `TOOLCHAIN_DIR` / `OPENOCD_DIR` | 自动探测 | 三个工具目录;留空走 bin\ 和系统探测 |
| `JLINK_DEVICE` | STM32F429IG | 芯片型号(J-Link flash 算法) |
| `JLINK_IF` | SWD | SWD / JTAG |
| `JLINK_SPEED` | 4000 | 接口时钟 kHz,不稳降到 1000 |
| `GDB_PORT` | 2333 | J-Link GDB Server TCP 端口 |
| `OPENOCD_IF` | stlink.cfg | cmsis-dap.cfg / jlink.cfg 等 |
| `UART_PORT` / `UART_BAUD` | COM5 / 115200 | 串口抓取默认值 |

可执行文件三级查找:`config\paths.bat` 手工指定 → `tools\bin\` 便携目录 →
系统默认位置(`C:\Program Files\SEGGER\JLink*`、CubeIDE 自带 gdb、`C:\Program Files\OpenOCD*`)。

## 外部依赖全量清单

### A. 第三方可执行文件(5 个 exe + 1 个解释器)

| # | 依赖 | 被哪些子命令调用 | 来源 | 缺失时的表现 |
|---|---|---|---|---|
| 1 | JLink.exe | flash、check | SEGGER J-Link Software Pack | "未找到 J-Link 软件包" |
| 2 | JLinkGDBServerCL.exe | server | 同上(⚠️ CubeIDE 精简插件不含) | server 报错并提示补装 |
| 3 | JLinkRTTLogger.exe | rtt | 同上 | rtt 报错 |
| 4 | arm-none-eabi-gdb.exe | read、watch | ARM GNU 工具链(xpack/arm-gnu 或 CubeIDE 自带) | "未找到 arm-none-eabi-gdb" |
| 5 | openocd.exe | ocd-server、ocd-flash | xpack-openocd 等 | "未找到 OpenOCD"(J-Link 路线可完全不用) |
| 6 | Python ≥3.6 | uart | 系统 Python | 脚本无法启动 |

### B. Python 包

| 包 | 安装 |
|---|---|
| pyserial(uart_capture.py 的 `import serial`) | `pip install pyserial`(缺失退出码 2) |

### C. OpenOCD 配置文件(随 OpenOCD 安装)

| 文件 | 说明 |
|---|---|
| interface/stlink.cfg / cmsis-dap.cfg / jlink.cfg | 由 `OPENOCD_IF` 选择,须与调试器匹配 |
| target/stm32f4x.cfg | F4 系列通用;换芯片需改 dt.bat 两处 |

### D. 固件/数据类依赖(输入工件)

| # | 依赖 | 被谁消费 | 要求 |
|---|---|---|---|
| 1 | .hex 或 .bin 固件 | flash / ocd-flash | HEX 自带地址;BIN 给地址(缺省 0x08000000) |
| 2 | .elf(含 DWARF 调试信息) | read / watch | 必须 Debug 构建(-g,建议 -Og) |
| 3 | 变量符号名 | read / watch 参数 | 全局/静态符号;局部变量不可靠 |
| 4 | 固件实现 RTT | rtt | 可选能力;需 RAM 中有 "SEGGER RTT" 控制块 |
| 5 | 固件 UART 配置 | uart | 波特率/COM 与配置一致 |

### E. 硬件

| # | 依赖 | 服务于 |
|---|---|---|
| 1 | J-Link(或 OpenOCD 路线下的 ST-Link/CMSIS-DAP) | 在线调试全部功能 |
| 2 | 目标板供电 | 所有操作 |
| 3 | SWD 接线(SWDIO+SWCLK+GND)或 JTAG 排线 | 与 `JLINK_IF` 一致 |
| 4 | USB-TTL 串口适配器 | 仅 uart,独立于调试器 |

### F. 系统/环境层

| # | 依赖 | 说明 |
|---|---|---|
| 1 | Windows + cmd.exe | .bat 为 GBK+CRLF,依赖中文代码页解析 |
| 2 | %TEMP% 可写 | 动态生成的 *.jlink / *.gdb 临时命令文件 |
| 3 | TCP 端口 2333(J-Link)/ 3333(OpenOCD) | 仅本机回环 |
| 4 | USB 驱动(J-Link 包自带 / ST-Link 驱动)、COM 驱动(CH340/CP2102) | 对应硬件 |
| 5 | `GDB_PORT` 只在 paths.bat 一处,dt 动态生成 gdb 脚本时注入 | 无跨文件同步负担 |

### G. 明确不需要的

- **objdump / nm / size / objcopy**:无脚本调用(nm/objdump 为可选辅助,查地址/反汇编时手动用)
- **CMake / make / gcc**:构建归各工程自己的 build.bat,本工具集零依赖
- **git / IDE / 外网**:均不需要

> 硬依赖主线 = J-Link 官方包 + arm-none-eabi-gdb + 一个 hex/bin + 一个带符号的 elf;
> OpenOCD、pyserial、RTT 固件支持、串口适配器都是可替代或可绕过的分支能力。

## AI 接入约定

1. **常驻子命令**(server / rtt / watch / uart)以后台任务启动,输出落文件再读;
   **一次性子命令**(check / flash / read / ocd-flash)直接调用,看退出码 + stdout
2. 任何 gdb 操作前先确认 `dt server` 已运行;任何烧录前先 `dt check`
3. watch 输出格式:`>>> [watch] 变量 = 值` + 3 层调用栈(修改点的代码路径)
4. 固件须 Debug 构建(-Og -g),变量为全局/静态,才有可靠符号

## 故障排除 FAQ

| 现象 | 处理 |
|---|---|
| 未找到 J-Link 软件包 / gdb / OpenOCD | 装官方包,或便携 exe 放 `bin\`,或改 `config\paths.bat` |
| check 连接失败 | USB 灯 / 供电 / `JLINK_IF` 与接线 / 是否被其他软件占用 |
| gdb 连接被拒 | `dt server` 没启动;端口被占改 `GDB_PORT` |
| 变量 `<optimized out>` / No symbol | Release 构建;改 Debug(-Og -g)重编,或用全局变量 |
| RTTLogger 找不到控制块 | 固件未实现 RTT |
| 串口打不开 / 乱码 | `dt uart --list` 查口;波特率与固件一致 |
| OpenOCD 找不到设备 | `OPENOCD_IF` 与调试器不符(stlink/cmsis-dap/jlink) |
| .bat 打开乱码 | GBK 编码,编辑器选 GB2312/GBK 打开,勿存成 UTF-8 |

## 原理速查

- **GDB Server**:gdb 远程协议 ↔ SWD/JTAG 的翻译器;gdb 走 TCP,可随连随断,Server 常驻
- **硬件观察点**:Cortex-M DWT 地址比较器,CPU 每次访问匹配地址即触发,中断里的写入也抓得到
- **RTT**:目标 RAM 环形缓冲 + 调试口 DMA 读取,单条日志微秒级,不阻塞目标
- **Debug 构建的必要性**:符号→地址映射(DWARF)在编译期生成;-Og 保证变量驻留、断点行号与源码一致

## 维护

- 换芯片:改 `JLINK_DEVICE`;OpenOCD 路线同时改 dt.bat 两处 `target/stm32f4x.cfg`
- 换调试器:J-Link 不动;OpenOCD 改 `OPENOCD_IF`
- 加子命令:在 dt.bat 加一个 `if /i "%SUB%"=="xxx" goto S_XXX` 分支 + 实现块,配置一律来自 paths.bat
- .bat 为 GBK+CRLF(cmd 要求),编辑时选对编码
