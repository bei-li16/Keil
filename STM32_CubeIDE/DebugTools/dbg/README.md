# STM32 命令行调试工具集

基于 CubeIDE 1.18.1 捆绑工具（J-Link 驱动 V7.94e，已替换降级版），无需安装任何东西。

## 环境要求

- 工具路径与连接参数集中在 `env.sh`（换工程改这一个文件）
- J-Link 探针独占连接：调试期间不要开 CubeIDE 调试、J-Link Commander、RTT Viewer
- 端口用 3333（2331 曾被 Windows winnat 保留段挡住）

## 常用流程

### 一键调试（编译→唤醒探针→烧录→停在 main）
```bash
./debug.sh          # 增量编译
./debug.sh clean    # 全量重建
```

### 继续调试（芯片停在 main 时）
```bash
./gdb-run.sh myscript.gdb    # 反复执行自定义 GDB 脚本
```
GDB 脚本模板见 `flash.gdb`（烧录）和 `watch-var.gdb`（硬件观察点追踪变量修改）。

### 调试完看运行日志
```bash
./logs.sh           # 放行芯片自由运行 + 串口监听15秒统计
./logs.sh 30        # 监听30秒
```

### 收尾
```bash
./server-stop.sh
```

## 铁律（克隆 J-Link V8 的坑，全部实测踩过）

1. **每次调试前必跑 probe-reset.sh**（或 debug.sh，内含）——探针每次会话后都会退化
2. **只用断点/观察点停芯片**，绝不暂停"全速运行中"的目标（interrupt / monitor halt
   / 运行中继续操作）——会触发探针固件崩溃，之后全部操作报 Cannot access memory
3. **崩溃后跑 probe-reset.sh 即可恢复**，无需拔插 USB
4. **看日志前确认芯片在跑**（LED 在闪）——芯片被 halt 冻住时串口静默（0 字节），
   不是接线问题
5. 双 USB 会话（server + Commander 同时开）会直接搞崩链路——脚本已处理时序，
   不要手动同时开

## 符号与反汇编（离线分析，不用连板子）

```bash
GCC_BIN="<env.sh 里的路径>"
$GCC_BIN/arm-none-eabi-addr2line.exe -e xxx.elf -f 0x5ab8   # 地址->函数:行号
$GCC_BIN/arm-none-eabi-objdump.exe -d xxx.elf               # 全镜像反汇编
$GCC_BIN/arm-none-eabi-nm.exe xxx.elf | grep 函数名          # 符号是否链接进去
```
GDB 内置反汇编：`disassemble /s 函数`、`x/10i $pc`（可读真机 Flash）。
构建生成的 `Debug/*.list` 是现成的源码+汇编对照清单。

## 故障速查

| 现象 | 处理 |
|---|---|
| server-start 报端口被占 | `./server-stop.sh` 后重试 |
| 烧录/断点插入报 Cannot access memory | `./probe-reset.sh` |
| GDB 连接超时 | 确认 server 在跑（server-start），探针唤醒（probe-reset） |
| 串口 0 字节 | 先看 LED 闪不闪：闪=芯片在跑查接线；不闪=芯片被暂停，跑 run.sh |
