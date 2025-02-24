################################################################################
# Automatically-generated file. Do not edit!
# Toolchain: GNU Tools for STM32 (12.3.rel1)
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../BSP/TASK/Src/bsp_timer.c \
../BSP/TASK/Src/task_bsp.c 

OBJS += \
./BSP/TASK/Src/bsp_timer.o \
./BSP/TASK/Src/task_bsp.o 

C_DEPS += \
./BSP/TASK/Src/bsp_timer.d \
./BSP/TASK/Src/task_bsp.d 


# Each subdirectory must supply rules for building sources it contributes
BSP/TASK/Src/%.o BSP/TASK/Src/%.su BSP/TASK/Src/%.cyclo: ../BSP/TASK/Src/%.c BSP/TASK/Src/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m4 -std=gnu11 -g3 -DDEBUG -DUSE_HAL_DRIVER -DSTM32F429xx -c -I../Core/Inc -I"C:/Users/18283/STM32CubeIDE/workspace_1.17.0/LCD_Driver/BSP/PWM/Inc" -I"C:/Users/18283/STM32CubeIDE/workspace_1.17.0/LCD_Driver/BSP/EEPROM/Inc" -I"C:/Users/18283/STM32CubeIDE/workspace_1.17.0/LCD_Driver/BSP/LCD/Inc" -I"C:/Users/18283/STM32CubeIDE/workspace_1.17.0/LCD_Driver/BSP/TASK/Inc" -I../Drivers/STM32F4xx_HAL_Driver/Inc -I../Drivers/STM32F4xx_HAL_Driver/Inc/Legacy -I../Drivers/CMSIS/Device/ST/STM32F4xx/Include -I../Drivers/CMSIS/Include -I"C:/Users/18283/STM32CubeIDE/workspace_1.17.0/LCD_Driver/BSP/LOG/Inc" -I"C:/Users/18283/STM32CubeIDE/workspace_1.17.0/LCD_Driver/BSP/PWM/Inc" -O0 -ffunction-sections -fdata-sections -Wall -fstack-usage -fcyclomatic-complexity -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" --specs=nano.specs -mfpu=fpv4-sp-d16 -mfloat-abi=hard -mthumb -o "$@"

clean: clean-BSP-2f-TASK-2f-Src

clean-BSP-2f-TASK-2f-Src:
	-$(RM) ./BSP/TASK/Src/bsp_timer.cyclo ./BSP/TASK/Src/bsp_timer.d ./BSP/TASK/Src/bsp_timer.o ./BSP/TASK/Src/bsp_timer.su ./BSP/TASK/Src/task_bsp.cyclo ./BSP/TASK/Src/task_bsp.d ./BSP/TASK/Src/task_bsp.o ./BSP/TASK/Src/task_bsp.su

.PHONY: clean-BSP-2f-TASK-2f-Src

