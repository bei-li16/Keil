################################################################################
# Automatically-generated file. Do not edit!
# Toolchain: GNU Tools for STM32 (12.3.rel1)
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../BSP/Src/bsp_adc.c \
../BSP/Src/global_timer.c \
../BSP/Src/key_bsp.c \
../BSP/Src/led_bsp.c \
../BSP/Src/task_bsp.c \
../BSP/Src/tools_bsp.c \
../BSP/Src/usart_bsp.c 

OBJS += \
./BSP/Src/bsp_adc.o \
./BSP/Src/global_timer.o \
./BSP/Src/key_bsp.o \
./BSP/Src/led_bsp.o \
./BSP/Src/task_bsp.o \
./BSP/Src/tools_bsp.o \
./BSP/Src/usart_bsp.o 

C_DEPS += \
./BSP/Src/bsp_adc.d \
./BSP/Src/global_timer.d \
./BSP/Src/key_bsp.d \
./BSP/Src/led_bsp.d \
./BSP/Src/task_bsp.d \
./BSP/Src/tools_bsp.d \
./BSP/Src/usart_bsp.d 


# Each subdirectory must supply rules for building sources it contributes
BSP/Src/%.o BSP/Src/%.su BSP/Src/%.cyclo: ../BSP/Src/%.c BSP/Src/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m4 -std=gnu11 -g3 -DDEBUG -DUSE_HAL_DRIVER -DSTM32F429xx -c -I../Core/Inc -I../Drivers/STM32F4xx_HAL_Driver/Inc -I../Drivers/STM32F4xx_HAL_Driver/Inc/Legacy -I../Drivers/CMSIS/Device/ST/STM32F4xx/Include -I../Drivers/CMSIS/Include -I"K:/Data/GitFiles/Keil/STM32_CubeIDE/LED_Master/BSP/Inc" -O0 -ffunction-sections -fdata-sections -Wall -fstack-usage -fcyclomatic-complexity -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" --specs=nano.specs -mfpu=fpv4-sp-d16 -mfloat-abi=hard -mthumb -o "$@"

clean: clean-BSP-2f-Src

clean-BSP-2f-Src:
	-$(RM) ./BSP/Src/bsp_adc.cyclo ./BSP/Src/bsp_adc.d ./BSP/Src/bsp_adc.o ./BSP/Src/bsp_adc.su ./BSP/Src/global_timer.cyclo ./BSP/Src/global_timer.d ./BSP/Src/global_timer.o ./BSP/Src/global_timer.su ./BSP/Src/key_bsp.cyclo ./BSP/Src/key_bsp.d ./BSP/Src/key_bsp.o ./BSP/Src/key_bsp.su ./BSP/Src/led_bsp.cyclo ./BSP/Src/led_bsp.d ./BSP/Src/led_bsp.o ./BSP/Src/led_bsp.su ./BSP/Src/task_bsp.cyclo ./BSP/Src/task_bsp.d ./BSP/Src/task_bsp.o ./BSP/Src/task_bsp.su ./BSP/Src/tools_bsp.cyclo ./BSP/Src/tools_bsp.d ./BSP/Src/tools_bsp.o ./BSP/Src/tools_bsp.su ./BSP/Src/usart_bsp.cyclo ./BSP/Src/usart_bsp.d ./BSP/Src/usart_bsp.o ./BSP/Src/usart_bsp.su

.PHONY: clean-BSP-2f-Src

