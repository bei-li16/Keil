# ARM GCC Toolchain Configuration
# 此文件包含编译器、汇编器、链接器等工具的配置
# 跳过编译器检查，直接使用指定的工具链路径

# 工具链路径（根据实际安装路径修改）
set(TOOLCHAIN_PATH "D:/Software/arm-gnu-toolchain-14.3.rel1-mingw-w64-x86_64-arm-none-eabi/bin")

# 工具链前缀
set(TOOLCHAIN_PREFIX "arm-none-eabi-")

# 设置编译器路径（不进行编译器检查）
set(CMAKE_C_COMPILER "${TOOLCHAIN_PATH}/${TOOLCHAIN_PREFIX}gcc.exe" CACHE PATH "C Compiler" FORCE)
set(CMAKE_CXX_COMPILER "${TOOLCHAIN_PATH}/${TOOLCHAIN_PREFIX}g++.exe" CACHE PATH "C++ Compiler" FORCE)
set(CMAKE_ASM_COMPILER "${TOOLCHAIN_PATH}/${TOOLCHAIN_PREFIX}gcc.exe" CACHE PATH "ASM Compiler" FORCE)

# 设置链接器和相关工具
set(CMAKE_LINKER "${TOOLCHAIN_PATH}/${TOOLCHAIN_PREFIX}ld.exe" CACHE FILEPATH "Linker" FORCE)
set(CMAKE_AR "${TOOLCHAIN_PATH}/${TOOLCHAIN_PREFIX}ar.exe" CACHE FILEPATH "Archiver" FORCE)
set(CMAKE_OBJCOPY "${TOOLCHAIN_PATH}/${TOOLCHAIN_PREFIX}objcopy.exe" CACHE FILEPATH "Objcopy" FORCE)
set(CMAKE_OBJDUMP "${TOOLCHAIN_PATH}/${TOOLCHAIN_PREFIX}objdump.exe" CACHE FILEPATH "Objdump" FORCE)
set(CMAKE_SIZE "${TOOLCHAIN_PATH}/${TOOLCHAIN_PREFIX}size.exe" CACHE FILEPATH "Size" FORCE)
set(CMAKE_STRIP "${TOOLCHAIN_PATH}/${TOOLCHAIN_PREFIX}strip.exe" CACHE FILEPATH "Strip" FORCE)
set(CMAKE_NM "${TOOLCHAIN_PATH}/${TOOLCHAIN_PREFIX}nm.exe" CACHE FILEPATH "NM" FORCE)

# 跳过编译器检查
set(CMAKE_C_COMPILER_WORKS 1 CACHE BOOL "")
set(CMAKE_CXX_COMPILER_WORKS 1 CACHE BOOL "")

# 设置CMAKE相关变量以避免检查
set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR ARM)
set(CMAKE_SYSTEM_VERSION 1)

# 不使用系统路径查找库和头文件
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# 不生成测试程序
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

# 设置目标系统
set(CMAKE_EXECUTABLE_SUFFIX_ASM ".elf")
set(CMAKE_EXECUTABLE_SUFFIX_C ".elf")
set(CMAKE_EXECUTABLE_SUFFIX_CXX ".elf")

# 编译器选项（通用）
set(COMMON_FLAGS "-mcpu=cortex-m4")
set(COMMON_FLAGS "${COMMON_FLAGS} -mthumb")
set(COMMON_FLAGS "${COMMON_FLAGS} -mfpu=fpv4-sp-d16")
set(COMMON_FLAGS "${COMMON_FLAGS} -mfloat-abi=hard")
set(COMMON_FLAGS "${COMMON_FLAGS} -DSTM32F429xx")
set(COMMON_FLAGS "${COMMON_FLAGS} -DUSE_HAL_DRIVER")

# C编译器选项
set(CMAKE_C_FLAGS "${COMMON_FLAGS} -std=c11 -Wno-incompatible-pointer-types -Wno-int-conversion -Wno-implicit-int" CACHE STRING "C Flags")
set(CMAKE_C_FLAGS_DEBUG "${COMMON_FLAGS} -g -Og -Wall -Wno-incompatible-pointer-types -Wno-int-conversion -Wno-implicit-int" CACHE STRING "C Debug Flags")
set(CMAKE_C_FLAGS_RELEASE "${COMMON_FLAGS} -O2 -Wall -Wno-incompatible-pointer-types -Wno-int-conversion -Wno-implicit-int" CACHE STRING "C Release Flags")

# ASM编译器选项
set(CMAKE_ASM_FLAGS "${COMMON_FLAGS} -x assembler-with-cpp" CACHE STRING "ASM Flags")

# 链接器选项
set(CMAKE_EXE_LINKER_FLAGS "${COMMON_FLAGS}" CACHE STRING "Linker Flags")
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Wl,-Map=${CMAKE_BINARY_DIR}/build/${PROJECT_NAME}.map")
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Wl,--gc-sections")
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Wl,--start-group -lc -lm -Wl,--end-group")
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Wl,--print-memory-usage")

# 打印工具链信息
message(STATUS "===========================================")
message(STATUS "ARM GCC Toolchain Configuration")
message(STATUS "===========================================")
message(STATUS "Toolchain Path: ${TOOLCHAIN_PATH}")
message(STATUS "C Compiler: ${CMAKE_C_COMPILER}")
message(STATUS "C++ Compiler: ${CMAKE_CXX_COMPILER}")
message(STATUS "ASM Compiler: ${CMAKE_ASM_COMPILER}")
message(STATUS "Linker: ${CMAKE_LINKER}")
message(STATUS "Objcopy: ${CMAKE_OBJCOPY}")
message(STATUS "Objdump: ${CMAKE_OBJDUMP}")
message(STATUS "Size: ${CMAKE_SIZE}")
message(STATUS "===========================================")
