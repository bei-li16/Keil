/*
 * bsp_led.h
 *
 *  Created on: Feb 25, 2025
 *      Author: 18283
 */
#ifndef INC_BSP_LED_H_
#define INC_BSP_LED_H_

#include "gpio.h"

#define         LED_RED_ON          HAL_GPIO_WritePin(LED_RED_GPIO_Port, LED_RED_Pin, GPIO_PIN_RESET)
#define         LED_RED_OFF         HAL_GPIO_WritePin(LED_RED_GPIO_Port, LED_RED_Pin, GPIO_PIN_SET)
#define         LED_RED_TOGGLE      HAL_GPIO_TogglePin(LED_RED_GPIO_Port, LED_RED_Pin)

#define         LED_GREEN_ON        HAL_GPIO_WritePin(LED_GREEN_GPIO_Port, LED_GREEN_Pin, GPIO_PIN_RESET)
#define         LED_GREEN_OFF       HAL_GPIO_WritePin(LED_GREEN_GPIO_Port, LED_GREEN_Pin, GPIO_PIN_SET)
#define         LED_GREEN_TOGGLE    HAL_GPIO_TogglePin(LED_GREEN_GPIO_Port, LED_GREEN_Pin)

#define         LED_BLUE_ON         HAL_GPIO_WritePin(LED_BLUE_GPIO_Port, LED_BLUE_Pin, GPIO_PIN_RESET)
#define         LED_BLUE_OFF        HAL_GPIO_WritePin(LED_BLUE_GPIO_Port, LED_BLUE_Pin, GPIO_PIN_SET)
#define         LED_BLUE_TOGGLE     HAL_GPIO_TogglePin(LED_BLUE_GPIO_Port, LED_BLUE_Pin)


extern void Led_Init(void);
extern void Led_Task(void);
 
#endif /* INC_BSP_LED_H_ */