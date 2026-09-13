@echo off
setlocal
REM ==========================================================================
 REM  openocd_server.bat - 启动 OpenOCD GDB Server(J-Link 之外的免费替代)
 REM  前提:安装 OpenOCD(xpack-openocd 或发行版),config\paths.bat 能探测到
 REM  gdb 连接端口为 OpenOCD 默认 3333(与 J-Link 的 2333 互不影响)
 REM ==========================================================================
call "%~dp0..\config\paths.bat"
if errorlevel 1 exit /b 1

if not defined OPENOCD_DIR (
    echo [openocd][ERROR] 未找到 OpenOCD,请安装 xpack-openocd 或配置 config\paths.bat
    exit /b 1
)
if not exist "%OPENOCD_DIR%\openocd.exe" (
    echo [openocd][ERROR] %OPENOCD_DIR%\openocd.exe 不存在
    exit /b 1
)

echo [openocd] interface=%OPENOCD_IF% target=stm32f4x.cfg gdb_port=3333
echo [openocd] gdb 连接方式: target extended-remote :3333
 REM  -f interface/<cfg>:调试器(stlink/cmsis-dap/jlink 等,config 里配置)
 REM  -f target/stm32f4x.cfg:目标芯片系列
 REM  -c "adapter speed 4000":SWD 时钟 kHz
"%OPENOCD_DIR%\openocd.exe" -f "interface/%OPENOCD_IF%" -f "target/stm32f4x.cfg" -c "adapter speed 4000"
