@echo off
setlocal enabledelayedexpansion

set "BUILD_DIR=build"
set "GENERATOR=MinGW Makefiles"
set "BUILD_TYPE=Release"
cd ..

REM 设置工具链路径（根据实际安装路径修改）
@REM set "MAKE_DIR=C:\MinGW\bin"
set "CMAKE_DIR=C:\Program Files\CMake\bin"
set "MAKE_DIR=C:\ST\STM32CubeIDE_1.17.0\STM32CubeIDE\plugins\com.st.stm32cube.ide.mcu.externaltools.make.win32_2.2.0.202409170845\tools\bin"
set "COMPILER_DIR=C:\ST\STM32CubeIDE_1.17.0\STM32CubeIDE\plugins\com.st.stm32cube.ide.mcu.externaltools.gnu-tools-for-stm32.12.3.rel1.win32_1.1.0.202410251130\tools\bin"
set PATH=%COMPILER_DIR%;%MAKE_DIR%;%CMAKE_DIR%;%PATH%

REM 清理旧构建
if exist "%BUILD_DIR%" rmdir /s /q "%BUILD_DIR%"

REM 定义路径
set "BUILD_TOOL_DIR=%~dp0"
set "PROJECT_ROOT=%~dp0..\"
set "CMAKE_LIST_SRC=%BUILD_TOOL_DIR%CMakeLists.txt"
set "CMAKE_LIST_DEST=%PROJECT_ROOT%CMakeLists.txt"

REM 复制 CMakeLists.txt 到根目录
copy /Y "%CMAKE_LIST_SRC%" "%CMAKE_LIST_DEST%" > nul
if errorlevel 1 (
  echo Error: 复制 CMakeLists.txt 失败
  exit /b 1
)

REM 创建构建目录
mkdir "%BUILD_DIR%"
echo %BUILD_DIR%/BuildTool

REM 生成适用于 Windows 的 Makefile：
REM -G "MinGW Makefiles" 指定生成器类型（需安装 MinGW）
cmake -S %PROJECT_ROOT% -B %BUILD_DIR% -G "MinGW Makefiles" -DCMAKE_BUILD_TYPE=%BUILD_TYPE% -DCMAKE_TOOLCHAIN_FILE=.\BuildTool\arm-gcc-toolchain.cmake --fresh

REM 调用cmake指令执行编译动作
pushd "%BUILD_DIR%"
cmake --build . --config %BUILD_TYPE% --target all -- -j12  > build.log 2>&1
popd

REM 删除临时复制的 CMakeLists.txt
del "%CMAKE_LIST_DEST%" > nul 2>&1
if errorlevel 1 (
  echo Warning: 删除临时 CMakeLists.txt 失败
)

REM download hex file to board
@REM call download.bat