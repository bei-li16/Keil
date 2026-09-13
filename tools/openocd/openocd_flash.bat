@echo off
setlocal
REM ==========================================================================
 REM  openocd_flash.bat - 用 OpenOCD 烧录固件(J-Link 之外的免费替代)
 REM  用法: openocd_flash.bat <固件文件.hex 或 .bin> [烧写地址]
 REM        hex 自带地址;bin 必须给地址,缺省 0x08000000
 REM  原理:openocd 的 program 命令一条龙完成 烧写+校验+复位+退出
 REM ==========================================================================
call "%~dp0..\config\paths.bat"
if errorlevel 1 exit /b 1

set "IMG=%~1"
if "%IMG%"=="" (
    echo [openocd][ERROR] 用法: openocd_flash.bat ^<固件文件^> [地址]
    exit /b 1
)
if not exist "%IMG%" (
    echo [openocd][ERROR] 文件不存在: %IMG%
    exit /b 1
)
if not defined OPENOCD_DIR (
    echo [openocd][ERROR] 未找到 OpenOCD,请安装 xpack-openocd 或配置 config\paths.bat
    exit /b 1
)

REM BIN 文件没有内嵌地址:第二个参数给地址,缺省 flash 起始 0x08000000
set "ADDR=%~2"
if "%ADDR%"=="" set "ADDR=0x08000000"

echo [openocd] 烧录 %IMG% ...
 REM  program <file> [addr] verify reset exit:烧写 -> 校验 -> 复位运行 -> 退出
 REM  HEX 忽略 addr;BIN 用 ADDR;文件路径带空格时靠内层引号保护
"%OPENOCD_DIR%\openocd.exe" -f "interface/%OPENOCD_IF%" -f "target/stm32f4x.cfg" -c "adapter speed 4000" -c "program \"%IMG%\" %ADDR% verify reset exit"
if errorlevel 1 (
    echo [openocd][ERROR] 烧录失败:检查调试器连接 / OPENOCD_IF 配置是否匹配调试器
    exit /b 1
)
echo [openocd][OK] 已烧录并复位运行
endlocal
exit /b 0
