/*
 * Lcd_Driver.h
 *
 *  Created on: Feb 20, 2025
 *      Author: 18283
 */

#ifndef LCD_INC_LCD_DRIVER_H_
#define LCD_INC_LCD_DRIVER_H_

#include "gpio.h"
#include "spi.h"

#define X_MAX_PIXEL	        128
#define Y_MAX_PIXEL	        128

#define RED  		        0xf800
#define GREEN		        0x07e0
#define BLUE 		        0x001f
#define WHITE		        0xffff
#define BLACK		        0x0000
#define YELLOW              0xFFE0
#define GRAY0               0xEF7D   			//灰色0 3165 00110 001011 00101
#define GRAY1               0x8410      	    //灰色1      00000 000000 00000
#define GRAY2               0x4208      	    //灰色2  1111111111011111

#define 	        LCD_SPI 	                        hspi1
#define 	        STD_ON 				                1
#define 	        STD_OFF 			                0
#define             VIRTUAL_SPI_LCD 					STD_OFF	//use SPI or GPIO to drive LCD
#define             SPI_TRANSMIT_DMA 			        STD_OFF
#define             SPI_TRANSMIT_IT 			        STD_OFF
#define             SPI_TRANSMIT_IM 			        STD_ON

#if (VIRTUAL_SPI_LCD == STD_ON)

#define 			LCD_SCL_CLR 					HAL_GPIO_WritePin(LCD_SCL_GPIO_Port, LCD_SCL_Pin, GPIO_PIN_RESET)
#define 			LCD_SCL_SET 					HAL_GPIO_WritePin(LCD_SCL_GPIO_Port, LCD_SCL_Pin, GPIO_PIN_SET)
#define 			LCD_SDA_CLR 					HAL_GPIO_WritePin(LCD_SDA_GPIO_Port, LCD_SDA_Pin, GPIO_PIN_RESET)
#define 			LCD_SDA_SET 					HAL_GPIO_WritePin(LCD_SDA_GPIO_Port, LCD_SDA_Pin, GPIO_PIN_SET)

#endif

#define 			LCD_LED_CLR 					HAL_GPIO_WritePin(LCD_LED_GPIO_Port, LCD_LED_Pin, GPIO_PIN_RESET)
#define 			LCD_LED_SET 					HAL_GPIO_WritePin(LCD_LED_GPIO_Port, LCD_LED_Pin, GPIO_PIN_SET)
#define 			LCD_RS_CLR 					    HAL_GPIO_WritePin(LCD_RS_GPIO_Port, LCD_RS_Pin, GPIO_PIN_RESET)
#define 			LCD_RS_SET 					    HAL_GPIO_WritePin(LCD_RS_GPIO_Port, LCD_RS_Pin, GPIO_PIN_SET)
#define 			LCD_RST_SET 		 			HAL_GPIO_WritePin(LCD_RST_GPIO_Port, LCD_RST_Pin, GPIO_PIN_SET)
#define 			LCD_RST_CLR  					HAL_GPIO_WritePin(LCD_RST_GPIO_Port, LCD_RST_Pin, GPIO_PIN_RESET)
#define 			LCD_CS_SET 		 			    HAL_GPIO_WritePin(LCD_CS_GPIO_Port, LCD_CS_Pin, GPIO_PIN_SET)
#define 			LCD_CS_CLR  					HAL_GPIO_WritePin(LCD_CS_GPIO_Port, LCD_CS_Pin, GPIO_PIN_RESET)


// void LCD_GPIO_Init(void);
void SPI_WriteData(uint8_t Data);
void Lcd_WriteIndex(uint8_t Index);
void Lcd_WriteData(uint8_t Data);
void Lcd_WriteReg(uint8_t Index,uint8_t Data);
uint16_t Lcd_ReadReg(uint8_t LCD_Reg);
void Lcd_Reset(void);
void Lcd_Init(void);
void Lcd_Clear(uint16_t Color);
void Lcd_SetXY(uint16_t x,uint16_t y);
void Gui_DrawPoint(uint16_t x,uint16_t y,uint16_t Data);
unsigned int Lcd_ReadPoint(uint16_t x,uint16_t y);
void Lcd_SetRegion(uint16_t x_start,uint16_t y_start,uint16_t x_end,uint16_t y_end);
void LCD_WriteData_16Bit(uint16_t Data);

//add
void LCD_DrawBMP_8BIT(const unsigned char *p);
void LCD_DrawBMP_16BIT(const unsigned short *p);
void LCD_DrawBMP_BAPBIT(const unsigned short *p);

void Lcd_Display(void);
//end

#endif /* LCD_INC_LCD_DRIVER_H_ */
