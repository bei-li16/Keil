################################################################################
# Automatically-generated file. Do not edit!
# Toolchain: GNU Tools for STM32 (12.3.rel1)
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../BSP/OLED/Src/bsp_oled.c 

OBJS += \
./BSP/OLED/Src/bsp_oled.o 

C_DEPS += \
./BSP/OLED/Src/bsp_oled.d 


# Each subdirectory must supply rules for building sources it contributes
BSP/OLED/Src/%.o BSP/OLED/Src/%.su BSP/OLED/Src/%.cyclo: ../BSP/OLED/Src/%.c BSP/OLED/Src/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m4 -std=gnu11 -g3 -DDEBUG -DUSE_HAL_DRIVER -DSTM32F429xx -c -I../Core/Inc -I"K:/Data/GitFiles/Keil/STM32_CubeIDE/LED_Master/BSP/OLED/Inc" -I../Drivers/STM32F4xx_HAL_Driver/Inc -I../Drivers/STM32F4xx_HAL_Driver/Inc/Legacy -I../Drivers/CMSIS/Device/ST/STM32F4xx/Include -I../Drivers/CMSIS/Include -I"K:/Data/GitFiles/Keil/STM32_CubeIDE/LED_Master/BSP/Inc" -I"K:/Data/GitFiles/Keil/STM32_CubeIDE/LED_Master/BSP/LCD/Inc" -O0 -ffunction-sections -fdata-sections -Wall -fstack-usage -fcyclomatic-complexity -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" --specs=nano.specs -mfpu=fpv4-sp-d16 -mfloat-abi=hard -mthumb -o "$@"

clean: clean-BSP-2f-OLED-2f-Src

clean-BSP-2f-OLED-2f-Src:
	-$(RM) ./BSP/OLED/Src/bsp_oled.cyclo ./BSP/OLED/Src/bsp_oled.d ./BSP/OLED/Src/bsp_oled.o ./BSP/OLED/Src/bsp_oled.su

.PHONY: clean-BSP-2f-OLED-2f-Src

