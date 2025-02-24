/*
 * bsp_tower.c
 *
 *  Created on: Feb 24, 2025
 *      Author: 18283
 */
#include "bsp_tower.h"

void Tower_Init(void)
{
    HAL_TIM_PWM_Start(TIM_TOWER_PORT, TIM_TOWER_CHANNEL);
}

void Tower_SetToZero(void)
{
    __HAL_TIM_SET_COMPARE(TIM_TOWER_PORT, TIM_TOWER_CHANNEL, TIM_TOWER_PWM_0DEGREE);
}

void Tower_SetTo90(void)
{
    __HAL_TIM_SET_COMPARE(TIM_TOWER_PORT, TIM_TOWER_CHANNEL, TIM_TOWER_PWM_90DEGREE);
}

void Tower_SetTo180(void)
{
    __HAL_TIM_SET_COMPARE(TIM_TOWER_PORT, TIM_TOWER_CHANNEL, TIM_TOWER_PWM_180DEGREE);
}

void Tower_Around_Test(void)
{
    LOG_RELEASE("--------------Tower around test Begin------------\n");
    LOG_RELEASE("Tower Set to 0 degree\n");
    Tower_SetToZero();
    HAL_Delay(TOWER_TEST_DELAY);
    LOG_RELEASE("Tower Set to 90 degree\n");
    Tower_SetTo90();
    HAL_Delay(TOWER_TEST_DELAY);
    LOG_RELEASE("Tower Set to 180 degree\n");
    Tower_SetTo180();
    HAL_Delay(TOWER_TEST_DELAY);
    LOG_RELEASE("Tower Set to 90 degree\n");
    Tower_SetTo90();
    HAL_Delay(TOWER_TEST_DELAY);
    LOG_RELEASE("Tower Set to 0 degree\n");
    Tower_SetToZero();
    LOG_RELEASE("--------------Tower around test End--------------\n");
    HAL_Delay(TOWER_TEST_DELAY);
}

void Tower_GreenLed_Test(void)
{
    LOG_RELEASE("--------------Tower&Led around test Begin------------\n");
    for(int i = 0; i < TOWER_LED_TEST_STEP; i++)
    {
        __HAL_TIM_SET_COMPARE(TIM_TOWER_PORT, TIM_TOWER_CHANNEL, TIM_TOWER_PWM_0DEGREE + i * TOWER_LED_TEST_STEPLEN);
        HAL_Delay(TOWER_LED_TEST_DELAY);
    }
    LOG_RELEASE("--------------Tower&Led around test End--------------\n");
}

void GreenLed_Test(void)
{
    LOG_RELEASE("--------------Led around test Begin------------\n");
    for(int i = 0; i < LED_TEST_STEP; i++)
    {
        __HAL_TIM_SET_COMPARE(TIM_TOWER_PORT, TIM_TOWER_CHANNEL, i * LED_TEST_STEPLEN);
        HAL_Delay(LED_TEST_DELAY);
    }
    for(int i = 0; i < LED_TEST_STEP; i++)
    {
        __HAL_TIM_SET_COMPARE(TIM_TOWER_PORT, TIM_TOWER_CHANNEL, TIM_TOWER_PWM_PERIOD - i * LED_TEST_STEPLEN);
        HAL_Delay(LED_TEST_DELAY);
    }
    LOG_RELEASE("--------------Led around test End--------------\n");
}
