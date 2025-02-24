/*
 * bsp_timer.h
 *
 *  Created on: Feb 23, 2025
 *      Author: 18283
 */

#ifndef TASK_INC_BSP_TIMER_H_
#define TASK_INC_BSP_TIMER_H_

#include "tim.h"
#include "task_bsp.h"

#define 	OS_TICK_TIMER 		    &OS_TIMER

extern volatile uint32_t OS_Tick1ms;
extern uint32_t Get_Time(void);

#endif /* TASK_INC_BSP_TIMER_H_ */
