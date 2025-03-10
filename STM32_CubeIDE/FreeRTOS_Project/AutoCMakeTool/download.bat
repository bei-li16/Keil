@echo off
set JLINK_PATH="C:\ST\STM32CubeIDE_1.17.0\STM32CubeIDE\plugins\com.st.stm32cube.ide.mcu.externaltools.jlink.win32_2.3.0.202409170845\tools\bin\JLink.exe"                                   
set BUILD_TOOL_DIR=%~dp0
set "DEVICE=STM32F429IG"                                        
set "INTERFACE=JTAG"  
set "SPEED=4000"

@REM 参数处理, 选择下载的hex文件
set "HEX_FILE=%1"

REM 生成临时 J-Link 命令脚本
set COMMAND_FILE=%BUILD_TOOL_DIR%\STM32_commands.jlink
(
    echo device %DEVICE%
    echo speed %SPEED%
    echo JTAGConf 0, 0
    echo if JTAG
    echo connect
    echo halt
    echo loadfile %HEX_FILE%
    echo reset
    echo go
    echo exit
) > "%COMMAND_FILE%"


@REM Download hex file to program flash
echo ============== Download hex file to STM32 ==============
echo %2
@REM %JLINK_PATH% -CommandFile %JLINK_SCRIPT% -AutoConnect 1 -ExitOnError 1 -NoGui 1
%JLINK_PATH% -CommandFile %COMMAND_FILE% -AutoConnect 1 -ExitOnError 1 -NoGui 1

REM 清理临时文件
del %COMMAND_FILE% 2>nul
if %errorlevel% equ 0 (
    echo download %1 success!
    exit /b 0
) else (
    echo download %1 failed!
    exit /b 1
)
