################################################################################
# Automatically-generated file. Do not edit!
# Toolchain: GNU Tools for STM32 (12.3.rel1)
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../BSP/LED/Src/bsp_led.c 

OBJS += \
./BSP/LED/Src/bsp_led.o 

C_DEPS += \
./BSP/LED/Src/bsp_led.d 


# Each subdirectory must supply rules for building sources it contributes
BSP/LED/Src/%.o BSP/LED/Src/%.su BSP/LED/Src/%.cyclo: ../BSP/LED/Src/%.c BSP/LED/Src/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m4 -std=gnu11 -DUSE_HAL_DRIVER -DSTM32F429xx -c -I../Core/Inc -I"C:/Users/18283/STM32CubeIDE/workspace_1.17.0/BootLoader/BSP/BOOT/Inc" -I"C:/Users/18283/STM32CubeIDE/workspace_1.17.0/BootLoader/BSP/LED/Inc" -I"C:/Users/18283/STM32CubeIDE/workspace_1.17.0/BootLoader/BSP/LOG/Inc" -I"C:/Users/18283/STM32CubeIDE/workspace_1.17.0/BootLoader/BSP" -I../Drivers/STM32F4xx_HAL_Driver/Inc -I../Drivers/STM32F4xx_HAL_Driver/Inc/Legacy -I../Drivers/CMSIS/Device/ST/STM32F4xx/Include -I../Drivers/CMSIS/Include -Os -ffunction-sections -fdata-sections -Wall -fstack-usage -fcyclomatic-complexity -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" --specs=nano.specs -mfpu=fpv4-sp-d16 -mfloat-abi=hard -mthumb -o "$@"

clean: clean-BSP-2f-LED-2f-Src

clean-BSP-2f-LED-2f-Src:
	-$(RM) ./BSP/LED/Src/bsp_led.cyclo ./BSP/LED/Src/bsp_led.d ./BSP/LED/Src/bsp_led.o ./BSP/LED/Src/bsp_led.su

.PHONY: clean-BSP-2f-LED-2f-Src

