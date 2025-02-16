/*
 * global_timer.h
 *
 *  Created on: Feb 16, 2025
 *      Author: 18283
 */

#ifndef INC_GLOBAL_TIMER_H_
#define INC_GLOBAL_TIMER_H_

#include "tim.h"
#include "task_bsp.h"

extern volatile uint32_t timestamp1ms;
extern volatile uint32_t timestamp1000ms;
extern TIM_HandleTypeDef htim4;

#define 	PRINT_TIMER 		&htim3
#define 	GLOBAL_TIMER 		&htim4

extern uint32_t gettimestampms(void);


#endif /* INC_GLOBAL_TIMER_H_ */
