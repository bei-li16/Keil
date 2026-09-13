@echo off
setlocal
REM ==========================================================================
 REM  watch_vars.bat - 硬件观察点持续监视变量变化(需 gdb_server.bat 已后台运行)
 REM  用法: watch_vars.bat <工程.elf> <变量名1> [变量名2] ...
 REM  例 : watch_vars.bat build\FreeRTOS.elf g_counter g_fsm_state
 REM  输出:每次被写入时打印 ">>> [watch] 变量 = 新值" + 3 层调用栈
 REM        调用栈直接指明"是哪条代码路径改的它"——变量变化时机的答案
 REM  原理:CPU 硬件观察点(DWT 比较器),任何路径(含 ISR)写入都会命中
 REM  注意:本进程一直运行直到 Ctrl+C / 结束进程;建议 AI 以后台任务方式启动
 REM        固件必须为 Debug 构建(-Og -g),否则变量可能被优化掉
 REM ==========================================================================
call "%~dp0..\config\paths.bat"
if errorlevel 1 exit /b 1

REM ---------- 参数与工具检查(与 read_vars.bat 相同的套路) ----------
set "ELF=%~1"
if "%ELF%"=="" (
    echo [watchvars][ERROR] 用法: watch_vars.bat ^<工程.elf^> ^<变量名...^>
    exit /b 1
)
if not exist "%ELF%" (
    echo [watchvars][ERROR] elf 不存在: %ELF%
    exit /b 1
)
if "%~2"=="" (
    echo [watchvars][ERROR] 至少给一个变量名
    exit /b 1
)
if not defined TOOLCHAIN_DIR (
    echo [watchvars][ERROR] 未找到 arm-none-eabi-gdb,请装工具链或配置 config\paths.bat
    exit /b 1
)
set "GDB=%TOOLCHAIN_DIR%\arm-none-eabi-gdb.exe"
if not exist "%GDB%" (
    echo [watchvars][ERROR] %GDB% 不存在
    exit /b 1
)

REM ---------- 生成 gdb 观察脚本 ----------
set "CMDF=%TEMP%\tools_watch_vars.gdb"
>  "%CMDF%" echo set confirm off
>> "%CMDF%" echo set pagination off
>> "%CMDF%" echo target extended-remote :%GDB_PORT%

REM ---------- 对每个变量生成 watch + 命中动作 ----------
:ARGLOOP
if "%~2"=="" goto ARGDONE
 REM  watch:对变量地址下硬件写观察点
>> "%CMDF%" echo watch %~2
>> "%CMDF%" echo commands
 REM  silent:不回显 gdb 默认的命中信息,输出干净
>> "%CMDF%" echo   silent
 REM  printf 只打标签;真正的值用 output 打印 —— 它按变量自身类型输出,
 REM  因此本脚本对整型/浮点/枚举变量都通用,无需为类型定制格式符
>> "%CMDF%" echo   printf ">>> [watch] %~2 = "
>> "%CMDF%" echo   output %~2
>> "%CMDF%" echo   printf "\n"
 REM  bt 3:3 层调用栈,定位是哪条代码路径写入
>> "%CMDF%" echo   bt 3
 REM  打完立刻恢复运行,继续抓下一次修改
>> "%CMDF%" echo   continue
>> "%CMDF%" echo end
shift
goto ARGLOOP
:ARGDONE
 REM  进入观察循环:持续运行,直到人工中止
>> "%CMDF%" echo continue

REM ---------- 执行 ----------
"%GDB%" "%ELF%" -batch -x "%CMDF%"
endlocal
exit /b 0
