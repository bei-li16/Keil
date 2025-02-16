/*
 * key_bsp.c
 *
 *  Created on: Feb 13, 2025
 *      Author: 18283
 */
#include "led_bsp.h"
#include "key_bsp.h"

void HAL_GPIO_EXTI_Callback(uint16_t GPIO_Pin)
{
	if(KEY2_Pin == GPIO_Pin)
	{
		Led_BlueFlip();
	}
}
