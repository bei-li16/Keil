# tools 用户手册(STM32 控制台/AI 调试工具集)

> 适用对象:人(命令行使用者)和 AI 助手(通过 Bash/后台任务驱动)。
> 位置:`D:\lb\Keil\tools\`。版本:2026-09 初版。

---

## 1. 总览

### 1.1 这套工具解决什么问题

传统 STM32 调试依赖 IDE(Keil/CubeIDE)的图形界面,人和 AI 都难以介入。
本工具集把调试拆成 **纯命令行动作**,全部可脚本化、可落日志、可被 AI 驱动:

```
 ┌──────────────┐   TCP:2333    ┌──────────────────┐    SWD/JTAG    ┌─────────┐
 │ gdb 客户端    │◄────────────►│ J-Link GDB Server │◄─────────────►│         │
 │ (read/watch) │               │ (gdb_server.bat)  │               │  目标    │
 └──────────────┘               └──────────────────┘                │  MCU    │
 ┌──────────────┐               ┌──────────────────┐                │STM32F429│
 │ JLink.exe    │──────────────►│   J-Link 硬件     │◄─────────────►│         │
 │ (flash/check)│               └──────────────────┘                └────┬────┘
 └──────────────┐               ┌──────────────────┐                     │
 │ RTTLogger    │◄───────RAM共享─┐  RTT 缓冲区(目标固件内)◄────────────┘
 └──────────────┘               └──────────────────┘
 ┌──────────────┐
 │ pyserial     │◄───────COM 口◄──── 目标固件 USART1 打印
 └──────────────┘
```

### 1.2 三条观测通道对比

| 通道 | 工具 | 是否停机 | 时间精度 | 适合 |
|---|---|---|---|---|
| 停机式变量观察 | `gdb\read_vars.bat` / `watch_vars.bat` | 命中即停 | 停机瞬间 | "counter 被谁改的""状态机在哪切换"(**能拿到调用栈**) |
| RTT 实时打点 | `jlink\rtt_capture.bat` | 不停机 | 取决于目标端打点 | 中断触发序列、DMA 完成事件、高频日志 |
| 串口抓取 | `serial\uart_capture.py` | 不停机 | 毫秒级 | 目标固件 printf/日志,无需调试器的场合 |
| (进阶)RAM 事件环形缓冲 | 目标端自实现 + gdb 读 | 只在倒出时停 | DWT 周期级 | 不依赖 RTT 会话的时序分析 |

烧录/自检属于**控制类**动作:`jlink\flash.bat`、`jlink\check_jlink.bat`、`openocd\openocd_flash.bat`。

### 1.3 目录与文件职责

| 文件 | 类型 | 一句话职责 |
|---|---|---|
| `config\paths.bat` | 配置 | 全部工具路径与调试参数,唯一需要按机器修改的文件 |
| `bin\` | 可选 | 放便携版 exe(JLink.exe/openocd.exe/gdb),优先于系统安装 |
| `jlink\check_jlink.bat` | 控制类 | 链路自检:连接目标、打印寄存器 |
| `jlink\flash.bat` | 控制类 | 烧录 hex/bin 并复位运行 |
| `jlink\gdb_server.bat` | 常驻 | J-Link GDB Server,桥接 gdb 与调试口 |
| `jlink\rtt_capture.bat` | 常驻 | 抓 RTT 输出到日志文件 |
| `gdb\gdb_common.gdb` | gdb 脚本 | 连接初始化(被其他 gdb 操作 source) |
| `gdb\read_vars.bat` | 一次性 | 读若干变量当前值后放行目标 |
| `gdb\watch_vars.bat` | 常驻 | 硬件观察点盯变量,打印新值+调用栈 |
| `openocd\openocd_server.bat` | 常驻 | OpenOCD 替代 GDB Server(端口 3333) |
| `openocd\openocd_flash.bat` | 控制类 | OpenOCD 烧录 |
| `serial\uart_capture.py` | 常驻 | 串口抓取落盘(需 pyserial) |

### 1.4 可执行文件的三级查找顺序

脚本**不自带**任何 exe。按以下顺序定位,命中即停:

1. `config\paths.bat` 中手工指定的绝对路径(优先级最高);
2. `tools\bin\` 便携目录(如 `bin\openocd.exe`);
3. 系统自动探测:`C:\Program Files\SEGGER\JLink*`(J-Link 官方包)、
   `C:\ST\STM32CubeIDE_*\...\gnu-tools-for-stm32.*\tools\bin`(CubeIDE 自带 gdb)、
   `C:\Program Files\OpenOCD*`。

---

## 2. 安装与快速上手

### 2.1 需要安装什么

| 软件 | 作用 | 必需? | 获取 |
|---|---|---|---|
| SEGGER J-Link Software Pack | 驱动+JLink.exe+GDBServer+RTTLogger | 用 J-Link 时必需 | segger.com 下载页 |
| ARM 工具链(含 arm-none-eabi-gdb) | gdb 客户端 | 用 gdb 通道必需 | CubeIDE 自带,或 xpack/arm-gnu 独立版 |
| OpenOCD | 免费调试服务器 | 可选 | xpack-openocd |
| Python 3 + pyserial | 串口抓取 | 可选 | `pip install pyserial` |

装好后**先跑 `jlink\check_jlink.bat`**,看到 `[check][OK]` 再继续。

### 2.2 外部依赖全量清单

#### A. 第三方可执行文件(5 个 exe + 1 个解释器)

| # | 依赖 | 被谁调用 | 来源 | 缺失时的表现 |
|---|---|---|---|---|
| 1 | JLink.exe | flash.bat、check_jlink.bat | SEGGER J-Link Software Pack | 报"未找到 J-Link 软件包" |
| 2 | JLinkGDBServerCL.exe | gdb_server.bat | 同上(⚠️ CubeIDE 精简插件不含,需官方完整包) | gdb_server 报错并提示补装 |
| 3 | JLinkRTTLogger.exe | rtt_capture.bat | 同上 | rtt 报错 |
| 4 | arm-none-eabi-gdb.exe | read_vars.bat、watch_vars.bat | ARM GNU 工具链(xpack/arm-gnu 独立版,或 CubeIDE 自带) | 报"未找到 arm-none-eabi-gdb" |
| 5 | openocd.exe | openocd_server.bat、openocd_flash.bat | xpack-openocd 等 | 报"未找到 OpenOCD"(J-Link 路线可完全不用) |
| 6 | Python ≥3.6 | uart_capture.py 运行入口 | 系统 Python | 脚本无法启动 |

前 5 个 exe 按 **`tools\bin\` 便携目录 → 系统默认位置自动探测 → `paths.bat` 手工指定** 三级顺序定位(见 1.4)。

#### B. Python 包

| 包 | 被谁 import | 安装 |
|---|---|---|
| pyserial | uart_capture.py(`import serial`) | `pip install pyserial`(缺失退出码 2) |

其余 import(argparse/sys/time/re/os)均为标准库。

#### C. OpenOCD 配置文件(随 OpenOCD 安装,本工具集不含)

| 文件 | 由谁选择 | 说明 |
|---|---|---|
| interface/stlink.cfg / cmsis-dap.cfg / jlink.cfg | `OPENOCD_IF` | 必须与实际调试器匹配,配错报 "unable to find ... device" |
| target/stm32f4x.cfg | 硬编码在两个 openocd 脚本 | F4 系列通用;换芯片系列需改脚本 |

#### D. 固件/数据类依赖(工具的输入工件)

| # | 依赖 | 被谁消费 | 要求 |
|---|---|---|---|
| 1 | .hex 或 .bin 固件 | flash.bat / openocd_flash.bat | HEX 自带地址;BIN 必须给地址(缺省 0x08000000) |
| 2 | .elf(含 DWARF 调试信息) | read_vars / watch_vars | 必须 Debug 构建(-g,建议 -Og);Release 下变量 `<optimized out>` |
| 3 | 变量符号名(如 g_counter) | gdb 参数 | 须为 elf 中的全局/静态符号;局部变量不可靠 |
| 4 | 目标固件实现 RTT | rtt_capture.bat | RAM 中需有 SEGGER RTT 兼容控制块;**可选能力**,未实现则该通道不可用 |
| 5 | 固件 UART 配置 | uart_capture.py | 波特率与 `UART_PORT`/`UART_BAUD` 一致 |
| 6 | (可选)固件内事件缓冲数组 | `gdb -ex "x/256xw &数组"` | 进阶时序分析的载体,见 5.4 |

#### E. 硬件

| # | 依赖 | 服务于 |
|---|---|---|
| 1 | J-Link 调试器 + USB(或 OpenOCD 路线下的 ST-Link/CMSIS-DAP) | 烧录/自检/GDB Server/RTT |
| 2 | 目标板供电 | 所有操作 |
| 3 | SWD 接线(SWDIO+SWCLK+GND,建议加 RESET)或 JTAG 排线 | 与 `JLINK_IF` 一致 |
| 4 | USB-TTL 串口适配器 + COM 口 | 仅 uart_capture.py,独立于调试器 |

#### F. 操作系统/系统层

| # | 依赖 | 说明 |
|---|---|---|
| 1 | Windows + cmd.exe | .bat 为 GBK 编码 + CRLF,依赖中文代码页(cp936)解析 |
| 2 | `%TEMP%` 可写 | 临时生成的 *.jlink / *.gdb 命令文件 |
| 3 | 本机 TCP 端口 2333(J-Link)、3333(OpenOCD) | 仅本机回环,无外网依赖;被占用则启动失败 |
| 4 | USB 驱动:J-Link 驱动(官方包自带)/ ST-Link 驱动 | 对应调试器路线 |
| 5 | COM 口驱动(CH340/CP2102 等) | 仅串口抓取 |
| 6 | 跨文件一致性:`GDB_PORT` 在 paths.bat 与 gdb_common.gdb 两处写死 | 改端口需同步修改 |

#### G. 明确不需要的依赖

- **objdump / nm / size / objcopy**:当前无任何脚本调用。烧录走 hex、gdb 走 elf。
  它们是可选辅助(nm 查符号地址、objdump -d 反汇编),将来加"按地址直读内存"工具才成为正式依赖。
- **CMake / make / arm-gcc 编译器**:tools 不负责构建,编译归各工程自己的 build.bat,对本工具集零依赖。
- **git / 任何 IDE / 外网连接**:均不需要。

**一句话总结:硬依赖只有"J-Link 官方包 + arm-none-eabi-gdb + 一个 hex/bin + 一个带符号的 elf"这一条主线;OpenOCD、pyserial、RTT 固件支持、串口适配器都是可替代或可绕过的分支能力。**

### 2.3 五分钟上手(以任意工程为例)

```bat
:: 0) 如安装位置非默认,编辑 tools\config\paths.bat

:: 1) 链路自检
tools\jlink\check_jlink.bat

:: 2) 在你的工程里编译出 build\xxx.hex 和 xxx.elf(用工程自己的构建脚本)

:: 3) 烧录
tools\jlink\flash.bat D:\path\to\your_project\build\xxx.hex

:: 4) 起观测(全部后台)
start tools\jlink\rtt_capture.bat            :: RTT(若固件实现了 RTT)
python tools\serial\uart_capture.py          :: 串口(若固件走 UART 打印)
start tools\jlink\gdb_server.bat             :: GDB Server

:: 5) 观测
tools\gdb\read_vars.bat  D:\path\to\xxx.elf g_counter      :: 看一眼当前值
tools\gdb\watch_vars.bat D:\path\to\xxx.elf g_counter      :: 持续盯变化(Ctrl+C 停)
```

---

## 3. 配置详解:`config\paths.bat`

| 变量 | 默认 | 说明 |
|---|---|---|
| `JLINK_DIR` | 自动探测 | JLink.exe / JLinkGDBServerCL.exe / JLinkRTTLogger.exe 所在目录 |
| `TOOLCHAIN_DIR` | 自动探测 | arm-none-eabi-gdb.exe 所在目录 |
| `OPENOCD_DIR` | 自动探测 | openocd.exe 所在目录 |
| `JLINK_DEVICE` | STM32F429IG | J-Link 目标芯片名,决定 flash 算法与连接时序 |
| `JLINK_IF` | SWD | 调试接口,SWD 或 JTAG(与实际接线一致) |
| `JLINK_SPEED` | 4000 | 接口时钟 kHz,连接不稳时降到 1000 |
| `GDB_PORT` | 2333 | J-Link GDB Server 的 TCP 端口(gdb_common.gdb 里写死同值) |
| `OPENOCD_IF` | stlink.cfg | OpenOCD 调试器配置文件:stlink.cfg / cmsis-dap.cfg / jlink.cfg |
| `UART_PORT` | COM5 | 串口抓取默认口(`uart_capture.py --port` 可覆盖) |
| `UART_BAUD` | 115200 | 波特率,必须与目标固件 UART 配置一致 |

修改端口注意:`GDB_PORT` 改了要同步改 `gdb\gdb_common.gdb` 里的 `:2333`。

---

## 4. 各工具详解

### 4.1 `jlink\check_jlink.bat` — 链路自检

**用法**:`tools\jlink\check_jlink.bat`(无参数)
**原理**:动态生成 J-Link Commander 命令序列到 `%TEMP%\tools_check.jlink`,
内容为 `device → si SWD → speed → connect → h(停核) → regs(打印寄存器) → q`,
交给 `JLink.exe -CommandFile ... -ExitOnError 1` 执行。
**判读**:能打印出 PC/SP/xPSR/R0-R12 即整条链路(USB→J-Link→SWD→芯片)正常。
**退出码**:0 = 通过;1 = 任一环节失败(stderr 有排查指引)。

### 4.2 `jlink\flash.bat` — 烧录

**用法**:`tools\jlink\flash.bat <固件.hex 或 .bin>`
**命令序列**:`device → si → speed → connect → h → loadfile → r(复位) → g(运行) → q`
**要点**:
- HEX 内嵌烧写地址;BIN 从 `0x08000000` 开始烧(如需别的地址,用 openocd_flash 带地址参数);
- `h` 先停核再写 flash,否则边跑边写会失败;
- `-ExitOnError 1` 让任何一步失败都返回非零,便于脚本/AI 判断。

### 4.3 `jlink\gdb_server.bat` — GDB Server(常驻)

**用法**:`tools\jlink\gdb_server.bat`(前台常驻;人和 AI 都应以后台任务方式启动)
**架构**:gdb 客户端 ↔ TCP:2333 ↔ GDB Server ↔ SWD ↔ MCU。
**不加 `-singlerun`**:gdb 断开后 Server 存活,可被反复连接——这正是 AI 反复
读变量/下观察点而不重启 Server 的前提。
**停止**:Ctrl+C 或结束进程。

### 4.4 `gdb\gdb_common.gdb` — 公共初始化

被调用方式(AI 常用):
```bat
"%TOOLCHAIN_DIR%\arm-none-eabi-gdb.exe" <工程.elf> -batch ^
    -x tools\gdb\gdb_common.gdb -ex "p 某变量" -ex "detach"
```
逐条含义:`set confirm off`(禁 y/n 询问)、`set pagination off`(禁分页停等)、
`set print pretty on`(结构体多行打印)、`target extended-remote :2333`(连接)。
elf 由命令行加载,变量名/函数名/行号全部来自其中的 DWARF 调试信息——
**因此固件必须 Debug 构建(-Og -g)**,Release(-O2)下变量可能 `<optimized out>`。

### 4.5 `gdb\read_vars.bat` — 一次性读变量

**用法**:`tools\gdb\read_vars.bat <工程.elf> <变量名1> [变量名2] ...`
**原理**:生成临时 gdb 脚本,对每个变量执行 `p <变量>`,最后 `detach` 放行目标。
**注意**:连接期间目标被短暂停机,读取毫秒级完成;适合"随手查状态"。
**前提**:`gdb_server.bat` 已后台运行;变量名存在于该 elf。

### 4.6 `gdb\watch_vars.bat` — 硬件观察点盯变量(核心工具)

**用法**:`tools\gdb\watch_vars.bat <工程.elf> <变量名1> [变量名2] ...`(常驻)
**输出格式**:
```
>>> [watch] g_counter = 42
#0  main () at main.c:87
#1  0x08001234 in ?? ()
...
```
**原理**:`watch` 下的是 CPU **硬件观察点**(DWT 比较器),任何代码路径——主循环、
ISR、DMA 回调——只要写入该地址立即停机;`commands` 块里 `silent`(关默认输出)、
`printf` 打标签、`output <变量>` 按变量自身类型打印新值(整型/浮点/枚举通用)、
`bt 3` 打 3 层调用栈(**直接回答"是哪条代码路径改的它"**)、`continue` 恢复运行。
**这是"counter 变化时机""状态机何时切换"类问题的标准答案来源。**

### 4.7 `jlink\rtt_capture.bat` — RTT 抓取(常驻)

**用法**:`tools\jlink\rtt_capture.bat [输出文件]`,缺省 `rtt.log`(当前目录)。
**原理**:SEGGER RTT = 目标 RAM 里的一块环形缓冲 + 调试口 DMA 搬运;Logger 自动
在 RAM 搜索 `"SEGGER RTT"` 控制块并读取。目标端固件需实现 RTT(官方
SEGGER_RTT.c 或兼容实现,如本仓库曾有 Debug_Lab 的 dbg_rtt.c)。
**优势**:不停机、不占串口、开销微秒级,适合在 ISR 里打点。
**前提**:调试器持续连接;拔 J-Link 前先停本工具。

### 4.8 `openocd\` — OpenOCD 替代方案

`openocd_server.bat` 启动 `-f interface/<OPENOCD_IF> -f target/stm32f4x.cfg`,
gdb 连接 **端口 3333**(与 J-Link 的 2333 互不影响)。
`openocd_flash.bat <固件> [地址]` 用 `program <file> <addr> verify reset exit`
一条龙完成烧写/校验/复位/退出;BIN 必须给地址(缺省 0x08000000),HEX 忽略地址。

### 4.9 `serial\uart_capture.py` — 串口抓取(常驻)

**用法**:`python tools\serial\uart_capture.py [--port COM7] [--baud 115200] [--out uart.log]`,
`--list` 列出系统串口。
**行为**:每块到达数据打相对时间戳 `[   12.345s]`,可打印字节原样、控制/二进制
字节显示 `<hex>`(日志不被污染),终端实时回显 + 文件即时落盘。
**退出码**:2 = 缺 pyserial;1 = 串口打不开;0 = 正常退出。

---

## 5. 典型调试剧本(端到端)

### 5.1 烧一个新固件并确认跑起来
```
jlink\check_jlink.bat
jlink\flash.bat <你的>.hex
jlink\read_vars.bat <你的>.elf <任意全局变量>     :: 读到合理值 = 程序在跑
```

### 5.2 "counter 变量的变化时机"(你提过的场景)
```
jlink\gdb_server.bat        ← 后台
gdb\watch_vars.bat <你的>.elf g_counter   ← 后台,跑 30~60 秒
读 watch 输出:每条 ">>> [watch]" + 调用栈 = 一次修改的发生位置
```
若 counter 由多处递增,调用栈会依次展示各条路径(SysTick/主循环/中断回调),
频率和先后一目了然。

### 5.3 "状态机的切换"
```
gdb\watch_vars.bat <你的>.elf g_fsm_state   ← 后台
(操作设备或等待自动流转)
```
每次切换打出新状态值和切换处的调用栈;若想知道切换的**精确时间间隔**,
在状态机函数里打 RTT/事件点,用 5.4 的时间线看。

### 5.4 "UART 中断触发情况 / DMA 完成中断"(你提过的场景)
```
在固件的回调里加打点(HAL_UARTEx_RxEventCallback / HAL_UART_TxCpltCallback 等),
方式二选一:
  a) 目标固件实现 RTT → jlink\rtt_capture.bat(后台)→ 读 rtt.log
  b) 事件写入 RAM 数组 → jlink\read_vars.bat / gdb -ex "x/256xw &数组" 倒出
jlink\gdb_server.bat       ← 若用 gdb 方式
```
判读:TX_START→TX_DONE 成对出现 = DMA 完成中断正常;RX_IDLE 出现次数 = 收到的
帧数;两条事件的时间戳差 = 中断间隔。

### 5.5 纯串口日志采集(没有/不想用调试器)
```
python serial\uart_capture.py --port COM5 --baud 115200 --out session.log
```

---

## 6. AI 接入约定

给 AI(ZCode 等)的固定约定,已同步写在 `README.md`:

1. **长驻进程一律后台启动**:gdb_server / rtt_capture / uart_capture / watch_vars;
   启动后通过"读日志文件"获取输出,而不是依赖交互终端。
2. **一次性命令直接调用**:flash / read_vars / check_jlink,看退出码 + stdout。
3. **先探测后动作**:任何 gdb 操作前确认 gdb_server 已运行;任何烧录前先 check。
4. **输出解析约定**:watch_vars 的 `>>> [watch] 变量 = 值` + 调用栈;
   rtt/uart 日志的 `[  时间s] ` 前缀行。
5. **固件要求**:带调试符号(Debug 构建);变量是全局/静态(局部变量 watch 不可靠)。

---

## 7. 故障排除 FAQ

| 现象 | 原因与处理 |
|---|---|
| `未找到 J-Link 软件包` | 未装官方包。装 SEGGER J-Link Software Pack,或把便携 exe 放 `tools\bin\`,或改 paths.bat |
| `JLinkGDBServerCL.exe 不存在` | 只装了 CubeIDE 精简插件。补装官方完整包 |
| check 连接失败 | 依次查:J-Link USB 灯/目标板供电/`JLINK_IF` 与实际接线(SWD 需 SWDIO+SWCLK+GND)/被 IDE 或其他烧录器占用 |
| gdb 连接被拒 | gdb_server 没启动,或端口与 paths.bat 的 `GDB_PORT` 不一致 |
| 变量打印 `<optimized out>` 或 `No symbol` | 固件是 Release/-O2 构建,或变量是寄存器缓存的局部变量;改 Debug(-Og -g)重编,或用全局/静态变量 |
| watch 一次都不触发 | 变量地址没变但被 DMA 改写(硬件观察点只盯 CPU 访问);或变量在 CCM RAM(DWT 无法监视,换主 SRAM) |
| RTTLogger 找不到控制块 | 固件没实现 RTT,或控制块不在可搜索 RAM 区;gdb 直读控制块符号兜底 |
| 串口打不开 | 口号错(`--list` 查)、被其他终端占用、USB-TTL 未插 |
| 串口日志乱码 | 波特率与固件不一致;或 8N1 之外的数据位/校验不同 |
| OpenOCD 报 `Error: unable to find CMSIS-DAP device` | `OPENOCD_IF` 与实际调试器不符:ST-Link 用 stlink.cfg,DAP-Link 用 cmsis-dap.cfg,J-Link 用 jlink.cfg |
| .bat 打开是乱码 | 这些文件是 GBK 编码,用 VS Code(选 GB2312/GBK)或 Notepad 打开,勿用 UTF-8 保存 |

---

## 8. 原理速查(30 秒版)

- **GDB Server**:把 gdb 的远程串行协议翻译成调试口的 SWD/JTAG 操作;gdb 走 TCP,
  Server 走 J-Link 硬件,两者解耦,gdb 可随时连/断而 Server 常驻。
- **硬件观察点**:Cortex-M 的 DWT 单元提供若干地址比较器,CPU 每次访问匹配地址
  都触发调试事件——不依赖代码插桩,连中断里的写入都抓得到。
- **RTT**:目标 RAM 里的环形缓冲,固件只做 memcpy,主机经调试口 DMA 读取;
  打印一条日志约几微秒,比 UART 快百倍且不阻塞。
- **HEX vs BIN**:HEX 是带地址和校验的文本记录(直接 loadfile);BIN 是纯二进制
  镜像,烧录时必须显式给起始地址。
- **为什么 Debug 构建**:DWARF 调试信息(符号→地址映射)在编译期生成;`-Og`
  只做不妨碍调试的优化,变量驻留内存、断点行号与源码一致。

---

## 9. 维护与扩展

- **换芯片**:改 `JLINK_DEVICE`;OpenOCD 同时改两处 `target/stm32f4x.cfg`。
- **换调试器**:J-Link 全套不动;OpenOCD 改 `OPENOCD_IF`。
- **加工具**:新脚本放进对应子目录,一律 `call "%~dp0..\config\paths.bat"` 取配置,
  遵循"一次性命令看退出码、常驻进程落文件"两个约定。
- **给新固件加 RTT/事件打点**:参考 SEGGER 官方 RTT(两文件)或自实现兼容控制块
  (RAM 环形缓冲 + `"SEGGER RTT"` 16 字节 ID + up/down 描述符,布局见官方文档)。
