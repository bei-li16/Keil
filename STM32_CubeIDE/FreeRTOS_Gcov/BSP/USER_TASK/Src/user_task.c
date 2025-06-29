/*
 * user_task.c
 *
 *  Created on: Feb 26, 2025
 *      Author: 18283
 */
#include "FreeRTOS.h"
#include "task.h"
#include "cmsis_os.h"
#include "user_task.h"


void Task50ms(void *argument) 
{
#if (VTASKDELAYUNTIL == STD_ON)
    TickType_t xLastWakeTime = xTaskGetTickCount();
#endif
    const TickType_t xPeriod = pdMS_TO_TICKS(TASK50MS_DELAY);
    for(;;) 
    {

#if (VTASKDELAYUNTIL == STD_ON)
        osDelayUntil(&xLastWakeTime, xPeriod);
#else
        osDelay(xPeriod);
#endif
    }
}


void Task100ms(void *argument) 
{
#if (VTASKDELAYUNTIL == STD_ON)
    TickType_t xLastWakeTime = xTaskGetTickCount();
#endif
    const TickType_t xPeriod = pdMS_TO_TICKS(TASK100MS_DELAY);
    for(;;) 
    {
        // LOG_RELEASE("Task100ms\n");
        Led_Task();
#if (VTASKDELAYUNTIL == STD_ON)
        osDelayUntil(&xLastWakeTime, xPeriod);
#else
        osDelay(xPeriod);
#endif
    }
}

void Task1000ms(void *argument) 
{
#if (VTASKDELAYUNTIL == STD_ON)
    TickType_t xLastWakeTime = xTaskGetTickCount();
#endif
    const TickType_t xPeriod = pdMS_TO_TICKS(TASK1000MS_DELAY);
    for(;;) 
    {
#if defined(USE_BANK_A)
        LOG_RELEASE("Task1000ms in BankA 2\n");
#elif defined(USE_BANK_B)
        LOG_RELEASE("Task1000ms in BankB 2\n");
#else
        LOG_RELEASE("Task1000ms in default\n");
#endif
        LOG_RELEASE("Task1000ms in Normal\n");
        W25Q_ReadID_Test();
        // Led_Task();
#if (VTASKDELAYUNTIL == STD_ON)
        osDelayUntil(&xLastWakeTime, xPeriod);
#else
        osDelay(xPeriod);
#endif
    }
}
