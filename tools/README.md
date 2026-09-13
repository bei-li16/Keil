# tools — STM32 控制台/AI 调试工具集

> **文档导航**:快速总览看本页;架构图、逐工具详解、端到端剧本、AI 接入约定、
> 故障排除 FAQ 见 **[USERMANUAL.md](USERMANUAL.md)**(用户手册)。
> **外部依赖全量清单**(exe/Python包/固件/硬件/系统层)见手册 **2.2 节**。

纯脚本工具集,不绑定任何工程:固件文件、elf、变量名全部作参数传入。
依赖的可执行文件(JLink.exe、arm-none-eabi-gdb.exe、openocd.exe)**不用装在本目录**——
脚本按 `tools\bin\` → 系统默认位置 → `config\paths.bat` 手工配置 三级顺序查找。

## 目录

```
tools/
├── README.md               本页(快速总览)
├── USERMANUAL.md           详细用户手册 ★
├── config/paths.bat        唯一配置点:工具路径 + 器件/接口/端口/串口参数
├── bin/                    (可选)放便携版可执行文件,如 openocd.exe、arm-none-eabi-gdb.exe
├── jlink/
│   ├── check_jlink.bat     J-Link 链路自检(装驱动后第一个跑)
│   ├── flash.bat <hex|bin> 烧录固件
│   ├── gdb_server.bat      起 J-Link GDB Server(端口 2333,常驻)
│   └── rtt_capture.bat     抓 RTT 实时输出 → rtt.log
├── gdb/
│   ├── gdb_common.gdb      gdb 连接初始化(被 source)
│   ├── read_vars.bat       一次性读变量: read_vars.bat <elf> <变量...>
│   └── watch_vars.bat      硬件观察点盯变量变化(打印新值+调用栈)
├── openocd/                (可选,免费替代方案)
│   ├── openocd_server.bat  起 OpenOCD GDB Server(端口 3333)
│   └── openocd_flash.bat   OpenOCD 烧录
└── serial/
    └── uart_capture.py     调试串口抓取(需 pip install pyserial)
```

## 典型流程

```
1. jlink\check_jlink.bat                      # 确认链路
2. <在你的工程里编译>                          # 工程自己的 build.bat
3. jlink\flash.bat <工程>\build\xxx.hex       # 烧录
4. jlink\rtt_capture.bat &                    # 后台抓 RTT
   或 serial\uart_capture.py &                # 后台抓串口
5. jlink\gdb_server.bat &                     # 后台起 GDB Server
6. gdb\watch_vars.bat <elf> g_counter &       # 后台盯变量变化
   gdb\read_vars.bat <elf> g_counter          # 随手查值
```

## AI 接入约定

- **长驻进程**(gdb_server / rtt_capture / uart_capture / watch_vars)一律以后台任务启动,输出落文件再读
- **一次性命令**(flash / read_vars / check)直接调用看退出码和 stdout
- watch_vars 输出中 `>>> [watch] 变量 = 值` 后跟调用栈,即"变量被谁在何处修改"的答案
- 需要调试符号,固件必须 Debug 构建(-Og -g)

## 注意

- 所有 .bat 为 **GBK 编码 + CRLF 换行**(cmd 要求),用支持 ANSI/GBK 的编辑器改
- 接口默认 SWD;JTAG 排线改 `config\paths.bat` 的 `JLINK_IF=JTAG`
- 更换芯片型号改 `JLINK_DEVICE`;OpenOCD 换调试器改 `OPENOCD_IF`
