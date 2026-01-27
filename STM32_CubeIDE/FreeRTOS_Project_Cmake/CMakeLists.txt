cmake_minimum_required(VERSION 3.20)

# 工程名称
project(FreeRTOS_Project C ASM)

# 构建类型
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release)
    message(STATUS "Build type not specified, using Release")
endif()

# 输出目录
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/build)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/build)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/build)

# 链接脚本
set(LINKER_SCRIPT ${CMAKE_CURRENT_SOURCE_DIR}/STM32F429IGTX_FLASH.ld)

# 启用汇编语言支持
enable_language(ASM)

# 添加链接脚本到链接器选项
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -T${LINKER_SCRIPT}")

# 定义可执行文件
add_executable(${PROJECT_NAME}.elf

    # ========== 启动文件 ==========
    ${CMAKE_CURRENT_SOURCE_DIR}/Core/Startup/startup_stm32f429igtx.s

    # ========== Core源文件 ==========
    ${CMAKE_CURRENT_SOURCE_DIR}/Core/Src/main.c
    ${CMAKE_CURRENT_SOURCE_DIR}/Core/Src/gpio.c
    ${CMAKE_CURRENT_SOURCE_DIR}/Core/Src/dma.c
    ${CMAKE_CURRENT_SOURCE_DIR}/Core/Src/spi.c
    ${CMAKE_CURRENT_SOURCE_DIR}/Core/Src/usart.c
    ${CMAKE_CURRENT_SOURCE_DIR}/Core/Src/stm32f4xx_it.c
    ${CMAKE_CURRENT_SOURCE_DIR}/Core/Src/stm32f4xx_hal_msp.c
    ${CMAKE_CURRENT_SOURCE_DIR}/Core/Src/syscalls.c
    ${CMAKE_CURRENT_SOURCE_DIR}/Core/Src/sysmem.c
    ${CMAKE_CURRENT_SOURCE_DIR}/Core/Src/system_stm32f4xx.c
    ${CMAKE_CURRENT_SOURCE_DIR}/Core/Src/freertos.c

    # ========== HAL驱动源文件 ==========
    ${CMAKE_CURRENT_SOURCE_DIR}/Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal.c
    ${CMAKE_CURRENT_SOURCE_DIR}/Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_cortex.c
    ${CMAKE_CURRENT_SOURCE_DIR}/Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_dma.c
    ${CMAKE_CURRENT_SOURCE_DIR}/Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_dma_ex.c
    ${CMAKE_CURRENT_SOURCE_DIR}/Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_gpio.c
    ${CMAKE_CURRENT_SOURCE_DIR}/Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_pwr.c
    ${CMAKE_CURRENT_SOURCE_DIR}/Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_pwr_ex.c
    ${CMAKE_CURRENT_SOURCE_DIR}/Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_rcc.c
    ${CMAKE_CURRENT_SOURCE_DIR}/Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_rcc_ex.c
    ${CMAKE_CURRENT_SOURCE_DIR}/Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_spi.c
    ${CMAKE_CURRENT_SOURCE_DIR}/Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_uart.c
    ${CMAKE_CURRENT_SOURCE_DIR}/Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_flash.c
    ${CMAKE_CURRENT_SOURCE_DIR}/Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_flash_ex.c
    ${CMAKE_CURRENT_SOURCE_DIR}/Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_exti.c
    ${CMAKE_CURRENT_SOURCE_DIR}/Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_flash_ramfunc.c

    # ========== FreeRTOS源文件 ==========
    ${CMAKE_CURRENT_SOURCE_DIR}/Middlewares/Third_Party/FreeRTOS/Source/croutine.c
    ${CMAKE_CURRENT_SOURCE_DIR}/Middlewares/Third_Party/FreeRTOS/Source/event_groups.c
    ${CMAKE_CURRENT_SOURCE_DIR}/Middlewares/Third_Party/FreeRTOS/Source/list.c
    ${CMAKE_CURRENT_SOURCE_DIR}/Middlewares/Third_Party/FreeRTOS/Source/queue.c
    ${CMAKE_CURRENT_SOURCE_DIR}/Middlewares/Third_Party/FreeRTOS/Source/stream_buffer.c
    ${CMAKE_CURRENT_SOURCE_DIR}/Middlewares/Third_Party/FreeRTOS/Source/tasks.c
    ${CMAKE_CURRENT_SOURCE_DIR}/Middlewares/Third_Party/FreeRTOS/Source/timers.c
    ${CMAKE_CURRENT_SOURCE_DIR}/Middlewares/Third_Party/FreeRTOS/Source/CMSIS_RTOS/cmsis_os.c
    ${CMAKE_CURRENT_SOURCE_DIR}/Middlewares/Third_Party/FreeRTOS/Source/portable/GCC/ARM_CM4F/port.c
    ${CMAKE_CURRENT_SOURCE_DIR}/Middlewares/Third_Party/FreeRTOS/Source/portable/MemMang/heap_4.c

    # ========== BSP源文件 ==========
    ${CMAKE_CURRENT_SOURCE_DIR}/BSP/LED/Src/bsp_led.c
    ${CMAKE_CURRENT_SOURCE_DIR}/BSP/LOG/Src/bsp_log.c
    ${CMAKE_CURRENT_SOURCE_DIR}/BSP/USER_TASK/Src/user_task.c
    ${CMAKE_CURRENT_SOURCE_DIR}/BSP/W25Q128/Src/bsp_w25q.c
)

# ========== 包含目录 ==========
target_include_directories(${PROJECT_NAME}.elf PRIVATE

    # Core包含目录
    ${CMAKE_CURRENT_SOURCE_DIR}/Core/Inc

    # CMSIS包含目录
    ${CMAKE_CURRENT_SOURCE_DIR}/Drivers/CMSIS/Device/ST/STM32F4xx/Include
    ${CMAKE_CURRENT_SOURCE_DIR}/Drivers/CMSIS/Include

    # HAL驱动包含目录
    ${CMAKE_CURRENT_SOURCE_DIR}/Drivers/STM32F4xx_HAL_Driver/Inc

    # FreeRTOS包含目录
    ${CMAKE_CURRENT_SOURCE_DIR}/Middlewares/Third_Party/FreeRTOS/Source/include
    ${CMAKE_CURRENT_SOURCE_DIR}/Middlewares/Third_Party/FreeRTOS/Source/CMSIS_RTOS
    ${CMAKE_CURRENT_SOURCE_DIR}/Middlewares/Third_Party/FreeRTOS/Source/portable/GCC/ARM_CM4F

    # BSP包含目录
    ${CMAKE_CURRENT_SOURCE_DIR}/BSP
    ${CMAKE_CURRENT_SOURCE_DIR}/BSP/LED/Inc
    ${CMAKE_CURRENT_SOURCE_DIR}/BSP/LOG/Inc
    ${CMAKE_CURRENT_SOURCE_DIR}/BSP/USER_TASK/Inc
    ${CMAKE_CURRENT_SOURCE_DIR}/BSP/W25Q128/Inc
)

# ========== 编译定义 ==========
target_compile_definitions(${PROJECT_NAME}.elf PRIVATE
    USE_HAL_DRIVER
    STM32F429xx
)

# ========== 后处理命令 ==========
# 生成HEX文件
add_custom_command(TARGET ${PROJECT_NAME}.elf POST_BUILD
    COMMAND ${CMAKE_OBJCOPY} -O ihex $<TARGET_FILE:${PROJECT_NAME}.elf>
            ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${PROJECT_NAME}.hex
    COMMENT "Generating HEX file"
)

# 生成BIN文件
add_custom_command(TARGET ${PROJECT_NAME}.elf POST_BUILD
    COMMAND ${CMAKE_OBJCOPY} -O binary $<TARGET_FILE:${PROJECT_NAME}.elf>
            ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${PROJECT_NAME}.bin
    COMMENT "Generating BIN file"
)

# 显示内存使用情况
add_custom_command(TARGET ${PROJECT_NAME}.elf POST_BUILD
    COMMAND ${CMAKE_SIZE} $<TARGET_FILE:${PROJECT_NAME}.elf>
    COMMENT "Memory usage:"
)

# ========== 输出构建信息 ==========
message(STATUS "===========================================")
message(STATUS "FreeRTOS Project Configuration")
message(STATUS "===========================================")
message(STATUS "Project Name: ${PROJECT_NAME}")
message(STATUS "Build Type: ${CMAKE_BUILD_TYPE}")
message(STATUS "Target MCU: STM32F429IGT6")
message(STATUS "Core: Cortex-M4F")
message(STATUS "Linker Script: ${LINKER_SCRIPT}")
message(STATUS "Output Directory: ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}")
message(STATUS "===========================================")
message(STATUS "Output Files:")
message(STATUS "  - ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${PROJECT_NAME}.elf")
message(STATUS "  - ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${PROJECT_NAME}.hex")
message(STATUS "  - ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${PROJECT_NAME}.bin")
message(STATUS "  - ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${PROJECT_NAME}.map")
message(STATUS "===========================================")
