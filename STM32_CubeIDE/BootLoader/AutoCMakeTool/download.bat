@echo off
set JLINK_PATH="C:\ST\STM32CubeIDE_1.17.0\STM32CubeIDE\plugins\com.st.stm32cube.ide.mcu.externaltools.jlink.win32_2.3.0.202409170845\tools\bin\JLink.exe"  
@REM set "PROJECT_HEX=.\build\*.hex"                                  
set PROJECT_DIR=%~dp0                                         

echo download hex file...
echo %PROJECT_DIR%flash.jlink
%JLINK_PATH% -CommandFile %PROJECT_DIR%flash.jlink -AutoConnect 1 -ExitOnError 1 -NoGui 1

@REM set SCRIPT_FILE=flash.jlink
@REM set HEX_FILE=BootLoader.hex
@REM echo %SCRIPT_FILE%
@REM echo %HEX_FILE%

@REM echo 正在烧录程序...
@REM %JLINK_PATH% %SCRIPT_FILE% %HEX_FILE%

if %errorlevel% equ 0 (
    echo download success!
) else (
    echo download failed!
)
pause