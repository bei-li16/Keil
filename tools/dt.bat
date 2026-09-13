@echo off
setlocal
REM ==========================================================================
 REM  dt.bat - STM32 控制台/AI 调试工具集 · 唯一入口(子命令分发)
 REM  所有配置在 config\paths.bat;固件/elf/变量名一律作参数传入
 REM
 REM  用法: dt <子命令> [参数...]      (不带参数显示本帮助)
 REM   check                      J-Link 链路自检
 REM   flash [--hold] <固件.hex|.bin>  烧录;--hold 烧完保持暂停
 REM   server                     起 J-Link GDB Server(常驻,后台运行)
 REM   rtt [输出文件]             抓 RTT 输出(常驻,缺省 rtt.log)
 REM   read <elf> <变量...>       一次性读变量值
 REM   watch <elf> <变量...>      硬件观察点盯变量(常驻,含调用栈)
 REM   gdb <elf> <命令...>        任意 gdb 命令(每参数一条,自动初始化/断开)
 REM   ocd-server                 起 OpenOCD GDB Server(常驻,端口 3333)
 REM   ocd-flash <固件> [地址]    OpenOCD 烧录(bin 必须给地址)
 REM   uart [参数...]             串口抓取(常驻,如: dt uart --list)
 REM   halt                       暂停运行中的目标(常驻暂停, dt run 恢复)
 REM   probe-reset                探针恢复(克隆 J-Link V8 退化时必跑)
 REM   run                        清残留断点/观察点后复位放行
 REM   server-stop                停止 J-Link/OpenOCD GDB Server
 REM ==========================================================================

REM ---- 载入配置(所有子命令共享;帮助信息也顺带显示当前配置状态) ----
call "%~dp0config\paths.bat"
if errorlevel 1 exit /b 1
 REM  交互式 Commander 脚本需要接口字母(S=SWD / J=JTAG)
set "IF_LETTER=J"
if /i "%JLINK_IF%"=="SWD" set "IF_LETTER=S"

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
if /i "%SUB%"=="gdb"        goto S_GDB
if /i "%SUB%"=="ocd-server" goto S_OCDSERVER
if /i "%SUB%"=="ocd-flash"  goto S_OCDFLASH
if /i "%SUB%"=="uart"       goto S_UART
if /i "%SUB%"=="halt"       goto S_HALT
if /i "%SUB%"=="probe-reset" goto S_PROBERESET
if /i "%SUB%"=="run"        goto S_RUN
if /i "%SUB%"=="server-stop" goto S_SERVERSTOP
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
>> "%CMDF%" echo r
 REM  --hold: 复位后保持暂停便于接着调试;默认复位即运行
if "%HOLD%"=="0" >> "%CMDF%" echo g
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
set "HOLD=0"
if /i "%~1"=="--hold" set "HOLD=1"
if /i "%~1"=="--hold" shift
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
if "%HOLD%"=="1" (echo [flash][OK] 已烧录, 目标保持暂停; dt run 恢复运行) else echo [flash][OK] 已烧录并复位运行
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

REM ==================== gdb:任意 gdb 命令 ====================
:S_GDB
call :NEED_GDB || exit /b 1
set "ELF=%~1"
if "%ELF%"=="" (
    echo [gdb][ERROR] 用法: dt gdb ^<工程.elf^> ^<gdb命令...^>
    echo [gdb]        每个参数是一条 gdb 命令,自动初始化连接并在结束断开放行目标
    echo [gdb]        例: dt gdb app.elf "info registers" "x/16xw 0x08000000"
    exit /b 1
)
if not exist "%ELF%" (
    echo [gdb][ERROR] elf 不存在: %ELF%
    exit /b 1
)
if "%~2"=="" (
    echo [gdb][ERROR] 至少给一条 gdb 命令
    exit /b 1
)
set "CMDF=%TEMP%\dt_gdb.gdb"
>  "%CMDF%" echo set confirm off
>> "%CMDF%" echo set pagination off
>> "%CMDF%" echo target extended-remote :%GDB_PORT%
:GB_LOOP
if "%~2"=="" goto GB_DONE
 REM  原样写入用户命令;注意 gdb 命令里避免 cmd 重定向字符 ^< ^> ^|
>> "%CMDF%" echo %~2
shift
goto GB_LOOP
:GB_DONE
 REM  断开放行目标,与 read/watch 保持一致的"用完即还"语义
>> "%CMDF%" echo detach
"%GDB%" "%ELF%" -batch -x "%CMDF%"
if errorlevel 1 (
    echo [gdb][ERROR] 执行失败:确认 server 已后台运行、命令与符号正确
    exit /b 1
)
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
echo [ocd-server] interface=%OPENOCD_IF% target=stm32f4x.cfg gdb_port=%OPENOCD_PORT%
echo [ocd-server] gdb 连接: target extended-remote :%OPENOCD_PORT%   本进程常驻,Ctrl+C 停止
"%OPENOCD_DIR%\openocd.exe" -f "interface/%OPENOCD_IF%" -f "target/stm32f4x.cfg" -c "adapter speed 4000" -c "gdb_port %OPENOCD_PORT%"
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
REM ==================== halt:暂停运行中的目标 ====================
:S_HALT
call :NEED_JLINK || exit /b 1
call :ASSERT_NO_GDBSERVER || exit /b 1
 REM  JLink.exe 独占探针执行 h 后退出,目标保持暂停;LED 停闪即确认
set "CMDF=%TEMP%\dt_halt.jlink"
>  "%CMDF%" echo connect
>> "%CMDF%" echo %JLINK_DEVICE%
>> "%CMDF%" echo %IF_LETTER%
>> "%CMDF%" echo %JLINK_SPEED%
>> "%CMDF%" echo h
>> "%CMDF%" echo qc
echo [halt] 暂停目标 ^(%JLINK_DEVICE%, %JLINK_SPEED%kHz^)...
"%JLINK_DIR%\JLink.exe" -if %JLINK_IF% -speed %JLINK_SPEED% -device %JLINK_DEVICE% -CommandFile "%CMDF%" -NoGui 1 > "%TEMP%\dt_halt.log" 2>&1
call :CHECK_JLINK_LOG "%TEMP%\dt_halt.log" halt || exit /b 1
echo [halt][OK] 目标已暂停;用 dt run 恢复自由运行,或先 dt server 再用 gdb 检查
exit /b 0

REM ==================== probe-reset:探针恢复(克隆 J-Link V8 必备) ====================
:S_PROBERESET
call :NEED_JLINK || exit /b 1
 REM  克隆 V8 每次会话后退化(变慢/Cannot access memory),独占探针低速重连+复位即恢复
call :STOP_GDBSERVER_QUIET
set "CMDF=%TEMP%\dt_probe_reset.jlink"
>  "%CMDF%" echo connect
>> "%CMDF%" echo %JLINK_DEVICE%
>> "%CMDF%" echo %IF_LETTER%
>> "%CMDF%" echo %PROBE_SPEED%
>> "%CMDF%" echo h
>> "%CMDF%" echo r
>> "%CMDF%" echo g
>> "%CMDF%" echo qc
echo [probe-reset] 低速重连并复位 ^(%PROBE_SPEED%kHz^)...
"%JLINK_DIR%\JLink.exe" -if %JLINK_IF% -speed %PROBE_SPEED% -device %JLINK_DEVICE% -CommandFile "%CMDF%" -NoGui 1 > "%TEMP%\dt_probe_reset.log" 2>&1
call :CHECK_JLINK_LOG "%TEMP%\dt_probe_reset.log" probe-reset || exit /b 1
echo [probe-reset][OK] 探针已恢复;server 若被本次操作停止,请重新 dt server
exit /b 0

REM ==================== run:清残留断点/观察点后放行 ====================
:S_RUN
call :NEED_JLINK || exit /b 1
call :STOP_GDBSERVER_QUIET
set "CMDF=%TEMP%\dt_run.jlink"
>  "%CMDF%" echo connect
>> "%CMDF%" echo %JLINK_DEVICE%
>> "%CMDF%" echo %IF_LETTER%
>> "%CMDF%" echo %PROBE_SPEED%
>> "%CMDF%" echo h
>> "%CMDF%" echo r
 REM  FPB/DWT 调试寄存器跨系统复位不清零,残留断点/观察点会让 CPU 一跑到就被冻住
>> "%CMDF%" echo w4 0xE0002000 0x3
>> "%CMDF%" echo w4 0xE0001020 0x0
>> "%CMDF%" echo w4 0xE0001030 0x0
>> "%CMDF%" echo w4 0xE0001040 0x0
>> "%CMDF%" echo w4 0xE0001050 0x0
>> "%CMDF%" echo g
>> "%CMDF%" echo qc
echo [run] 清残留断点/观察点并复位放行...
"%JLINK_DIR%\JLink.exe" -if %JLINK_IF% -speed %PROBE_SPEED% -device %JLINK_DEVICE% -CommandFile "%CMDF%" -NoGui 1 > "%TEMP%\dt_run.log" 2>&1
call :CHECK_JLINK_LOG "%TEMP%\dt_run.log" run || exit /b 1
echo [run][OK] 目标已自由运行(断点/观察点残留已清除)
exit /b 0

REM ==================== server-stop:停止 GDB Server ====================
:S_SERVERSTOP
call :STOP_GDBSERVER_QUIET
tasklist 2>nul | findstr /I "JLinkGDBServerCL.exe openocd.exe" >nul && (
    echo [server-stop][FAIL] 仍有调试服务器进程存活,请手动检查 tasklist
    exit /b 1
)
echo [server-stop][OK] J-Link/OpenOCD GDB Server 已停止,端口已释放
exit /b 0


:USAGE
echo 用法: dt ^<子命令^> [参数...]
echo   check                      J-Link 链路自检
echo   flash [--hold] ^<固件.hex^|.bin^>  烧录;--hold 烧完保持暂停
echo   server                     起 J-Link GDB Server ^(常驻,端口 %GDB_PORT%^)
echo   rtt [输出文件]             抓 RTT 输出 ^(常驻,缺省 rtt.log^)
echo   read ^<elf^> ^<变量...^>       一次性读变量值
echo   watch ^<elf^> ^<变量...^>      硬件观察点盯变量 ^(常驻,含调用栈^)
echo   gdb ^<elf^> ^<命令...^>        任意 gdb 命令 ^(自动初始化与断开^)
echo   ocd-server                 起 OpenOCD GDB Server ^(常驻,端口 3333^)
echo   ocd-flash ^<固件^> [地址]    OpenOCD 烧录 ^(bin 必须给地址^)
echo   uart [参数...]             串口抓取 ^(如: dt uart --list^)
echo   halt                       暂停运行中的目标 ^(常驻, dt run 恢复^)
echo   probe-reset                探针恢复 ^(克隆 J-Link V8 退化时必跑^)
echo   run                        清残留断点/观察点后复位放行
echo   server-stop                停止 J-Link/OpenOCD GDB Server 并释放端口
echo.
echo 示例: dt flash build\app.hex
echo       dt watch build\app.elf g_counter g_fsm_state
echo       dt read  build\app.elf g_counter
echo       dt gdb   build\app.elf "info registers" "x/16xw 0x08000000"
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


REM ==================== 子程序:探针/服务器辅助 ====================
:ASSERT_NO_GDBSERVER
tasklist 2>nul | findstr /I "JLinkGDBServerCL.exe" >nul && (
    echo [dt][ERROR] GDB Server 正在占用探针,先执行: dt server-stop
    exit /b 1
)
exit /b 0

:STOP_GDBSERVER_QUIET
taskkill /IM JLinkGDBServerCL.exe /F >nul 2>&1
taskkill /IM openocd.exe /F >nul 2>&1
 REM  等 1 秒让探针句柄释放
ping -n 2 127.0.0.1 >nul
exit /b 0

:CHECK_JLINK_LOG
 REM  %1=日志文件 %2=子命令名;JLink.exe 交互退出码不可靠,以输出 O.K/identified 判定
findstr /C:"O.K" "%~1" >nul && exit /b 0
findstr /C:"identified" "%~1" >nul && exit /b 0
echo [%~2][FAIL] 未检测到连接成功标记(O.K/identified),完整日志:
type "%~1"
exit /b 1
