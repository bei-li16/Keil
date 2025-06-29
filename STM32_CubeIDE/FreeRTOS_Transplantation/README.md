# FreeRTOS_Project

## CMake自动脚本

1. AutoCMakeTool文件夹下包含自动构建所需脚本;
2. Build.bat程序入口，包含1个入参;

```bat
.\Build.bat [param1]
其中: param1为bankname，可选A, B, ALL
```

3. download.bat为jlink下载脚本，下载hex文件到STM32片内Flash;
4. gen_cmake.py自动检索工程根目录下所有.c .h .s .S文件和路径，并根据模板CMakeLists.template生成CMakelists.txt;
5. merge_hex.py hex1 hex2 --o/----output output.hex 用于合并A/B分区的hex文件输出到output.hex中;
6. arm-gcc-toolchain.cmake为工具链脚本用于定义CMake工具链。
