@echo off
setlocal enabledelayedexpansion

REM ==============================================================================
REM ################  设置工具链路径（根据实际安装路径修改）         ################
REM ==============================================================================
@REM set cmake path
set "CMAKE_DIR=C:\Program Files\CMake\bin"
@REM set make path
set "MAKE_DIR=C:\ST\STM32CubeIDE_1.17.0\STM32CubeIDE\plugins\com.st.stm32cube.ide.mcu.externaltools.make.win32_2.2.0.202409170845\tools\bin"
@REM set compiler path
set "COMPILER_DIR=C:\ST\STM32CubeIDE_1.17.0\STM32CubeIDE\plugins\com.st.stm32cube.ide.mcu.externaltools.gnu-tools-for-stm32.12.3.rel1.win32_1.1.0.202410251130\tools\bin"
@REM set python path
set "PYTHON_DIR=C:\Users\18283\AppData\Local\Programs\Python\Python312"
@REM set PATH
set PATH=%COMPILER_DIR%;%MAKE_DIR%;%CMAKE_DIR%;%PYTHON_DIR%;%PATH%


REM ==============================================================================
REM ################  获取&定义环境变量                            ################
REM ==============================================================================
@REM 定义工具链路径
set "BUILD_TOOL_DIR=%~dp0"
@REM 定义工程根目录
set "PROJECT_ROOT=%~dp0..\"
@REM 定义构建目录
set "BUILD_DIR=%PROJECT_ROOT%build"
@REM 定义构建类型
set "BUILD_TYPE=Release"
@REM 定义构建类型
set "OUTPUT_MAKELIST=%PROJECT_ROOT%CMakeLists.txt"
@REM 定义工具链文件
set "TOOLCHAIN_FILE=%BUILD_TOOL_DIR%arm-gcc-toolchain.cmake"
@REM 定义工程名称
set "PROJECT_NAME=BootLoader"
@REM 定义工程版本
set "PROJECT_VERSION=2.0.0"

REM ==============================================================================
REM ################  根据cmake模板自动生成CMakelists.txt          ################
REM ==============================================================================
@REM 定义cmake模板路径
set GEN_CMAKE_TEMPLATE=%BUILD_TOOL_DIR%CMakeLists.template
@REM 清理旧构建
if exist "%BUILD_DIR%" rmdir /s /q "%BUILD_DIR%"
@REM python脚本自动生成CMakeLists.txt
call %PYTHON_DIR%\python.exe %BUILD_TOOL_DIR%gen_cmake.py %PROJECT_ROOT% %GEN_CMAKE_TEMPLATE% %OUTPUT_MAKELIST%


REM ==============================================================================
REM ################  调用cmake生成构建                            ################
REM ==============================================================================
@REM 创建构建目录
mkdir "%BUILD_DIR%"
@REM 生成适用于 Windows 的 Makefile：
@REM -G "MinGW Makefiles" 指定生成器类型（需安装 MinGW）
cmake   -S %PROJECT_ROOT% -B %BUILD_DIR% -G "MinGW Makefiles" ^
        -DCMAKE_BUILD_TYPE=%BUILD_TYPE% ^
        -DCMAKE_TOOLCHAIN_FILE=%TOOLCHAIN_FILE% ^
        --fresh ^
        -DPROJECT_NAME=%PROJECT_NAME% ^
        -DPROJECT_VERSION=%PROJECT_VERSION% 


REM ==============================================================================
REM ################  调用cmake --build执行编译动作                ################
REM ==============================================================================
@REM 调用cmake指令执行编译动作，编译日志输出到build.log
pushd "%BUILD_DIR%"
echo =========== Build project start! ===========
@REM cmake --build . --config %BUILD_TYPE% --target all -- -j12  > build.log 2>&1
cmake --build . --config %BUILD_TYPE% --target all -- -j12 2>&1 | ^
powershell -Command "$input | ForEach-Object { \"$(Get-Date -Format '[yyyy-MM-dd HH:mm:ss]') $_\" }" ^
> build.log
if errorlevel 1 (
  echo =========== ERROR: Build project failed! ===========
  exit /b 1
) else (
  del /f %OUTPUT_MAKELIST%
  echo =========== SUCCESS: Build project successfully!  ===========
)
popd


REM ==============================================================================
REM ################  调用cmake --build执行编译动作                ################
REM ==============================================================================
@REM download hex file to board
@REM call download.bat

endlocal
echo CMake auto build finished!
exit /b 0
```