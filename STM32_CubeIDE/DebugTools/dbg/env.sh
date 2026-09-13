# 调试工具链环境配置 —— source 本文件后使用各脚本
# 所有路径指向 CubeIDE 1.18.1 捆绑的工具（J-Link 已降级为 V7.94e）

export CUBEIDE=/c/ST/STM32CubeIDE_1.18.1/STM32CubeIDE/plugins
export GDB_SERVER="$CUBEIDE/com.st.stm32cube.ide.mcu.externaltools.jlink.win32_2.4.0.202501261557/tools/bin/JLinkGDBServerCL.exe"
export GDB="$CUBEIDE/com.st.stm32cube.ide.mcu.externaltools.gnu-tools-for-stm32.13.3.rel1.win32_1.0.0.202411081344/tools/bin/arm-none-eabi-gdb.exe"
export MAKE="$CUBEIDE/com.st.stm32cube.ide.mcu.externaltools.make.win32_2.2.0.202409170845/tools/bin/make.exe"
export GCC_BIN="$CUBEIDE/com.st.stm32cube.ide.mcu.externaltools.gnu-tools-for-stm32.13.3.rel1.win32_1.0.0.202411081344/tools/bin"

# 目标与连接参数（V7.94e + 克隆V8 实测稳定的组合）
export DBG_DEVICE=STM32F429ZI
export DBG_IF=SWD
export DBG_SPEED=1000
export DBG_PORT=3333

# 默认工程
export PROJ=/g/Data/GitFiles/Keil/STM32_CubeIDE/FreeRTOS_Project
export ELF="$PROJ/Debug/FreeRTOS_Project.elf"
