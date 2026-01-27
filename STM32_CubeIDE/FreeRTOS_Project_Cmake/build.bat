@echo off
setlocal enabledelayedexpansion

REM J-Link path
set "JLINK_PATH=C:\ST\STM32CubeIDE_1.18.1\STM32CubeIDE\plugins\com.st.stm32cube.ide.mcu.externaltools.jlink.win32_2.4.0.202501261557\tools\bin\JLink.exe"

REM Get parameters
set CMD=%~1
set BUILD_TYPE=%~2

REM Handle different parameters
if /i "%CMD%"=="clean" goto CLEAN
if /i "%CMD%"=="rebuild" goto REBUILD
if /i "%CMD%"=="run" goto RUN_BUILD

REM Default or specified Release/Debug build
set BUILD_TYPE=%CMD%
if "%BUILD_TYPE%"=="" set BUILD_TYPE=Release

cmake -B build -G "MinGW Makefiles" -DCMAKE_TOOLCHAIN_FILE=gcc.cmake -DCMAKE_BUILD_TYPE=%BUILD_TYPE%
cmake --build build -- -j8
goto END

:RUN_BUILD
REM run parameter: build + download
if "%BUILD_TYPE%"=="" set BUILD_TYPE=Release
cmake -B build -G "MinGW Makefiles" -DCMAKE_TOOLCHAIN_FILE=gcc.cmake -DCMAKE_BUILD_TYPE=%BUILD_TYPE%
cmake --build build -- -j8

REM Download HEX file to STM32
echo ================================================
echo Downloading HEX to STM32...
echo ================================================
echo.

REM Check if J-Link is available
if exist "%JLINK_PATH%" (
    echo [J-Link] Found J-Link Commander
    echo.
    echo "%JLINK_PATH%" -device STM32F429IG -if JTAG -speed 4000 -autoconnect 1 -CommandFile download.jlink
    echo "%JLINK_PATH%" -CommandFile download.jlink
    echo.
    "%JLINK_PATH%" -CommandFile download.jlink
    echo.
    echo [OK] Download completed!
) else (
    echo [ERROR] J-Link not found at:
    echo   %JLINK_PATH%
    echo.
    echo Please check J-Link installation path in build.bat
    echo.
    echo Alternatively, use ST-Link Utility or OpenOCD:
    echo   ST-Link Utility: File ^> Open File ^> build\build\FreeRTOS_Project.hex
    echo   OpenOCD: openocd -f interface/stlink.cfg -f target/stm32f4x.cfg
)

goto END

:CLEAN
REM clean parameter: clean build
echo ================================================
echo Cleaning build directory...
echo ================================================
if exist build rmdir /s /q build
echo [OK] Clean completed!
goto END

:REBUILD
REM rebuild parameter: clean + build
echo ================================================
echo Rebuilding project...
echo ================================================
if "%BUILD_TYPE%"=="" set BUILD_TYPE=Release
if exist build rmdir /s /q build
cmake -B build -G "MinGW Makefiles" -DCMAKE_TOOLCHAIN_FILE=gcc.cmake -DCMAKE_BUILD_TYPE=%BUILD_TYPE%
cmake --build build -- -j8
goto END

:END
endlocal
