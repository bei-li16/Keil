/*
 * bsp_adc.c
 *
 *  Created on: Feb 17, 2025
 *      Author: 18283
 */
#include "bsp_adc.h"

uint32_t AdcValue[2] = {0};
uint16_t AdcValueGroup[4] = {0};

void Bsp_AdcStart(void)
{
//	HAL_ADC_Start(&hadc1);
//	HAL_ADC_Start(&hadc3);
	HAL_ADC_Start_DMA(&hadc1, (uint32_t*)AdcValueGroup, 4);
}

void Bsp_AdcValuePrint(void)
{
//	AdcValue[0] = HAL_ADC_GetValue(&hadc1);
//	AdcValue[1] = HAL_ADC_GetValue(&hadc3);
//	LOG_RELEASE("ADC1 Value is %d V\n", AdcValue[0]);
//	LOG_RELEASE("ADC3 Value is %d V\n", AdcValue[1]);
//	LOG_RELEASE("ADC1 Value is %.2f V\n", (float)((AdcValue[0] / 4095.0) * 3.3));
//	LOG_RELEASE("ADC3 Value is %.2f V\n", (float)((AdcValue[1] / 4095.0) * 3.3));
	LOG_RELEASE("ADC1 Value is %d %d %d %d V\n", AdcValueGroup[0], AdcValueGroup[1], AdcValueGroup[2], AdcValueGroup[3]);
//	LOG_RELEASE("cpt %d.\n", AdcValue[0]);
}

void HAL_ADC_ConvCpltCallback(ADC_HandleTypeDef *hadc)
{
	if(&hadc1 == hadc)
	{
//		AdcValue[0] += 1;
	}
}
