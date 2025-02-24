################################################################################
# Automatically-generated file. Do not edit!
# Toolchain: GNU Tools for STM32 (12.3.rel1)
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../BSP/EEPROM/Src/bsp_I2C_eeprom.c 

OBJS += \
./BSP/EEPROM/Src/bsp_I2C_eeprom.o 

C_DEPS += \
./BSP/EEPROM/Src/bsp_I2C_eeprom.d 


# Each subdirectory must supply rules for building sources it contributes
BSP/EEPROM/Src/%.o BSP/EEPROM/Src/%.su BSP/EEPROM/Src/%.cyclo: ../BSP/EEPROM/Src/%.c BSP/EEPROM/Src/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m4 -std=gnu11 -g3 -DDEBUG -DUSE_HAL_DRIVER -DSTM32F429xx -c -I../Core/Inc -I"K:/Data/GitFiles/Keil/STM32_CubeIDE/LCD_Driver/BSP/PWM/Inc" -I"K:/Data/GitFiles/Keil/STM32_CubeIDE/LCD_Driver/BSP/EEPROM/Inc" -I"K:/Data/GitFiles/Keil/STM32_CubeIDE/LCD_Driver/BSP/LCD/Inc" -I"K:/Data/GitFiles/Keil/STM32_CubeIDE/LCD_Driver/BSP/TASK/Inc" -I../Drivers/STM32F4xx_HAL_Driver/Inc -I../Drivers/STM32F4xx_HAL_Driver/Inc/Legacy -I../Drivers/CMSIS/Device/ST/STM32F4xx/Include -I../Drivers/CMSIS/Include -I"K:/Data/GitFiles/Keil/STM32_CubeIDE/LCD_Driver/BSP/LOG/Inc" -I"K:/Data/GitFiles/Keil/STM32_CubeIDE/LCD_Driver/BSP/PWM/Inc" -O0 -ffunction-sections -fdata-sections -Wall -fstack-usage -fcyclomatic-complexity -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" --specs=nano.specs -mfpu=fpv4-sp-d16 -mfloat-abi=hard -mthumb -o "$@"

clean: clean-BSP-2f-EEPROM-2f-Src

clean-BSP-2f-EEPROM-2f-Src:
	-$(RM) ./BSP/EEPROM/Src/bsp_I2C_eeprom.cyclo ./BSP/EEPROM/Src/bsp_I2C_eeprom.d ./BSP/EEPROM/Src/bsp_I2C_eeprom.o ./BSP/EEPROM/Src/bsp_I2C_eeprom.su

.PHONY: clean-BSP-2f-EEPROM-2f-Src

