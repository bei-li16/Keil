@echo off
REM ==========================================================================
 REM  paths.bat - tools 工具集的唯一配置点(所有脚本都 call 本文件)
 REM  换机器/换安装位置只改这里;各脚本不含任何硬编码路径
 REM ==========================================================================

REM ------------------- 第 1 部分:用户强制指定(优先级最高) -------------------
REM 留空 = 走下面的"bin 目录探测"和"系统自动探测"
REM 也可写死,例: set "JLINK_DIR=D:\Software\SEGGER\JLink"
set "JLINK_DIR="       REM JLink.exe / JLinkGDBServerCL.exe / JLinkRTTLogger.exe 所在目录
set "TOOLCHAIN_DIR="   REM arm-none-eabi-gdb.exe 所在目录(CubeIDE 自带或独立 ARM 工具链)
set "OPENOCD_DIR="     REM openocd.exe 所在目录(可选,不用 OpenOCD 可留空)

REM ------------------- 第 2 部分:tools\bin 便携目录(次优先) -------------------
REM 把便携版可执行文件直接扔进 tools\bin\ 即可被所有脚本使用,无需安装
if not defined JLINK_DIR if exist "%~dp0..\bin\JLink.exe" set "JLINK_DIR=%~dp0..\bin"
if not defined TOOLCHAIN_DIR if exist "%~dp0..\bin\arm-none-eabi-gdb.exe" set "TOOLCHAIN_DIR=%~dp0..\bin"
if not defined OPENOCD_DIR if exist "%~dp0..\bin\openocd.exe" set "OPENOCD_DIR=%~dp0..\bin"

REM ------------------- 第 3 部分:系统自动探测(最后兜底) -------------------
REM for /d 按目录名通配匹配,多个匹配取最后一个(版本号高的排后面)
if not defined JLINK_DIR (
    for /d %%D in ("C:\Program Files\SEGGER\JLink*") do set "JLINK_DIR=%%D"
)
REM  CubeIDE 捆绑 J-Link 兜底:cmd 的 for /d 不支持中间路径段通配,必须嵌套展开
if not defined JLINK_DIR (
    for /d %%D in ("C:\ST\STM32CubeIDE_*") do for /d %%E in ("%%D\STM32CubeIDE\plugins\com.st.stm32cube.ide.mcu.externaltools.jlink.win32_*") do set "JLINK_DIR=%%E\tools\bin"
)
if not defined TOOLCHAIN_DIR (
    for /d %%D in ("C:\ST\STM32CubeIDE_*") do for /d %%E in ("%%D\STM32CubeIDE\plugins\com.st.stm32cube.ide.mcu.externaltools.gnu-tools-for-stm32.*") do set "TOOLCHAIN_DIR=%%E\tools\bin"
)
if not defined OPENOCD_DIR (
    for /d %%D in ("C:\Program Files\OpenOCD*") do set "OPENOCD_DIR=%%D\bin"
)

REM ------------------- 第 4 部分:目标板 / 调试参数 -------------------
set "JLINK_DEVICE=STM32F429IG"  REM 芯片型号(J-Link 选 flash 算法用)
set "JLINK_IF=SWD"              REM 调试接口 SWD / JTAG
set "JLINK_SPEED=4000"          REM 接口时钟 kHz
set "PROBE_SPEED=1000"         REM probe-reset/run 专用低速(克隆 J-Link V8 实测稳定值)
REM  端口须避开 winnat 保留段(netsh interface ipv4 show excludedportrange protocol=tcp),
REM  本机 2311-2410 被保留,2333 会绑定失败(实测),故用 3333
set "GDB_PORT=3333"             REM J-Link GDB Server TCP 端口
set "OPENOCD_IF=stlink.cfg"     REM OpenOCD 调试器配置:stlink.cfg / cmsis-dap.cfg 等
set "OPENOCD_PORT=3334"         REM OpenOCD GDB Server 端口(与 J-Link 的 3333 错开)
set "UART_PORT=COM3"            REM 调试串口(默认值,uart_capture.py 可用 --port 覆盖)
set "UART_BAUD=115200"          REM 串口波特率,须与目标工程固件配置一致

REM ------------------- 第 5 部分:结果汇报(供人/脚本/AI 判断缺什么) -------------------
echo [paths] JLINK_DIR     = %JLINK_DIR%
echo [paths] TOOLCHAIN_DIR = %TOOLCHAIN_DIR%
echo [paths] OPENOCD_DIR   = %OPENOCD_DIR%
echo [paths] device=%JLINK_DEVICE% if=%JLINK_IF% speed=%JLINK_SPEED%kHz probe=%PROBE_SPEED%kHz gdb_port=%GDB_PORT% uart=%UART_PORT%@%UART_BAUD%
exit /b 0
