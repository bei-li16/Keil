################################################################################
# Automatically-generated file. Do not edit!
# Toolchain: GNU Tools for STM32 (12.3.rel1)
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../BSP/LOG/Src/bsp_log.c 

OBJS += \
./BSP/LOG/Src/bsp_log.o 

C_DEPS += \
./BSP/LOG/Src/bsp_log.d 


# Each subdirectory must supply rules for building sources it contributes
BSP/LOG/Src/%.o BSP/LOG/Src/%.su BSP/LOG/Src/%.cyclo: ../BSP/LOG/Src/%.c BSP/LOG/Src/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m4 -std=gnu11 -g3 -DDEBUG -DUSE_HAL_DRIVER -DSTM32F429xx -c -I../Core/Inc -I"C:/Users/18283/STM32CubeIDE/workspace_1.17.0/LCD_Driver/BSP/PWM/Inc" -I"C:/Users/18283/STM32CubeIDE/workspace_1.17.0/LCD_Driver/BSP/EEPROM/Inc" -I"C:/Users/18283/STM32CubeIDE/workspace_1.17.0/LCD_Driver/BSP/LCD/Inc" -I"C:/Users/18283/STM32CubeIDE/workspace_1.17.0/LCD_Driver/BSP/TASK/Inc" -I../Drivers/STM32F4xx_HAL_Driver/Inc -I../Drivers/STM32F4xx_HAL_Driver/Inc/Legacy -I../Drivers/CMSIS/Device/ST/STM32F4xx/Include -I../Drivers/CMSIS/Include -I"C:/Users/18283/STM32CubeIDE/workspace_1.17.0/LCD_Driver/BSP/LOG/Inc" -I"C:/Users/18283/STM32CubeIDE/workspace_1.17.0/LCD_Driver/BSP/PWM/Inc" -O0 -ffunction-sections -fdata-sections -Wall -fstack-usage -fcyclomatic-complexity -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" --specs=nano.specs -mfpu=fpv4-sp-d16 -mfloat-abi=hard -mthumb -o "$@"

clean: clean-BSP-2f-LOG-2f-Src

clean-BSP-2f-LOG-2f-Src:
	-$(RM) ./BSP/LOG/Src/bsp_log.cyclo ./BSP/LOG/Src/bsp_log.d ./BSP/LOG/Src/bsp_log.o ./BSP/LOG/Src/bsp_log.su

.PHONY: clean-BSP-2f-LOG-2f-Src

