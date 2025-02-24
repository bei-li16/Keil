/*
 * bsp_tower.h
 *
 *  Created on: Feb 24, 2025
 *      Author: 18283
 */

#ifndef PWM_INC_BSP_TOWER_H_
#define PWM_INC_BSP_TOWER_H_

#include "tim.h"
#include "bsp_log.h"

#define     TIM_TOWER_PORT      &htim5
#define     TIM_TOWER_CHANNEL   TIM_CHANNEL_2

#define     TIM_TOWER_PWM_PERIOD        2000
#define     TIM_TOWER_PWM_180DEGREE     ((TIM_TOWER_PWM_PERIOD * 125) / 1000)
#define     TIM_TOWER_PWM_90DEGREE      ((TIM_TOWER_PWM_PERIOD * 75) / 1000)
#define     TIM_TOWER_PWM_0DEGREE       ((TIM_TOWER_PWM_PERIOD * 25) / 1000)

#define     TOWER_TEST_DELAY            10000
#define     TOWER_LED_TEST_DELAY        50
#define     TOWER_LED_TEST_STEPLEN      10
#define     TOWER_LED_TEST_STEP         ((TIM_TOWER_PWM_180DEGREE - TIM_TOWER_PWM_0DEGREE) / TOWER_LED_TEST_STEPLEN)

#define     LED_TEST_DELAY              50
#define     LED_TEST_STEPLEN            10
#define     LED_TEST_STEP               ((TIM_TOWER_PWM_PERIOD - 1) / LED_TEST_STEPLEN)


extern void Tower_Init(void);
extern void Tower_SetToZero(void);
extern void Tower_SetTo90(void);
extern void Tower_SetTo180(void);
extern void Tower_Around_Test(void);
extern void Tower_GreenLed_Test(void);
extern void GreenLed_Test(void);

#endif /* PWM_INC_BSP_TOWER_H_ */
