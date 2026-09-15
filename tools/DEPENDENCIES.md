# 最小调试工具集

面向 Windows 10/11 x64、STM32F429/STM32F4、J-Link SWD 调试。
只携带现有调试命令需要的程序；编译环境、驱动安装程序、GUI、示例和完整工具手册不随包携带。

## 保留内容

| 目录 | 内容 | 原因 |
|---|---|---|
| bin/gdb | bin/arm-none-eabi-gdb.exe、内部资源目录、原许可说明 | 加载 ELF、断点、观察点、变量和寄存器读取 |
| bin/jlink | JLink.exe、JLinkGDBServerCL.exe、JLinkRTTLogger.exe、JLink_x64.dll、原许可 | 当前三个命令行程序均为 x64；无需 32 位 DLL、GUI 或 Qt |
| bin/python | python.exe、核心 DLL/标准库 ZIP、必需扩展、VC DLL、pyserial、许可 | dt 脚本、进程管理、串口和自检 |
| xpack-openocd | openocd.exe、libusb/libftdi DLL、4 个脚本及运行组件许可 | J-Link 接口、STM32F4 目标 |

GDB 14.2.90.20240526-git（STM32 13.3.rel1）、J-Link V7.94e、OpenOCD 0.12.0+dev-01685、Python 3.13.5、pyserial 3.5 均沿用已经验证的版本。

J-Link DLL 约 21.5 MiB，含设备支持，是该版本命令行程序必需的原厂二进制。本次只裁剪文件，不改写 EXE/DLL。

Python 保留 _ctypes/libffi、_socket、select、unicodedata，以及回归测试依赖的 _overlapped；保留完整压缩标准库以支持脚本导入。移除 OpenSSL、SQLite、GUI 解释器和未用扩展。SHA-256 使用内置 _sha2，已验证，无需 OpenSSL。这是调试工具专用运行时，不是通用 Python 开发环境。入口使用 -B 避免生成字节码缓存。

OpenOCD 仅随附 interface/jlink.cfg、target/stm32f4x.cfg、target/swj-dp.tcl、mem_helper.tcl。其他芯片/探针需将对应配置补齐到 tools/xpack-openocd/openocd/scripts。config/openocd-portable.tcl 将嵌套 find 限制在该目录，不向系统安装目录或当前工作目录回退。

## 使用与校验

```bat
tools\verify_tools.bat --full
tools\dt.bat uart --list
tools\dt.bat check
tools\dt.bat read "firmware\app.elf" xTickCount
```

所有调试程序和资源固定在当前 tools 内，忽略外部 JLINK_DIR、GDB_DIR、TOOLCHAIN_DIR、OPENOCD_DIR、OPENOCD_SCRIPTS 对调试程序的覆盖。不再搜索 SEGGER、CubeIDE 或 OpenOCD 安装目录。缺失内置程序时直接报错。

GDB 恢复标准目录布局，原厂 EXE 的默认数据和独立符号目录可随 tools 迁移；dt 进一步用启动参数指定内部数据、符号、自动加载目录，并通过 -nx 忽略系统和用户 gdbinit。保留原厂二进制中的编译/PDB 路径元数据，不修改 EXE/DLL。自检同时检查原厂默认目录与 dt 的实际启动目录；--full 按 dependencies.lock.json 逐文件校验 SHA-256。

日志和 Server 状态默认写入 tools/runtime，可显式使用 DT_LOG_DIR/DT_STATE_DIR 选择输出位置。用户 ELF、源码及显式选择的输出目录不属于调试程序依赖，不限制在 tools 内。

Windows 系统 DLL/UCRT、J-Link/USB 串口驱动、用户固件和源码仍由目标电脑提供。复制 tools 不安装驱动。本机旧 J-Link 驱动与 OpenOCD/libusb 的不兼容仍存在，裁剪不会改变驱动绑定。没有 RTT 控制块的固件不能用于验证 RTT 数据接收。

GDB 本身未编译 Python 脚本支持；随附解释器只运行本工具脚本。若要编译工程，另行提供 ARM GCC、CMake、Make，通过 TOOLCHAIN_DIR、CMAKE_DIR、MAKE_DIR 配置。

## 来源与许可证

- GDB：原 CubeIDE 工具链中的单独 EXE；bin/gdb/license.txt、ST-about.html 保留。
- J-Link：原 V7.94e；bin/jlink/Doc/LicenseIncGUI.txt、ST-about.html 保留。
- OpenOCD：原 xPack 包；distro-info/licenses 保留 OpenOCD、libusb、libftdi、libiconv、hidapi 许可。
- Python：[官方 3.13.5 嵌入式包](https://www.python.org/downloads/release/python-3135/)，保留 LICENSE.txt。
- pyserial：[PyPI 3.5](https://pypi.org/project/pyserial/3.5/)，保留 dist-info/LICENSE.txt。

OpenOCD 依赖目录保留许可证、作者和版权文件；历史 NEWS、构建/平台 README 等非运行材料已移除。tools/tests 只保留调试工具回归，不携带工程构建或 W25Q 驱动专项测试。

原下载来源和校验记录保留于工作区 debug_artifacts/history/portable_20260915。J-Link 有再分发限制，向第三方分发时遵循原许可；包未上传或发布。

完整编译器、CMake、Make 和旧大 ZIP 从调试目录移除。以前的报告在 debug_artifacts/history，精简验证在 debug_artifacts/minimal_20260915，最小 ZIP 也放在 debug_artifacts，避免在 tools 中保留重复归档。二进制目录仍被 Git 忽略，请整体复制目录或携带 ZIP。

## 原完整副本

自动审批拒绝递归删除旧工具目录（blocked by policy）。已采用可恢复移动：当前 tools 是最小集，原完整程序和旧 ZIP 保留在 debug_artifacts/full-tools-backup，历史报告在 debug_artifacts/history。当前调试目录已精简，旧副本所占磁盘空间尚未释放。
