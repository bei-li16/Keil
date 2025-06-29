/*
 * user_task.h
 *
 *  Created on: Feb 26, 2025
 *      Author: 18283
 */

#ifndef USER_TASK_INC_USER_TASK_H_
#define USER_TASK_INC_USER_TASK_H_

#include "bsp.h"

#define     TASK50MS_DELAY          50
#define     TASK100MS_DELAY         100
#define     TASK1000MS_DELAY        1000

#define     TASKDEFAULT_PRIORITY    1
#define     TASK50MS_PRIORITY       2
#define     TASK100MS_PRIORITY      3
#define     TASK1000MS_PRIORITY     4

#define     TASK50MS_STACK_SIZE     (128 * 1)
#define     TASK100MS_STACK_SIZE    (128 * 4)
#define     TASK1000MS_STACK_SIZE   (128 * 4)

#define     TASK50MS_NAME           "Task50ms"
#define     TASK100MS_NAME          "Task100ms"
#define     TASK1000MS_NAME         "Task1000ms"

#define     VTASKDELAYUNTIL         INCLUDE_vTaskDelayUntil

extern void Task50ms(void *argument);
extern void Task100ms(void *argument);
extern void Task1000ms(void *argument);

#endif /* USER_TASK_INC_USER_TASK_H_ */
