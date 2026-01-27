/*
 * bsp_led.h
 *
 *  Created on: Feb 25, 2025
 *      Author: 18283
 */
#ifndef INC_BSP_LED_H_
#define INC_BSP_LED_H_

#include "gpio.h"

extern void Led_RedFlip(void);
extern void Led_RedON(void);
extern void Led_RedOFF(void);

extern void Led_Init(void);
extern void Led_Task(void);
 
#endif /* INC_BSP_LED_H_ */