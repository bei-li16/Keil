# gcov 覆盖率数据导出:三种方案使用说明

固件端统一由 `BSP/GCOV/bsp_gcov.c` 完成:自定义 `__gcov_init` 收集各插桩单元的
`gcov_info` 指针,导出时逐个调 `__gcov_info_to_gcda()` 序列化成标准 .gcda 字节流,
经三种可选传输层送回主机。**三种方案输出同一种记录流格式**,主机端统一用
`gcov-extract.py` 还原为 `build/<源文件名>.gcda`,再交给现有 `make gcov-report` 出报告。

选型建议(详细对比见下):先跑通 **ram**(最稳),要"不停机持续采集"再上 **rtt**;
**semihost** 适合 ST-LINK+OpenOCD 场景的一次性验证。

## 通用流程

```bash
cd AutoMakeTool
# 1. 构建(插桩 GCOV_FILES 列出的文件,导出代码始终编入)
make GCOV_FILES="bsp_led.c" gcov-build
# 2. 烧录运行: make run  或 J-Link/openocd 手动烧 build/FreeRTOS_STM32F429.hex
# 3. 板上跑测试场景(覆盖率即计数器在 RAM 中累加)
# 4. 按所选方案提取 gcov_blob.bin(见下)
# 5. 还原 .gcda 并出报告
python gcov-extract.py gcov_blob.bin -o build
make gcov-report          # 报告在 gcov_output/*_report.txt / *_branch.txt
```

## 方案 B:RAM 缓冲 + GDB dump(默认,推荐先跑通)

- 原理:固件把记录流写进静态缓冲 `gcov_buf`(8KB,.bss);GDB halt 后
  `dump binary memory` 整块搬回主机。
- 触发:Task1000ms 每秒自动刷新缓冲(`GCOV_BUILD` 宏链入),GDB 里也可
  `call bsp_gcov_dump_all()` 立即取最新值。
- 提取(**推荐 J-Link Commander,真机已验证**):

  ```bash
  "$JLINK_DIR/JLink.exe" -device STM32F429IG -if SWD -speed 1000 -autoconnect 0 \
      -commanderscript gcov-read-ram.jlink
  python gcov-extract.py gcov_blob.bin -o build
  ```

  或 GDB Server 路线(注意其"连接即复位"会清掉已有计数,连接后需重跑采集场景):

  ```bash
  arm-none-eabi-gdb -nx -batch -x gcov-dump-ram.gdb build/FreeRTOS_STM32F429.elf
  python gcov-extract.py gcov_blob.bin -o build
  ```

- 注意:0x20000198 是 `&gcov_buf` 的链接地址,内存布局变化后用
  `arm-none-eabi-nm build/FreeRTOS_STM32F429.elf | grep " b gcov_buf"` 查最新值;
  savebin 的数字按十六进制解析。
- 多轮采集:每轮"复位 → 跑场景 → dump"即可,计数器随复位清零。

## 方案 C:SEGGER RTT 实时流

- 原理:固件把记录流写入 RTT 上行通道 0(`BSP/GCOV/SEGGER_RTT.c` 为 SEGGER 兼容
  最小实现);主机 `JLinkRTTLogger` 挂上通道落盘。上行缓冲 8KB,BLOCK 模式保证
  不丢数据(无接收端时会阻塞任务,所以默认靠 `gcov_stream_enable` 门控)。
- 触发:GDB `set var gcov_stream_enable=1` 后 `call bsp_gcov_dump_all()`;
  或使能后由 Task1000ms 周期导出。
- 采集:

  ```bat
  gcov-rtt-capture.bat          rem 路径按本机 J-Link 驱动目录调整
  ```

  期间触发导出(另一终端用 GDB 连上:`set var gcov_stream_enable=1; call bsp_gcov_dump_all()`)。
- 适合:需要"不 halt 目标持续采集"、一次运行多轮统计时。

## 方案 A:Semihosting 直接写主机文件

- 原理:固件用裸 BKPT 0xAB semihosting 调用(SYS_OPEN/SYS_WRITE/SYS_CLOSE,
  不依赖 rdimon.specs)把记录流写成主机文件 `gcov_blob.bin`。
- 调试器要求:**OpenOCD**(工程根目录 `FreeRTOS_Project.cfg`,ST-LINK DAP)已验证
  命令集;克隆 J-Link V8 对 semihosting 支持不稳,不推荐。每次写文件会短暂停机。
- 触发:GDB `set var gcov_stream_enable=1` 后 `call bsp_gcov_dump_all()`。

  ```bash
  openocd -f ../FreeRTOS_Project.cfg          # 终端 1
  arm-none-eabi-gdb -nx -batch -x gcov-dump-semihost.gdb build/FreeRTOS_STM32F429.elf
  python gcov-extract.py gcov_blob.bin -o build
  ```

## 三方案对比

| | B. RAM+GDB dump | C. RTT 流式 | A. Semihosting |
|---|---|---|---|
| 固件改动 | 无额外依赖 | +SEGGER_RTT.c | 无额外依赖 |
| 是否 halt 目标 | 提取时 halt | 不需要 | 每次写文件短暂停机 |
| 对探针要求 | 任意(GDB Server) | 仅 J-Link | OpenOCD 最佳 |
| 数据完整性 | 确定 | BLOCK 模式保证 | 确定 |
| 无接收端时 | 无影响 | 阻塞(有门控) | open 失败静默丢弃 |
| 典型用途 | 日常用例采集 | 长时间运行/不中断 | ST-LINK 临时验证 |

## 实现备注

- **警告:不要在 GDB 里 `call bsp_gcov_dump_all()`**(真机事故复盘 2025-09-14):
  GDB 的 inferior-call 会把整个 dump 调用链压到** halt 时所在上下文的栈**上;
  目标 halt 在 IDLE 任务时,那就是 128 字(512B)的静态栈——链深溢出即 HardFault
  (当时计数冻结在 526 次=52.6s,正是 call 的时刻)。
  采集一律用 `gcov-read-ram.jlink`(只 halt+savebin,不执行任何目标代码,
  数据靠 Task1000ms 周期刷新)。
- **警告:不要用 taskkill 强杀 GDB Server**:GDB inferior-call 的返回断点是
  FPB 硬件比较器(本轮实例:FP_COMP0=0x480062CD 匹配 Reset_Handler 首地址),
  **跨 SYSRESETREQ/RESETPIN 复位、跨全片擦除重烧存活**;强杀导致断点残留后,
  每次启动执行到该地址即命中无调试器接管的断点事件 → 升级 HardFault
  (FORCED=1 且 CFSR=0)。排障口诀:遇到"启动即 HardFault 且烧录/擦除无效",
  先查 `mem32 0xE0002008`(FP_CTRL)和 `mem32 0xE0002008,8`(FP_COMP0-7),
  清除:`w4 0xE0002008, 0`(逐个比较器写 0)。
- `__gcov_init` 为用户自定义符号,链接器不会拉取 libgcov.a 的 `_gcov.o`
  (fopen 文件路径),运行时仅依赖 `__gcov_info_to_gcda`(独立库成员)与 memcpy。
- 保活链:插桩构造函数 → `__gcov_init` → Task1000ms(`GCOV_BUILD` 宏,
  由 gcov-build 注入)→ `bsp_gcov_periodic()` → `bsp_gcov_dump_all()`,
  确保 `--gc-sections` 不会裁掉导出入口。
- 默认构建(无 GCOV_BUILD)下 bsp_gcov.o/SEGGER_RTT.o 全部被裁剪,零开销。
- 缓冲不够时(RAM 方案溢出/RTT 阻塞超时)按 `.map` 里 `__gcov_.` 符号总量调大
  `GCOV_BUF_SIZE` / `SEGGER_RTT_BUFFER_SIZE_UP`。
