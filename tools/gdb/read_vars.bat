@echo off
setlocal
REM ==========================================================================
 REM  read_vars.bat - 一次性读取固件变量值(需 gdb_server.bat 已后台运行)
 REM  用法: read_vars.bat <工程.elf> <变量名1> [变量名2] ...
 REM  例 : read_vars.bat build\FreeRTOS.elf g_counter g_fsm_state
 REM  原理:动态生成 gdb 命令脚本,p 命令按符号打印,读完 detach 放行目标
 REM ==========================================================================
call "%~dp0..\config\paths.bat"
if errorlevel 1 exit /b 1

REM ---------- 参数检查:%1=elf,变量从 %2 起 ----------
set "ELF=%~1"
if "%ELF%"=="" (
    echo [readvars][ERROR] 用法: read_vars.bat ^<工程.elf^> ^<变量名...^>
    exit /b 1
)
if not exist "%ELF%" (
    echo [readvars][ERROR] elf 不存在: %ELF%
    exit /b 1
)
if "%~2"=="" (
    echo [readvars][ERROR] 至少给一个变量名
    exit /b 1
)
if not defined TOOLCHAIN_DIR (
    echo [readvars][ERROR] 未找到 arm-none-eabi-gdb,请装工具链或配置 config\paths.bat
    exit /b 1
)
set "GDB=%TOOLCHAIN_DIR%\arm-none-eabi-gdb.exe"
if not exist "%GDB%" (
    echo [readvars][ERROR] %GDB% 不存在
    exit /b 1
)

REM ---------- 生成 gdb 脚本 ----------
set "CMDF=%TEMP%\tools_read_vars.gdb"
 REM  关确认/分页,防批量模式卡死
>  "%CMDF%" echo set confirm off
>> "%CMDF%" echo set pagination off
 REM  端口来自 config\paths.bat 的 GDB_PORT,与 gdb_server.bat 保持一致
>> "%CMDF%" echo target extended-remote :%GDB_PORT%

REM ---------- 循环处理每个变量名 ----------
 REM  shift 把参数左移:先记下 ELF 后,循环消费 %2..%N
:ARGLOOP
if "%~2"=="" goto ARGDONE
 REM  p <变量>:按 DWARF 调试信息解析符号并打印(含类型)
>> "%CMDF%" echo p %~2
shift
goto ARGLOOP
:ARGDONE
 REM  detach:断开并让目标恢复运行;gdb -batch 到此自动退出
>> "%CMDF%" echo detach

REM ---------- 执行 ----------
"%GDB%" "%ELF%" -batch -x "%CMDF%"
if errorlevel 1 (
    echo [readvars][ERROR] 读取失败:确认 gdb_server.bat 已运行、符号名存在于该 elf
    exit /b 1
)
endlocal
exit /b 0
