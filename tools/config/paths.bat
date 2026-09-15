@echo off
REM Debug dependencies always belong to this tools copy. No external fallback.
for %%D in ("%~dp0..") do (
    set "JLINK_DIR=%%~fD\bin\jlink"
    set "GDB_DIR=%%~fD\bin\gdb\bin"
    set "OPENOCD_DIR=%%~fD\xpack-openocd\bin"
    set "OPENOCD_SCRIPTS=%%~fD\xpack-openocd\openocd\scripts"
)
if not defined JLINK_DEVICE set "JLINK_DEVICE=STM32F429IG"
if not defined JLINK_IF set "JLINK_IF=SWD"
if not defined JLINK_SPEED set "JLINK_SPEED=4000"
if not defined PROBE_SPEED set "PROBE_SPEED=1000"
if not defined GDB_PORT set "GDB_PORT=3333"
if not defined DEBUG_BACKEND set "DEBUG_BACKEND=jlink"
if not defined OPENOCD_IF set "OPENOCD_IF=jlink.cfg"
if not defined OPENOCD_TRANSPORT set "OPENOCD_TRANSPORT=swd"
if not defined OPENOCD_TARGET set "OPENOCD_TARGET=target/stm32f4x.cfg"
if not defined OPENOCD_SPEED set "OPENOCD_SPEED=4000"
if not defined OPENOCD_PORT set "OPENOCD_PORT=3334"
if not defined UART_PORT set "UART_PORT=COM3"
if not defined UART_BAUD set "UART_BAUD=115200"
echo [paths] device=%JLINK_DEVICE% if=%JLINK_IF% speed=%JLINK_SPEED%kHz gdb=%GDB_PORT% ocd=%OPENOCD_PORT% uart=%UART_PORT%@%UART_BAUD%
exit /b 0
