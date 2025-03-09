# CMake最低版本要求
cmake_minimum_required(VERSION 3.12)

# 项目名称和版本
project(BootLoader VERSION 1.0.0 LANGUAGES C ASM)

# 添加工具链文件（关键！）
set(CMAKE_TOOLCHAIN_FILE ${CMAKE_SOURCE_DIR}/arm-gcc-toolchain.cmake)

# 源文件配置------------------------------------------
# 启动文件（根据实际路径调整）
set(STARTUP_SCRIPT "${CMAKE_SOURCE_DIR}/STM32F429IGTX_FLASH.ld")
set(STARTUP_FILE "Core/Startup/startup_stm32f429igtx.s")

# 递归收集源文件（注意：GLOB在新增文件时需要重新生成）
file(GLOB_RECURSE SOURCES
    "Core/Src/*.c"
    "Drivers/STM32F4xx_HAL_Driver/Src/*.c"
    # "BSP/LOG/Src/*.c"
    # "BSP/LED/Src/*.c"
    # "BSP/BOOT/Src/*.c"
)

# ----------------------------- 自动发现模块 -----------------------------
# 定义模块根目录
set(MODULES_ROOT ${CMAKE_CURRENT_SOURCE_DIR}/BSP)

# 查找所有可能的模块目录
file(GLOB module_dirs LIST_DIRECTORIES true 
    RELATIVE ${MODULES_ROOT} 
    ${MODULES_ROOT}/*)

# 遍历模块目录，收集源码和头文件
foreach(module_dir ${module_dirs})
    # 拼接完整模块路径
    set(full_module_path ${MODULES_ROOT}/${module_dir})

    # 检查是否存在 src 目录
    if(IS_DIRECTORY ${full_module_path}/src)
        # 收集该模块的源文件
        file(GLOB module_sources 
            ${full_module_path}/src/*.c 
            ${full_module_path}/src/*.cpp 
            ${full_module_path}/src/*.s)

        # 将源文件加入全局列表
        list(APPEND SOURCES ${module_sources})

        # 自动添加头文件目录（如果存在 inc 目录）
        if(IS_DIRECTORY ${full_module_path}/inc)
            include_directories(${full_module_path}/inc)
        endif()

        message(STATUS "Found module: ${module_dir}")
    endif()
endforeach()

# 包含头文件目录--------------------------------------
include_directories(
    Core/Inc
    Drivers/STM32F4xx_HAL_Driver/Inc
    Drivers/STM32F4xx_HAL_Driver/Inc/Legacy
    Drivers/CMSIS/Device/ST/STM32F4xx/Include
    Drivers/CMSIS/Include
    BSP
    BSP/LOG/Inc
    BSP/LED/Inc
    BSP/BOOT/Inc
)

# 编译选项--------------------------------------------
add_compile_options(
    -mcpu=cortex-m4
    -std=gnu11
    -g3
    -DDEBUG
    -DSTM32F429xx  # 芯片型号宏定义
    -DUSE_HAL_DRIVER
    -O0
    -ffunction-sections
    -fdata-sections
    -Wall
    -fstack-usage
    -fcyclomatic-complexity
    --specs=nano.specs
    -mfpu=fpv4-sp-d16
    -mfloat-abi=hard
    -mthumb
)

# 链接选项--------------------------------------------
add_link_options(
    -mcpu=cortex-m4
    -T${STARTUP_SCRIPT}
    -Wl,--gc-sections
    -static
    --specs=nano.specs
    -mfpu=fpv4-sp-d16
    -mfloat-abi=hard
    -mthumb
    -Wl,--start-group
    -lc
    -lm
    -Wl,--end-group
    # -Wl,-Map="BootLoader.map"
)

# 生成可执行文件--------------------------------------
add_executable(${PROJECT_NAME}.elf 
    ${SOURCES}
    ${STARTUP_FILE}
)

# 生成辅助文件----------------------------------------
add_custom_command(TARGET ${PROJECT_NAME}.elf POST_BUILD
    COMMAND ${CMAKE_OBJCOPY} -O ihex ${PROJECT_NAME}.elf ${PROJECT_NAME}.hex
    COMMAND ${CMAKE_OBJCOPY} -O binary ${PROJECT_NAME}.elf ${PROJECT_NAME}.bin
    COMMAND ${CMAKE_OBJCOPY} -O srec ${PROJECT_NAME}.elf ${PROJECT_NAME}.srec
    COMMENT "Generating HEX/BIN/SREC files..."
)

# 显示尺寸信息----------------------------------------
add_custom_command(TARGET ${PROJECT_NAME}.elf POST_BUILD
    COMMAND arm-none-eabi-size ${PROJECT_NAME}.elf
    COMMENT "Memory usage:"
)