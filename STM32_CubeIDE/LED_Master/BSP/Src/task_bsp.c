/*
 * task_bsp.c
 *
 *  Created on: Feb 16, 2025
 *      Author: 18283
 */
#include "task_bsp.h"
#include "bsp_bmp.h"
#include "Lcd_bmp.h"

volatile uint32_t Task_Cmd;

void Led_task(void)
{
	Led_RedFlip();
}

void OLED_task(void)
{
	static uint8_t t = 0;
	OLED_Clear();
	OLED_ShowCHinese(0,0,0);//zhong
	OLED_ShowCHinese(18,0,1);//jing
	OLED_ShowCHinese(36,0,2);//yuan
	OLED_ShowCHinese(54,0,3);//dian
	OLED_ShowCHinese(72,0,4);//zi
	OLED_ShowCHinese(90,0,5);//ke
	OLED_ShowCHinese(108,0,6);//ji
	OLED_ShowString(0,2,"0.96' OLED TEST");
	OLED_ShowString(0,4,"0123456789ABCDEF");
	OLED_ShowString(0,6,"ASCII:");
	OLED_ShowString(63,6,"CODE:");
	OLED_ShowChar(48,6,t);//display ASCII code
	t++;
	if(t>'~')t=' ';
	OLED_ShowNum(103,6,t,3,16);//display ASCII code

	HAL_Delay(200);
	OLED_Clear();
	HAL_Delay(200);
	OLED_DrawBMP(0,0,128,8,BMP1);  //Picture display
	HAL_Delay(200);
	OLED_DrawBMP(0,0,128,8,BMP2);
	HAL_Delay(200);
	HAL_Delay(200);
}

void Lcd_Task(void)
{
//	LCD_DrawBMP_8BIT(gImage_clannad);
//	delay_ms(1000);
//	LCD_DrawBMP_16BIT(gImage_SunshineGirl);
//	delay_ms(1000);
	// LCD_DrawBMP_BAPBIT(gImage_BadApple);
	LCD_DrawBMP_BAPBIT(Image_BadApple);
	delay_ms(1000);
	// // Gui_DrawPoint(2,2, 0x0050); 
	// uint8_t Data = 0xAB;
	// uint8_t *pData = &Data;
	// extern uint8_t TxStatus;
	// while(TxStatus != STD_ON);
    // TxStatus = STD_OFF;
	// HAL_UART_Transmit_DMA(TRANSMIT_COMPORT, pData, 1);
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

extern uint32_t SPI_Tx_Cpt;
extern uint32_t LCD_Tx_Cpt;
void Task_500ms_Entry(void)
{
	LOG_RELEASE("This is a 500ms message\n");
	// LOG_RELEASE("SPI Tx Cpt: %d.\n", SPI_Tx_Cpt);
	// LOG_RELEASE("LCD Tx Cpt: %d.\n", LCD_Tx_Cpt);
	// OLED_task();
	Lcd_Task();
	RESET_500MS_TASK;
	LOG_RELEASE("Log1 %d.\n", timestamp1ms);
	HAL_Delay(500);
	LOG_RELEASE("Log2 %d.\n", timestamp1ms);
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
	// OLED_Init();
	Lcd_Init();
	LCD_LED_SET;
	Lcd_Clear(BLACK);
//	Lcd_Clear(WHITE);
	HAL_Delay(500);
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
