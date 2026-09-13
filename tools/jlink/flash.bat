@echo off
setlocal
REM ==========================================================================
 REM  flash.bat - 用 J-Link 烧录固件(不绑定任何工程,文件路径作参数传入)
 REM  用法: flash.bat <固件文件.hex 或 .bin>
 REM  原理:动态生成 J-Link Commander 命令文件(%TEMP% 下),交 JLink.exe 执行
 REM ==========================================================================
call "%~dp0..\config\paths.bat"
if errorlevel 1 exit /b 1

REM ---------- 参数与前置检查 ----------
REM %~1 = 第 1 个参数(去引号);本工具无默认文件,必须显式传入
set "IMG=%~1"
if "%IMG%"=="" (
    echo [flash][ERROR] 用法: flash.bat ^<固件文件.hex 或 .bin^>
    exit /b 1
)
if not exist "%IMG%" (
    echo [flash][ERROR] 文件不存在: %IMG%
    exit /b 1
)
if not defined JLINK_DIR (
    echo [flash][ERROR] 未找到 J-Link 软件包,请安装或配置 config\paths.bat
    exit /b 1
)
if not exist "%JLINK_DIR%\JLink.exe" (
    echo [flash][ERROR] %JLINK_DIR%\JLink.exe 不存在
    exit /b 1
)

REM ---------- 生成烧录命令序列 ----------
 REM  > 首行覆盖写,>> 后续追加;这些行严禁行尾 REM,否则注释会被写进命令文件
set "CMDF=%TEMP%\tools_flash.jlink"
 REM  device:芯片型号,J-Link 据此加载对应 flash 下载算法
>  "%CMDF%" echo device %JLINK_DEVICE%
 REM  si:选择调试接口 SWD/JTAG
>> "%CMDF%" echo si %JLINK_IF%
 REM  speed:接口时钟 kHz
>> "%CMDF%" echo speed %JLINK_SPEED%
 REM  connect:建立与目标的连接
>> "%CMDF%" echo connect
 REM  h:halt,CPU 停机后才能写 flash
>> "%CMDF%" echo h
 REM  loadfile:按扩展名自动识别 HEX/BIN;HEX 内部自带烧写地址,BIN 从 0x08000000 起
>> "%CMDF%" echo loadfile "%IMG%"
 REM  r:复位;g:开始运行;q:退出
>> "%CMDF%" echo r
>> "%CMDF%" echo g
>> "%CMDF%" echo q

REM ---------- 执行 ----------
echo [flash] 烧录 %IMG% ^(%JLINK_DEVICE%, %JLINK_IF%, %JLINK_SPEED%kHz^) ...
 REM  -AutoConnect 1:自动连 J-Link 硬件;-ExitOnError 1:失败即退非零;-NoGui 1:纯命令行
"%JLINK_DIR%\JLink.exe" -CommandFile "%CMDF%" -AutoConnect 1 -ExitOnError 1 -NoGui 1
if errorlevel 1 (
    echo [flash][ERROR] 烧录失败:检查 J-Link USB / 目标板供电 / 接口模式与接线
    exit /b 1
)
echo [flash][OK] 已烧录并复位运行
endlocal
exit /b 0
