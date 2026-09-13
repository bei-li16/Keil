@echo off
setlocal
REM ==========================================================================
 REM  gdb_server.bat - 启动 J-Link GDB Server(前台常驻,AI 用后台任务运行)
 REM  链路:arm-none-eabi-gdb <--TCP:2333--> GDB Server <--SWD--> MCU
 REM  不加 -singlerun:gdb 断开后 Server 存活,可反复连接
 REM ==========================================================================
call "%~dp0..\config\paths.bat"
if errorlevel 1 exit /b 1

REM ---------- 检查 GDB Server 可执行文件 ----------
if not defined JLINK_DIR (
    echo [gdbserver][ERROR] 未找到 J-Link 软件包,请安装或配置 config\paths.bat
    exit /b 1
)
if not exist "%JLINK_DIR%\JLinkGDBServerCL.exe" (
    echo [gdbserver][ERROR] %JLINK_DIR%\JLinkGDBServerCL.exe 不存在
    echo [gdbserver]        官方完整软件包才含 GDB Server;
    echo [gdbserver]        只有 CubeIDE 精简插件时请补装官方包
    exit /b 1
)

REM ---------- 启动 ----------
echo [gdbserver] device=%JLINK_DEVICE% if=%JLINK_IF% speed=%JLINK_SPEED% port=%GDB_PORT%
echo [gdbserver] gdb 连接方式: target extended-remote :%GDB_PORT%
echo [gdbserver] 本进程常驻,Ctrl+C 停止
 REM  -device/-if/-speed:目标与接口参数;-port:gdb 协议 TCP 端口
 REM  -nogui:纯命令行;-select USB:多调试器时选 USB 上的第一个
"%JLINK_DIR%\JLinkGDBServerCL.exe" -device %JLINK_DEVICE% -if %JLINK_IF% -speed %JLINK_SPEED% -port %GDB_PORT% -nogui -select USB
