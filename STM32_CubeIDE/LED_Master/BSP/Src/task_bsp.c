/*
 * task_bsp.c
 *
 *  Created on: Feb 16, 2025
 *      Author: 18283
 */
#include "task_bsp.h"

volatile uint32_t Task_Cmd;

void Led_task(void)
{
	Led_RedFlip();
}

void Task_1ms_Entry(void)
{
	LOG_RELEASE("This is a 1ms message\n");
	RESET_1MS_TASK;
}

void Task_5ms_Entry(void)
{
	LOG_RELEASE("This is a 5ms message\n");
	RESET_5MS_TASK;
}

void Task_10ms_Entry(void)
{
	LOG_RELEASE("This is a 10ms message\n");
	RESET_10MS_TASK;
}

void Task_50ms_Entry(void)
{
	LOG_RELEASE("This is a 50ms message\n");
	RESET_50MS_TASK;
}

void Task_100ms_Entry(void)
{
	LOG_RELEASE("This is a 100ms message\n");
	RESET_100MS_TASK;
}

void Task_500ms_Entry(void)
{
	LOG_RELEASE("This is a 500ms message\n");
	RESET_500MS_TASK;
}

void Task_1000ms_Entry(void)
{
	LOG_RELEASE("This is a 1000ms message\n");
	Led_task();
	Bsp_AdcValuePrint();
	RESET_1000MS_TASK;
}

void OS_Init(void)
{
	Msg_Init();
	HAL_TIM_Base_Start_IT(PRINT_TIMER);
	HAL_TIM_Base_Start_IT(GLOBAL_TIMER);
	HAL_UARTEx_ReceiveToIdle_DMA(RECEIVE_COMPORT, RxMsg, RX_MESSAGE_LEN);
	Bsp_AdcStart();
}

void Start_OS(void)
{
	while(1)
	{
		if(GET_1MS_TASK)
		{
			Task_1ms_Entry();
		}
		if(GET_5MS_TASK)
		{
			Task_5ms_Entry();
		}
		if(GET_10MS_TASK)
		{
			Task_10ms_Entry();
		}
		if(GET_50MS_TASK)
		{
			Task_50ms_Entry();
		}
		if(GET_100MS_TASK)
		{
			Task_100ms_Entry();
		}
		if(GET_500MS_TASK)
		{
			Task_500ms_Entry();
		}
		if(GET_1000MS_TASK)
		{
			Task_1000ms_Entry();
		}
	}
}
