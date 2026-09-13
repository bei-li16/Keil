@echo off
setlocal
REM ==========================================================================
 REM  check_jlink.bat - J-Link 链路连通性自检(装好驱动后第一个跑的脚本)
 REM  验证 驱动 -> USB -> J-Link -> 目标板 全链路,能打印寄存器即链路正常
 REM ==========================================================================
call "%~dp0..\config\paths.bat"
if errorlevel 1 exit /b 1

REM ---------- J-Link 软件包检查 ----------
if not defined JLINK_DIR (
    echo [check][ERROR] 未找到 J-Link 软件包 ^(自动探测失败且未手工配置^)
    echo [check]        1. 安装 SEGGER J-Link Software and Documentation Pack
    echo [check]        2. 或把便携版放进 tools\bin\,或编辑 config\paths.bat
    exit /b 1
)
if not exist "%JLINK_DIR%\JLink.exe" (
    echo [check][ERROR] %JLINK_DIR%\JLink.exe 不存在
    exit /b 1
)

REM ---------- 生成自检命令 ----------
set "CMDF=%TEMP%\tools_check.jlink"
 REM  目标芯片型号
>  "%CMDF%" echo device %JLINK_DEVICE%
 REM  调试接口与速度
>> "%CMDF%" echo si %JLINK_IF%
>> "%CMDF%" echo speed %JLINK_SPEED%
 REM  连接目标(失败会因 ExitOnError 退出非零)
>> "%CMDF%" echo connect
 REM  停核后打印内核寄存器 —— 能打印说明链路完全通
>> "%CMDF%" echo h
>> "%CMDF%" echo regs
>> "%CMDF%" echo q

REM ---------- 执行 ----------
echo [check] 连接测试: %JLINK_DEVICE% / %JLINK_IF% / %JLINK_SPEED%kHz
"%JLINK_DIR%\JLink.exe" -CommandFile "%CMDF%" -AutoConnect 1 -ExitOnError 1 -NoGui 1
if errorlevel 1 (
    echo [check][FAIL] 连接失败,依次排查:J-Link USB 指示灯 / 目标板供电 /
    echo [check]       接口模式与接线 ^(SWD 需 SWDIO+SWCLK+GND^) / 是否被其他软件占用
    exit /b 1
)
echo [check][OK] J-Link 链路正常
endlocal
exit /b 0
