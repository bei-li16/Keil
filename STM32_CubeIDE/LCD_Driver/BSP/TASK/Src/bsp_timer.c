/*
 * bsp_timer.c
 *
 *  Created on: Feb 23, 2025
 *      Author: 18283
 */
#include "bsp_timer.h"

volatile uint32_t OS_Tick1ms = 0;

uint32_t Get_Time(void)
{
    return OS_Tick1ms;
}

void HAL_TIM_PeriodElapsedCallback(TIM_HandleTypeDef *htim)
{
    if(OS_TICK_TIMER == htim)
    {
        OS_Tick1ms++;
        if((OS_Tick1ms % 500) == 0)
        {
            SET_500MS_TASK;
        }
        if((OS_Tick1ms % 1000) == 0)
        {
            SET_1000MS_TASK;
        }
    }
}
