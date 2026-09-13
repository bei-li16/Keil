@echo off
setlocal
REM ==========================================================================
 REM  dt.bat - STM32 控制台/AI 调试工具集 · 唯一入口(子命令分发)
 REM  所有配置在 config\paths.bat;固件/elf/变量名一律作参数传入
 REM
 REM  用法: dt <子命令> [参数...]      (不带参数显示本帮助)
 REM   check                      J-Link 链路自检
 REM   flash <固件.hex|.bin>      J-Link 烧录并复位运行
 REM   server                     起 J-Link GDB Server(常驻,后台运行)
 REM   rtt [输出文件]             抓 RTT 输出(常驻,缺省 rtt.log)
 REM   read <elf> <变量...>       一次性读变量值
 REM   watch <elf> <变量...>      硬件观察点盯变量(常驻,含调用栈)
 REM   ocd-server                 起 OpenOCD GDB Server(常驻,端口 3333)
 REM   ocd-flash <固件> [地址]    OpenOCD 烧录(bin 必须给地址)
 REM   uart [参数...]             串口抓取(常驻,如: dt uart --list)
 REM ==========================================================================

REM ---- 载入配置(所有子命令共享;帮助信息也顺带显示当前配置状态) ----
call "%~dp0config\paths.bat"
if errorlevel 1 exit /b 1

set "SUB=%~1"
if "%SUB%"=="" goto USAGE
 REM  shift 后 %1..%9 变为子命令之后的参数(%* 不受 shift 影响,见 uart 分支)
shift

if /i "%SUB%"=="check"      goto S_CHECK
if /i "%SUB%"=="flash"      goto S_FLASH
if /i "%SUB%"=="server"     goto S_SERVER
if /i "%SUB%"=="rtt"        goto S_RTT
if /i "%SUB%"=="read"       goto S_READ
if /i "%SUB%"=="watch"      goto S_WATCH
if /i "%SUB%"=="ocd-server" goto S_OCDSERVER
if /i "%SUB%"=="ocd-flash"  goto S_OCDFLASH
if /i "%SUB%"=="uart"       goto S_UART
goto USAGE

REM ==================== check:J-Link 链路自检 ====================
:S_CHECK
call :NEED_JLINK || exit /b 1
 REM  动态生成 Commander 命令:> 首行覆盖,>> 追加;这些行严禁行尾 REM
set "CMDF=%TEMP%\dt_check.jlink"
>  "%CMDF%" echo device %JLINK_DEVICE%
>> "%CMDF%" echo si %JLINK_IF%
>> "%CMDF%" echo speed %JLINK_SPEED%
>> "%CMDF%" echo connect
>> "%CMDF%" echo h
>> "%CMDF%" echo regs
>> "%CMDF%" echo q
echo [check] 连接测试: %JLINK_DEVICE% / %JLINK_IF% / %JLINK_SPEED%kHz
"%JLINK_DIR%\JLink.exe" -CommandFile "%CMDF%" -AutoConnect 1 -ExitOnError 1 -NoGui 1
if errorlevel 1 (
    echo [check][FAIL] 连接失败:查 USB 灯 / 供电 / 接口模式与接线 ^(SWD 需 SWDIO+SWCLK+GND^) / 是否被占用
    exit /b 1
)
echo [check][OK] J-Link 链路正常
exit /b 0

REM ==================== flash:J-Link 烧录 ====================
:S_FLASH
call :NEED_JLINK || exit /b 1
set "IMG=%~1"
if "%IMG%"=="" (
    echo [flash][ERROR] 用法: dt flash ^<固件.hex 或 .bin^>
    exit /b 1
)
if not exist "%IMG%" (
    echo [flash][ERROR] 文件不存在: %IMG%
    exit /b 1
)
set "CMDF=%TEMP%\dt_flash.jlink"
 REM  h:先停核再写;loadfile:按扩展名自动识别 HEX/BIN;r:复位;g:运行
>  "%CMDF%" echo device %JLINK_DEVICE%
>> "%CMDF%" echo si %JLINK_IF%
>> "%CMDF%" echo speed %JLINK_SPEED%
>> "%CMDF%" echo connect
>> "%CMDF%" echo h
>> "%CMDF%" echo loadfile "%IMG%"
>> "%CMDF%" echo r
>> "%CMDF%" echo g
>> "%CMDF%" echo q
echo [flash] 烧录 %IMG% ^(%JLINK_DEVICE%, %JLINK_IF%, %JLINK_SPEED%kHz^) ...
"%JLINK_DIR%\JLink.exe" -CommandFile "%CMDF%" -AutoConnect 1 -ExitOnError 1 -NoGui 1
if errorlevel 1 (
    echo [flash][ERROR] 烧录失败:检查 J-Link USB / 目标板供电 / 接口模式与接线
    exit /b 1
)
echo [flash][OK] 已烧录并复位运行
exit /b 0

REM ==================== server:J-Link GDB Server ====================
:S_SERVER
call :NEED_JLINK || exit /b 1
if not exist "%JLINK_DIR%\JLinkGDBServerCL.exe" (
    echo [server][ERROR] %JLINK_DIR%\JLinkGDBServerCL.exe 不存在
    echo [server]        官方完整包才含 GDB Server;只有 CubeIDE 精简插件时请补装
    exit /b 1
)
echo [server] device=%JLINK_DEVICE% if=%JLINK_IF% speed=%JLINK_SPEED% port=%GDB_PORT%
echo [server] gdb 连接: target extended-remote :%GDB_PORT%   本进程常驻,Ctrl+C 停止
"%JLINK_DIR%\JLinkGDBServerCL.exe" -device %JLINK_DEVICE% -if %JLINK_IF% -speed %JLINK_SPEED% -port %GDB_PORT% -nogui -select USB
exit /b 0

REM ==================== rtt:RTT 抓取 ====================
:S_RTT
call :NEED_JLINK || exit /b 1
if not exist "%JLINK_DIR%\JLinkRTTLogger.exe" (
    echo [rtt][ERROR] %JLINK_DIR%\JLinkRTTLogger.exe 不存在
    exit /b 1
)
set "OUT=%~1"
if "%OUT%"=="" set "OUT=rtt.log"
echo [rtt] logging to %OUT% ^(Ctrl+C 停止^)
 REM  -RTTChannel 0:读上行通道 0;Logger 自动在 RAM 搜 "SEGGER RTT" 控制块
"%JLINK_DIR%\JLinkRTTLogger.exe" -Device %JLINK_DEVICE% -If %JLINK_IF% -Speed %JLINK_SPEED% -RTTChannel 0 "%OUT%"
exit /b 0

REM ==================== read:一次性读变量 ====================
:S_READ
call :NEED_GDB || exit /b 1
set "ELF=%~1"
if "%ELF%"=="" (
    echo [read][ERROR] 用法: dt read ^<工程.elf^> ^<变量名...^>
    exit /b 1
)
if not exist "%ELF%" (
    echo [read][ERROR] elf 不存在: %ELF%
    exit /b 1
)
if "%~2"=="" (
    echo [read][ERROR] 至少给一个变量名
    exit /b 1
)
set "CMDF=%TEMP%\dt_read.gdb"
>  "%CMDF%" echo set confirm off
>> "%CMDF%" echo set pagination off
>> "%CMDF%" echo target extended-remote :%GDB_PORT%
:RD_LOOP
if "%~2"=="" goto RD_DONE
 REM  p <变量>:按 DWARF 调试信息解析符号并打印(含类型)
>> "%CMDF%" echo p %~2
shift
goto RD_LOOP
:RD_DONE
 REM  detach:断开并放行目标;-batch 到此自动退出
>> "%CMDF%" echo detach
"%GDB%" "%ELF%" -batch -x "%CMDF%"
if errorlevel 1 (
    echo [read][ERROR] 读取失败:确认 server 已后台运行、变量存在于该 elf
    exit /b 1
)
exit /b 0

REM ==================== watch:硬件观察点盯变量 ====================
:S_WATCH
call :NEED_GDB || exit /b 1
set "ELF=%~1"
if "%ELF%"=="" (
    echo [watch][ERROR] 用法: dt watch ^<工程.elf^> ^<变量名...^>
    exit /b 1
)
if not exist "%ELF%" (
    echo [watch][ERROR] elf 不存在: %ELF%
    exit /b 1
)
if "%~2"=="" (
    echo [watch][ERROR] 至少给一个变量名
    exit /b 1
)
set "CMDF=%TEMP%\dt_watch.gdb"
>  "%CMDF%" echo set confirm off
>> "%CMDF%" echo set pagination off
>> "%CMDF%" echo target extended-remote :%GDB_PORT%
:WT_LOOP
if "%~2"=="" goto WT_DONE
 REM  watch:CPU 硬件观察点,任何路径(含 ISR)写入即命中
>> "%CMDF%" echo watch %~2
>> "%CMDF%" echo commands
>> "%CMDF%" echo   silent
 REM  printf 只打标签;值用 output 打印 —— 按变量自身类型输出,整型/浮点/枚举通用
>> "%CMDF%" echo   printf ">>> [watch] %~2 = "
>> "%CMDF%" echo   output %~2
>> "%CMDF%" echo   printf "\n"
 REM  bt 3:3 层调用栈,定位是哪条代码路径写入
>> "%CMDF%" echo   bt 3
>> "%CMDF%" echo   continue
>> "%CMDF%" echo end
shift
goto WT_LOOP
:WT_DONE
 REM  进入观察循环直到人工中止;建议后台任务运行后读其输出
>> "%CMDF%" echo continue
"%GDB%" "%ELF%" -batch -x "%CMDF%"
exit /b 0

REM ==================== ocd-server:OpenOCD GDB Server ====================
:S_OCDSERVER
if not defined OPENOCD_DIR (
    echo [ocd][ERROR] 未找到 OpenOCD:装 xpack-openocd / 放 bin\ / 改 config\paths.bat
    exit /b 1
)
if not exist "%OPENOCD_DIR%\openocd.exe" (
    echo [ocd][ERROR] %OPENOCD_DIR%\openocd.exe 不存在
    exit /b 1
)
echo [ocd-server] interface=%OPENOCD_IF% target=stm32f4x.cfg gdb_port=3333
echo [ocd-server] gdb 连接: target extended-remote :3333   本进程常驻,Ctrl+C 停止
"%OPENOCD_DIR%\openocd.exe" -f "interface/%OPENOCD_IF%" -f "target/stm32f4x.cfg" -c "adapter speed 4000"
exit /b 0

REM ==================== ocd-flash:OpenOCD 烧录 ====================
:S_OCDFLASH
if not defined OPENOCD_DIR (
    echo [ocd][ERROR] 未找到 OpenOCD:装 xpack-openocd / 放 bin\ / 改 config\paths.bat
    exit /b 1
)
if not exist "%OPENOCD_DIR%\openocd.exe" (
    echo [ocd][ERROR] %OPENOCD_DIR%\openocd.exe 不存在
    exit /b 1
)
set "IMG=%~1"
if "%IMG%"=="" (
    echo [ocd-flash][ERROR] 用法: dt ocd-flash ^<固件^> [地址]
    exit /b 1
)
if not exist "%IMG%" (
    echo [ocd-flash][ERROR] 文件不存在: %IMG%
    exit /b 1
)
 REM  BIN 无内嵌地址:第二参数给地址,缺省 flash 起始
set "ADDR=%~2"
if "%ADDR%"=="" set "ADDR=0x08000000"
echo [ocd-flash] 烧录 %IMG% @%ADDR% ...
 REM  program 一条龙:烧写 -> 校验 -> 复位运行 -> 退出
"%OPENOCD_DIR%\openocd.exe" -f "interface/%OPENOCD_IF%" -f "target/stm32f4x.cfg" -c "adapter speed 4000" -c "program \"%IMG%\" %ADDR% verify reset exit"
if errorlevel 1 (
    echo [ocd-flash][ERROR] 烧录失败:检查调试器连接 / OPENOCD_IF 是否匹配调试器
    exit /b 1
)
echo [ocd-flash][OK] 已烧录并复位运行
exit /b 0

REM ==================== uart:串口抓取 ====================
:S_UART
 REM  %* 不受 shift 影响,仍含子命令本身;截掉第一个 token 即剩余参数
for /f "tokens=1,* delims= " %%a in ("%*") do set "UART_ARGS=%%b"
python "%~dp0uart_capture.py" %UART_ARGS%
exit /b %errorlevel%

REM ==================== 帮助 ====================
:USAGE
echo 用法: dt ^<子命令^> [参数...]
echo   check                      J-Link 链路自检
echo   flash ^<固件.hex^|.bin^>      J-Link 烧录并复位运行
echo   server                     起 J-Link GDB Server ^(常驻,端口 %GDB_PORT%^)
echo   rtt [输出文件]             抓 RTT 输出 ^(常驻,缺省 rtt.log^)
echo   read ^<elf^> ^<变量...^>       一次性读变量值
echo   watch ^<elf^> ^<变量...^>      硬件观察点盯变量 ^(常驻,含调用栈^)
echo   ocd-server                 起 OpenOCD GDB Server ^(常驻,端口 3333^)
echo   ocd-flash ^<固件^> [地址]    OpenOCD 烧录 ^(bin 必须给地址^)
echo   uart [参数...]             串口抓取 ^(如: dt uart --list^)
echo.
echo 示例: dt flash build\app.hex
echo       dt watch build\app.elf g_counter g_fsm_state
echo       dt read  build\app.elf g_counter
echo 配置文件: %~dp0config\paths.bat
exit /b 1

REM ==================== 子程序:依赖检查 ====================
:NEED_JLINK
if not defined JLINK_DIR (
    echo [dt][ERROR] 未找到 J-Link 软件包:装 SEGGER 官方包 / 便携版放 bin\ / 改 config\paths.bat
    exit /b 1
)
if not exist "%JLINK_DIR%\JLink.exe" (
    echo [dt][ERROR] %JLINK_DIR%\JLink.exe 不存在
    exit /b 1
)
exit /b 0

:NEED_GDB
if not defined TOOLCHAIN_DIR (
    echo [dt][ERROR] 未找到 arm-none-eabi-gdb:装 ARM 工具链 / 便携版放 bin\ / 改 config\paths.bat
    exit /b 1
)
if not exist "%TOOLCHAIN_DIR%\arm-none-eabi-gdb.exe" (
    echo [dt][ERROR] %TOOLCHAIN_DIR%\arm-none-eabi-gdb.exe 不存在
    exit /b 1
)
set "GDB=%TOOLCHAIN_DIR%\arm-none-eabi-gdb.exe"
exit /b 0
