@echo off
setlocal
REM ==========================================================================
 REM  rtt_capture.bat - JLinkRTTLogger 抓取目标端 RTT 输出
 REM  用法: rtt_capture.bat [输出文件]   缺省 rtt.log(写到当前目录)
 REM  要求目标固件内置 RTT 输出(如 SEGGER RTT 或兼容实现),
 REM  Logger 自动在 RAM 中搜索 "SEGGER RTT" 控制块
 REM ==========================================================================
call "%~dp0..\config\paths.bat"
if errorlevel 1 exit /b 1

REM ---------- 参数与检查 ----------
REM 缺省输出文件 = 当前目录 rtt.log
set "OUT=%~1"
if "%OUT%"=="" set "OUT=rtt.log"
if not defined JLINK_DIR (
    echo [rtt][ERROR] 未找到 J-Link 软件包,请安装或配置 config\paths.bat
    exit /b 1
)
if not exist "%JLINK_DIR%\JLinkRTTLogger.exe" (
    echo [rtt][ERROR] %JLINK_DIR%\JLinkRTTLogger.exe 不存在
    exit /b 1
)

REM ---------- 启动抓取(前台常驻,后台任务运行后读文件即可) ----------
echo [rtt] logging to %OUT% (Ctrl+C 停止)
 REM  -Device/-If/-Speed:目标与接口;-RTTChannel 0:读上行通道 0
 REM  最后一个参数:输出文件
"%JLINK_DIR%\JLinkRTTLogger.exe" -Device %JLINK_DEVICE% -If %JLINK_IF% -Speed %JLINK_SPEED% -RTTChannel 0 "%OUT%"
