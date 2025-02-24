################################################################################
# Automatically-generated file. Do not edit!
# Toolchain: GNU Tools for STM32 (12.3.rel1)
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../BSP/LCD/Src/GUI.c \
../BSP/LCD/Src/Lcd_Driver.c 

OBJS += \
./BSP/LCD/Src/GUI.o \
./BSP/LCD/Src/Lcd_Driver.o 

C_DEPS += \
./BSP/LCD/Src/GUI.d \
./BSP/LCD/Src/Lcd_Driver.d 


# Each subdirectory must supply rules for building sources it contributes
BSP/LCD/Src/%.o BSP/LCD/Src/%.su BSP/LCD/Src/%.cyclo: ../BSP/LCD/Src/%.c BSP/LCD/Src/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m4 -std=gnu11 -g3 -DDEBUG -DUSE_HAL_DRIVER -DSTM32F429xx -c -I../Core/Inc -I"K:/Data/GitFiles/Keil/STM32_CubeIDE/LCD_Driver/BSP/PWM/Inc" -I"K:/Data/GitFiles/Keil/STM32_CubeIDE/LCD_Driver/BSP/EEPROM/Inc" -I"K:/Data/GitFiles/Keil/STM32_CubeIDE/LCD_Driver/BSP/LCD/Inc" -I"K:/Data/GitFiles/Keil/STM32_CubeIDE/LCD_Driver/BSP/TASK/Inc" -I../Drivers/STM32F4xx_HAL_Driver/Inc -I../Drivers/STM32F4xx_HAL_Driver/Inc/Legacy -I../Drivers/CMSIS/Device/ST/STM32F4xx/Include -I../Drivers/CMSIS/Include -I"K:/Data/GitFiles/Keil/STM32_CubeIDE/LCD_Driver/BSP/LOG/Inc" -I"K:/Data/GitFiles/Keil/STM32_CubeIDE/LCD_Driver/BSP/PWM/Inc" -O0 -ffunction-sections -fdata-sections -Wall -fstack-usage -fcyclomatic-complexity -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" --specs=nano.specs -mfpu=fpv4-sp-d16 -mfloat-abi=hard -mthumb -o "$@"

clean: clean-BSP-2f-LCD-2f-Src

clean-BSP-2f-LCD-2f-Src:
	-$(RM) ./BSP/LCD/Src/GUI.cyclo ./BSP/LCD/Src/GUI.d ./BSP/LCD/Src/GUI.o ./BSP/LCD/Src/GUI.su ./BSP/LCD/Src/Lcd_Driver.cyclo ./BSP/LCD/Src/Lcd_Driver.d ./BSP/LCD/Src/Lcd_Driver.o ./BSP/LCD/Src/Lcd_Driver.su

.PHONY: clean-BSP-2f-LCD-2f-Src

