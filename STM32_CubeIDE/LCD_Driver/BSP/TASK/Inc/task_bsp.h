/*
 * task_bsp.h
 *
 *  Created on: Feb 16, 2025
 *      Author: 18283
 */

#ifndef INC_TASK_BSP_H_
#define INC_TASK_BSP_H_

#include "Lcd_Driver.h"
#include "bsp_log.h"
#include "bsp_timer.h"
#include "bsp_tower.h"

#define 	TASK_1MS		0x01
#define 	TASK_5MS		0x02
#define 	TASK_10MS		0x04
#define 	TASK_50MS		0x08
#define 	TASK_100MS		0x10
#define 	TASK_500MS		0x20
#define 	TASK_1000MS		0x40

extern volatile uint32_t Task_Cmd;

#define 	SET_1MS_TASK		(Task_Cmd |= TASK_1MS)
#define 	SET_5MS_TASK		(Task_Cmd |= TASK_5MS)
#define 	SET_10MS_TASK		(Task_Cmd |= TASK_10MS)
#define 	SET_50MS_TASK		(Task_Cmd |= TASK_50MS)
#define 	SET_100MS_TASK		(Task_Cmd |= TASK_100MS)
#define 	SET_500MS_TASK		(Task_Cmd |= TASK_500MS)
#define 	SET_1000MS_TASK		(Task_Cmd |= TASK_1000MS)
#define 	RESET_1MS_TASK		(Task_Cmd &= ~TASK_1MS)
#define 	RESET_5MS_TASK		(Task_Cmd &= ~TASK_5MS)
#define 	RESET_10MS_TASK		(Task_Cmd &= ~TASK_10MS)
#define 	RESET_50MS_TASK		(Task_Cmd &= ~TASK_50MS)
#define 	RESET_100MS_TASK	(Task_Cmd &= ~TASK_100MS)
#define 	RESET_500MS_TASK	(Task_Cmd &= ~TASK_500MS)
#define 	RESET_1000MS_TASK	(Task_Cmd &= ~TASK_1000MS)
#define 	GET_1MS_TASK		(TASK_1MS == (Task_Cmd&TASK_1MS))
#define 	GET_5MS_TASK		(TASK_5MS == (Task_Cmd&TASK_5MS))
#define 	GET_10MS_TASK		(TASK_10MS == (Task_Cmd&TASK_10MS))
#define 	GET_50MS_TASK		(TASK_50MS == (Task_Cmd&TASK_50MS))
#define 	GET_100MS_TASK		(TASK_100MS == (Task_Cmd&TASK_100MS))
#define 	GET_500MS_TASK		(TASK_500MS == (Task_Cmd&TASK_500MS))
#define 	GET_1000MS_TASK		(TASK_1000MS == (Task_Cmd&TASK_1000MS))

extern void Start_OS(void);
extern void OS_Init(void);

#endif /* INC_TASK_BSP_H_ */
