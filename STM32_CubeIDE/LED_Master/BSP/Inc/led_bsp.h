/*
 * led_bsp.h
 *
 *  Created on: Feb 13, 2025
 *      Author: 18283
 */

#ifndef INC_LED_BSP_H_
#define INC_LED_BSP_H_

#include "gpio.h"

extern void Led_RedFlip(void);
extern void Led_GreenFlip(void);
extern void Led_BlueFlip(void);

extern void Led_RedON(void);
extern void Led_RedOFF(void);
extern void Led_GreenON(void);
extern void Led_GreenOFF(void);
extern void Led_BlueON(void);
extern void Led_BlueOFF(void);

#endif /* INC_LED_BSP_H_ */
