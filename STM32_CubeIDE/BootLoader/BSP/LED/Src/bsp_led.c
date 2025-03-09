/*
* led_bsp.c
*
*  Created on: Feb 25, 2025
*      Author: 18283
*/
#include "bsp_led.h"

void Led_Init(void)
{
    LED_RED_OFF;
    LED_GREEN_OFF;
    LED_BLUE_OFF;
}

void Led_Task(void)
{
    Led_RedFlip();
}
 