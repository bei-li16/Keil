/*
 * task_bsp.c
 *
 *  Created on: Feb 16, 2025
 *      Author: 18283
 */
#include "task_bsp.h"

volatile uint32_t Task_Cmd;

void Task_1ms_Entry(void)
{
	// LOG_RELEASE("This is a 1ms message\n");
	RESET_1MS_TASK;
}

void Task_5ms_Entry(void)
{
	// LOG_RELEASE("This is a 5ms message\n");
	RESET_5MS_TASK;
}

void Task_10ms_Entry(void)
{
	// LOG_RELEASE("This is a 10ms message\n");
	RESET_10MS_TASK;
}

void Task_50ms_Entry(void)
{
	// LOG_RELEASE("This is a 50ms message\n");
	RESET_50MS_TASK;
}

void Task_100ms_Entry(void)
{
	// LOG_RELEASE("This is a 100ms message\n");
	RESET_100MS_TASK;
}

void Task_500ms_Entry(void)
{
	LOG_RELEASE("This is a 500ms message\n");
	// I2C_Test_2Byte();
	// I2C_Test_TwoByte();
	// uint8_t tsLen = snprintf(Tx500Msg, sizeof(Tx500Msg), "%010u\n", OS_Tick1ms);
	// HAL_DMA_Start_IT(&hdma_memtomem_dma2_stream0, Tx500Msg, Tx500MsgReal, tsLen);
	// DMA2_Stream0_TxStatus = 0;
	// while(DMA2_Stream0_TxStatus != 1);
	// HAL_UART_Transmit_DMA(&LOG_COM, (const uint8_t *)Tx500MsgReal, 12);
	// LOG_RELEASE("SPI Tx Cpt: %d.\n", SPI_Tx_Cpt);
	// LOG_RELEASE("LCD Tx Cpt: %d.\n", LCD_Tx_Cpt);
	// OLED_task();
	Lcd_Display();
	// OLED_Display();
	RESET_500MS_TASK;
}

uint8_t ret0 = 0;
void Task_1000ms_Entry(void)
{
	LOG_RELEASE("This is a 1000ms message\n");
	// LOG_RELEASE("OS_Tick: %d.\n", OS_Tick1ms);
	// I2C_Test1();
	// Tower_Around_Test();
	// Tower_GreenLed_Test();
	// GreenLed_Test();
	// Led_task();
	// Bsp_AdcValuePrint();
	RESET_1000MS_TASK;
}

void OS_Init(void)
{
	HAL_TIM_Base_Start_IT(OS_TICK_TIMER);
	HAL_UARTEx_ReceiveToIdle_DMA(RECEIVE_COMPORT, RxMsg, RX_MESSAGE_LEN);
	Tower_Init();
	// Bsp_AdcStart();
	Lcd_Init();
	// OLED_Init();
	// HAL_Delay(500);
	SET_1000MS_TASK;
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
