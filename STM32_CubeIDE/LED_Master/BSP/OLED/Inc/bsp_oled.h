/*
 * bsp_oled.h
 *
 *  Created on: Feb 19, 2025
 *      Author: 18283
 */

#ifndef OLED_INC_BSP_OLED_H_
#define OLED_INC_BSP_OLED_H_

#include "gpio.h"
#include "spi.h"

//OLED模式设置
//0:4线串行模式
//1:并行8080模式
#define 			OLED_MODE 							0
#define 			SIZE 								16	
#define 			XLevelL								0x00
#define 			XLevelH								0x10
#define 			Max_Column							128
#define 			Max_Row								64
#define				Brightness							0xFF 
#define 			X_WIDTH 							128
#define 			Y_WIDTH 							64

#define 	        STD_ON 				                1
#define 	        STD_OFF 			                0
#define             VIRTUAL_SPI 						STD_OFF	//写命令

/*-----------------OLED端口定义----------------*/ 					   

//#define 			OLED_SCLK_Clr()					GPIO_ResetBits(GPIOA,GPIO_Pin_1)//CLK
//#define 			OLED_SCLK_Set() 				GPIO_SetBits(GPIOA,GPIO_Pin_1)
//
//#define 			OLED_SDIN_Clr()		 			GPIO_ResetBits(GPIOA,GPIO_Pin_2)//DIN
//#define 			OLED_SDIN_Set() 				GPIO_SetBits(GPIOA,GPIO_Pin_2)
//
//#define 			OLED_RST_Clr() 					GPIO_ResetBits(GPIOA,GPIO_Pin_3)//RES
//#define 			OLED_RST_Set() 					GPIO_SetBits(GPIOA,GPIO_Pin_3)
//
//#define 			OLED_DC_Clr() 					GPIO_ResetBits(GPIOA,GPIO_Pin_4)//DC
//#define 			OLED_DC_Set() 					GPIO_SetBits(GPIOA,GPIO_Pin_4)
//
//#define 			OLED_CS_Clr() 		 			GPIO_ResetBits(GPIOA,GPIO_Pin_9)//CS
//#define 			OLED_CS_Set()  					GPIO_SetBits(GPIOA,GPIO_Pin_9)

// #define 			OLED_SCLK_Clr()					HAL_GPIO_WritePin(LED_RED_GPIO_Port, LED_RED_Pin, GPIO_PIN_RESET);
// #define 			OLED_SCLK_Set() 				GPIO_SetBits(GPIOA,GPIO_Pin_1)

// #define 			OLED_SDIN_Clr()		 			GPIO_ResetBits(GPIOA,GPIO_Pin_2)//DIN
// #define 			OLED_SDIN_Set() 				GPIO_SetBits(GPIOA,GPIO_Pin_2)

#define 			OLED_RST_Clr() 					HAL_GPIO_WritePin(OLED_RESET_GPIO_Port, OLED_RESET_Pin, GPIO_PIN_RESET)//RES
#define 			OLED_RST_Set() 					HAL_GPIO_WritePin(OLED_RESET_GPIO_Port, OLED_RESET_Pin, GPIO_PIN_SET)

#define 			OLED_DC_Clr() 					HAL_GPIO_WritePin(OLED_DC_GPIO_Port, OLED_DC_Pin, GPIO_PIN_RESET)//DC
#define 			OLED_DC_Set() 					HAL_GPIO_WritePin(OLED_DC_GPIO_Port, OLED_DC_Pin, GPIO_PIN_SET)
 		     
#define 			OLED_CS_Clr() 		 			HAL_GPIO_WritePin(OLED_CS_GPIO_Port, OLED_CS_Pin, GPIO_PIN_RESET)//CS
#define 			OLED_CS_Set()  					HAL_GPIO_WritePin(OLED_CS_GPIO_Port, OLED_CS_Pin, GPIO_PIN_SET)

#define 			OLED_CMD	 					0	//write command
#define 			OLED_DATA 						1	//wrtie data


//OLED control functions
void OLED_WR_Byte(uint8_t dat,uint8_t cmd);
void OLED_Display_On(void);
void OLED_Display_Off(void);	   							   		    
void OLED_Init(void);
void OLED_Clear(void);
void OLED_DrawPoint(uint8_t x,uint8_t y,uint8_t t);
void OLED_Fill(uint8_t x1,uint8_t y1,uint8_t x2,uint8_t y2,uint8_t dot);
void OLED_ShowChar(uint8_t x,uint8_t y,uint8_t chr);
void OLED_ShowNum(uint8_t x,uint8_t y,uint32_t num,uint8_t len,uint8_t size);
void OLED_ShowString(uint8_t x,uint8_t y, uint8_t *p);
void OLED_Set_Pos(uint8_t x, uint8_t y);
void OLED_ShowCHinese(uint8_t x,uint8_t y,uint8_t no);
void OLED_DrawBMP(uint8_t x0, uint8_t y0,uint8_t x1, uint8_t y1,uint8_t BMP[]);

#endif /* OLED_INC_BSP_OLED_H_ */
