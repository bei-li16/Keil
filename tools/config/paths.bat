@echo off
REM ==========================================================================
 REM  paths.bat - the single configuration point of the tools kit (all scripts
 REM  call this file). To move to another machine/install location, edit only
 REM  this file; no script contains any hardcoded path.
 REM  Pure ASCII on purpose: no encoding can garble it.
 REM ==========================================================================

REM ------------------- part 1: user override (highest priority) -------------------
REM empty = fall through to the "bin directory probe" and "system auto detection" below
REM or hardcode it, e.g.: set "JLINK_DIR=D:\Software\SEGGER\JLink"
set "JLINK_DIR="       REM directory holding JLink.exe / JLinkGDBServerCL.exe / JLinkRTTLogger.exe
set "TOOLCHAIN_DIR="   REM directory holding arm-none-eabi-gdb.exe (CubeIDE bundled or standalone ARM toolchain)
set "OPENOCD_DIR=%~dp0..\xpack-openocd\bin"   REM xpack-openocd (full driver set incl. jlink)

REM ------------------- part 2: tools\bin portable directory (second priority) -------------------
REM drop portable executables into tools\bin\ and every script can use them, no install needed
if not defined JLINK_DIR if exist "%~dp0..\bin\JLink.exe" set "JLINK_DIR=%~dp0..\bin"
if not defined TOOLCHAIN_DIR if exist "%~dp0..\bin\arm-none-eabi-gdb.exe" set "TOOLCHAIN_DIR=%~dp0..\bin"
if not defined OPENOCD_DIR if exist "%~dp0..\bin\openocd.exe" set "OPENOCD_DIR=%~dp0..\bin"

REM ------------------- part 3: system auto detection (last fallback) -------------------
REM cmd's for /d cannot expand wildcards in middle path segments, so multi-level
REM globs must be expanded level by level with nested for; on multiple matches the last wins
if not defined JLINK_DIR (
    for /d %%D in ("C:\Program Files\SEGGER\JLink*") do set "JLINK_DIR=%%D"
)
REM  CubeIDE-bundled J-Link fallback (nested for, see the note above)
if not defined JLINK_DIR (
    for /d %%D in ("C:\ST\STM32CubeIDE_*") do for /d %%E in ("%%D\STM32CubeIDE\plugins\com.st.stm32cube.ide.mcu.externaltools.jlink.win32_*") do set "JLINK_DIR=%%E\tools\bin"
)
if not defined TOOLCHAIN_DIR (
    for /d %%D in ("C:\ST\STM32CubeIDE_*") do for /d %%E in ("%%D\STM32CubeIDE\plugins\com.st.stm32cube.ide.mcu.externaltools.gnu-tools-for-stm32.*") do set "TOOLCHAIN_DIR=%%E\tools\bin"
)
if not defined OPENOCD_DIR (
    for /d %%D in ("C:\Program Files\OpenOCD*") do set "OPENOCD_DIR=%%D\bin"
)

REM ------------------- part 4: target board / debug parameters -------------------
set "JLINK_DEVICE=STM32F429IG"  REM chip name (J-Link uses it to pick the flash algorithm)
set "JLINK_IF=SWD"              REM debug interface SWD / JTAG
set "JLINK_SPEED=4000"          REM interface clock kHz
set "PROBE_SPEED=1000"          REM low speed for probe-reset/run (verified stable on cloned J-Link V8)
REM  ports must avoid winnat reserved ranges (netsh interface ipv4 show excludedportrange protocol=tcp);
REM  on this machine 2311-2410 is reserved and binding 2333 fails (verified), hence 3333
set "GDB_PORT=3333"             REM J-Link GDB Server TCP port
set "OPENOCD_IF=jlink.cfg"      REM OpenOCD debugger config (this probe is a J-Link clone)
set "OPENOCD_PORT=3334"         REM OpenOCD GDB Server port (kept apart from J-Link's 3333)
set "UART_PORT=COM3"            REM debug serial port (default; uart_capture.py can override with --port)
set "UART_BAUD=115200"          REM serial baud rate, must match the target firmware config

REM ------------------- part 5: report (lets humans/scripts/AI see what is missing) -------------------
echo [paths] JLINK_DIR     = %JLINK_DIR%
echo [paths] TOOLCHAIN_DIR = %TOOLCHAIN_DIR%
echo [paths] OPENOCD_DIR   = %OPENOCD_DIR%
echo [paths] device=%JLINK_DEVICE% if=%JLINK_IF% speed=%JLINK_SPEED%kHz probe=%PROBE_SPEED%kHz gdb_port=%GDB_PORT% uart=%UART_PORT%@%UART_BAUD%
exit /b 0
