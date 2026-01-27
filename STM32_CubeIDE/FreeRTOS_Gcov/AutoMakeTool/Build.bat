@echo off
setlocal enabledelayedexpansion

REM Set toolchain paths
set "MAKE_DIR=C:\ST\STM32CubeIDE_1.18.1\STM32CubeIDE\plugins\com.st.stm32cube.ide.mcu.externaltools.make.win32_2.2.0.202409170845\tools\bin"
set "COMPILER_DIR=D:\Software\arm-gnu-toolchain-14.3.rel1-mingw-w64-x86_64-arm-none-eabi\bin"
set PATH=%COMPILER_DIR%;%MAKE_DIR%;%PATH%

REM Define project paths and variables
set "BUILD_TOOL_DIR=%~dp0"
set "PROJECT_ROOT=%~dp0..\"

REM Parameter handling: select linker file and project name based on input parameter
if "%1"=="A" (
    set "PROJECT_NAME=FreeRTOS_STM32F429_BANKA"
    set "LINKER_FILE=STM32F429IGTX_FLASH_BANKA.ld"
) else if "%1"=="B" (
    set "PROJECT_NAME=FreeRTOS_STM32F429_BANKB"
    set "LINKER_FILE=STM32F429IGTX_FLASH_BANKB.ld"
) else (
    set "PROJECT_NAME=FreeRTOS_STM32F429"
    set "LINKER_FILE=STM32F429IGTX_FLASH.ld"
)

REM Build the project using make
echo ========== Building project: %PROJECT_NAME% ==========

REM Call make to execute compilation, passing project and linker parameters
set "MAKE_EXE=%MAKE_DIR%\make.exe"
REM Pass variables that match the Makefile: PROJECT and LDSCRIPT. Avoid embedding extra quotes in PROJECT_ROOT.
REM Pass a relative PROJECT_ROOT to make to avoid Windows absolute-path/backslash issues
set "MAKE_PROJECT_ROOT=.."
"%MAKE_EXE%" -f "%BUILD_TOOL_DIR%Makefile" PROJECT=%PROJECT_NAME% LDSCRIPT=%MAKE_PROJECT_ROOT%/%LINKER_FILE% PROJECT_ROOT=%MAKE_PROJECT_ROOT%

if errorlevel 1 (
    echo ========== ERROR: Build failed! ==========
    exit /b 1
) else (
    echo ========== SUCCESS: Build completed! ===========
)

REM If download is needed, call download script
if "%2"=="download" (
    if exist "%BUILD_TOOL_DIR%build\%PROJECT_NAME%.hex" (
        call "%BUILD_TOOL_DIR%download.bat" "%BUILD_TOOL_DIR%build\%PROJECT_NAME%.hex"
    ) else (
        echo ERROR: Hex file not found!
        exit /b 1
    )
)

endlocal
exit /b 0