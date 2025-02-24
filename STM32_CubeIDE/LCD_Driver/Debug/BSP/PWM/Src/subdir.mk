################################################################################
# Automatically-generated file. Do not edit!
# Toolchain: GNU Tools for STM32 (12.3.rel1)
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../BSP/PWM/Src/bsp_tower.c 

OBJS += \
./BSP/PWM/Src/bsp_tower.o 

C_DEPS += \
./BSP/PWM/Src/bsp_tower.d 


# Each subdirectory must supply rules for building sources it contributes
BSP/PWM/Src/%.o BSP/PWM/Src/%.su BSP/PWM/Src/%.cyclo: ../BSP/PWM/Src/%.c BSP/PWM/Src/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m4 -std=gnu11 -g3 -DDEBUG -DUSE_HAL_DRIVER -DSTM32F429xx -c -I../Core/Inc -I"K:/Data/GitFiles/Keil/STM32_CubeIDE/LCD_Driver/BSP/PWM/Inc" -I"K:/Data/GitFiles/Keil/STM32_CubeIDE/LCD_Driver/BSP/EEPROM/Inc" -I"K:/Data/GitFiles/Keil/STM32_CubeIDE/LCD_Driver/BSP/LCD/Inc" -I"K:/Data/GitFiles/Keil/STM32_CubeIDE/LCD_Driver/BSP/TASK/Inc" -I../Drivers/STM32F4xx_HAL_Driver/Inc -I../Drivers/STM32F4xx_HAL_Driver/Inc/Legacy -I../Drivers/CMSIS/Device/ST/STM32F4xx/Include -I../Drivers/CMSIS/Include -I"K:/Data/GitFiles/Keil/STM32_CubeIDE/LCD_Driver/BSP/LOG/Inc" -I"K:/Data/GitFiles/Keil/STM32_CubeIDE/LCD_Driver/BSP/PWM/Inc" -O0 -ffunction-sections -fdata-sections -Wall -fstack-usage -fcyclomatic-complexity -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" --specs=nano.specs -mfpu=fpv4-sp-d16 -mfloat-abi=hard -mthumb -o "$@"

clean: clean-BSP-2f-PWM-2f-Src

clean-BSP-2f-PWM-2f-Src:
	-$(RM) ./BSP/PWM/Src/bsp_tower.cyclo ./BSP/PWM/Src/bsp_tower.d ./BSP/PWM/Src/bsp_tower.o ./BSP/PWM/Src/bsp_tower.su

.PHONY: clean-BSP-2f-PWM-2f-Src

