/*
* led_bsp.c
*
*  Created on: Feb 25, 2025
*      Author: 18283
*/
#include "bsp_led.h"

void Led_RedFlip(void)
{
	HAL_GPIO_TogglePin(LED_RED_GPIO_Port, LED_RED_Pin);
}

void Led_RedON(void)
{
	HAL_GPIO_WritePin(LED_RED_GPIO_Port, LED_RED_Pin, GPIO_PIN_RESET);
}
void Led_RedOFF(void)
{
	HAL_GPIO_WritePin(LED_RED_GPIO_Port, LED_RED_Pin, GPIO_PIN_SET);
}



void Led_Init(void)
{
    Led_RedOFF();
}

void Led_Task(void)
{
    Led_RedFlip();
}
 