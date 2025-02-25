/*
 * bsp_oled.h
 *
 *  Created on: Feb 25, 2025
 *      Author: 18283
 */

#ifndef OLED_INC_BSP_OLED_H_
#define OLED_INC_BSP_OLED_H_

#include "gpio.h"
#include "spi.h"
#include "Lcd_Driver.h"
#include "bsp_oledbmp.h"
 #include "bsp_oledfont.h"

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
#define             OLED_VIRTUAL_SPI 					VIRTUAL_SPI_LCD	//写命令

/*-----------------OLED端口定义----------------*/ 					   

#define 			OLED_DC_Clr()                       LCD_RS_CLR 				
#define 			OLED_DC_Set()                       LCD_RS_SET 					  
#define 			OLED_RST_Set()                      LCD_RST_SET 		 	
#define 			OLED_RST_Clr()                      LCD_RST_CLR  		
#define 			OLED_CS_Set()                       LCD_CS_SET 		
#define 			OLED_CS_Clr()                       LCD_CS_CLR

#define             OLED_TRANSMIT_BYTE(data)            SPI_WriteData(data)

#define 			OLED_CMD	 					    0	//write command
#define 			OLED_DATA 						    1	//wrtie data


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
void OLED_Display(void);

#endif /* OLED_INC_BSP_OLED_H_ */
