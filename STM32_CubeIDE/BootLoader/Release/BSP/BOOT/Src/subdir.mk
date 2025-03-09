################################################################################
# Automatically-generated file. Do not edit!
# Toolchain: GNU Tools for STM32 (12.3.rel1)
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../BSP/BOOT/Src/bsp_boot.c \
../BSP/BOOT/Src/bsp_verify.c 

OBJS += \
./BSP/BOOT/Src/bsp_boot.o \
./BSP/BOOT/Src/bsp_verify.o 

C_DEPS += \
./BSP/BOOT/Src/bsp_boot.d \
./BSP/BOOT/Src/bsp_verify.d 


# Each subdirectory must supply rules for building sources it contributes
BSP/BOOT/Src/%.o BSP/BOOT/Src/%.su BSP/BOOT/Src/%.cyclo: ../BSP/BOOT/Src/%.c BSP/BOOT/Src/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m4 -std=gnu11 -DUSE_HAL_DRIVER -DSTM32F429xx -c -I../Core/Inc -I"C:/Users/18283/STM32CubeIDE/workspace_1.17.0/BootLoader/BSP/BOOT/Inc" -I"C:/Users/18283/STM32CubeIDE/workspace_1.17.0/BootLoader/BSP/LED/Inc" -I"C:/Users/18283/STM32CubeIDE/workspace_1.17.0/BootLoader/BSP/LOG/Inc" -I"C:/Users/18283/STM32CubeIDE/workspace_1.17.0/BootLoader/BSP" -I../Drivers/STM32F4xx_HAL_Driver/Inc -I../Drivers/STM32F4xx_HAL_Driver/Inc/Legacy -I../Drivers/CMSIS/Device/ST/STM32F4xx/Include -I../Drivers/CMSIS/Include -Os -ffunction-sections -fdata-sections -Wall -fstack-usage -fcyclomatic-complexity -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" --specs=nano.specs -mfpu=fpv4-sp-d16 -mfloat-abi=hard -mthumb -o "$@"

clean: clean-BSP-2f-BOOT-2f-Src

clean-BSP-2f-BOOT-2f-Src:
	-$(RM) ./BSP/BOOT/Src/bsp_boot.cyclo ./BSP/BOOT/Src/bsp_boot.d ./BSP/BOOT/Src/bsp_boot.o ./BSP/BOOT/Src/bsp_boot.su ./BSP/BOOT/Src/bsp_verify.cyclo ./BSP/BOOT/Src/bsp_verify.d ./BSP/BOOT/Src/bsp_verify.o ./BSP/BOOT/Src/bsp_verify.su

.PHONY: clean-BSP-2f-BOOT-2f-Src

