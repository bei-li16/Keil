/*
 * global_timer.c
 *
 *  Created on: Feb 16, 2025
 *      Author: 18283
 */
#include "global_timer.h"

volatile uint32_t timestamp1ms = 0;
volatile uint32_t timestamp1000ms = 0;

uint32_t gettimestampms(void)
{
	return timestamp1ms;
}

void HAL_TIM_PeriodElapsedCallback(TIM_HandleTypeDef *htim)
{
	if(GLOBAL_TIMER == htim)
	{
		timestamp1ms++;
		if(((timestamp1ms + 1) % 500) == 0)
		{
			SET_500MS_TASK;
		}
	}
	else if (PRINT_TIMER == htim)
	{
		timestamp1000ms++;
		SET_1000MS_TASK;
	}

}
