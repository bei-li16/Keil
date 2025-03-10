/* USER CODE BEGIN Header */
/**
  ******************************************************************************
  * @file           : main.h
  * @brief          : Header for main.c file.
  *                   This file contains the common defines of the application.
  ******************************************************************************
  * @attention
  *
  * Copyright (c) 2025 STMicroelectronics.
  * All rights reserved.
  *
  * This software is licensed under terms that can be found in the LICENSE file
  * in the root directory of this software component.
  * If no LICENSE file comes with this software, it is provided AS-IS.
  *
  ******************************************************************************
  */
/* USER CODE END Header */

/* Define to prevent recursive inclusion -------------------------------------*/
#ifndef __MAIN_H
#define __MAIN_H

#ifdef __cplusplus
extern "C" {
#endif

/* Includes ------------------------------------------------------------------*/
#include "stm32f4xx_hal.h"

/* Private includes ----------------------------------------------------------*/
/* USER CODE BEGIN Includes */

/* USER CODE END Includes */

/* Exported types ------------------------------------------------------------*/
/* USER CODE BEGIN ET */

/* USER CODE END ET */

/* Exported constants --------------------------------------------------------*/
/* USER CODE BEGIN EC */

/* USER CODE END EC */

/* Exported macro ------------------------------------------------------------*/
/* USER CODE BEGIN EM */

/* USER CODE END EM */

/* Exported functions prototypes ---------------------------------------------*/
void Error_Handler(void);

/* USER CODE BEGIN EFP */

/* USER CODE END EFP */

/* Private defines -----------------------------------------------------------*/
#define Print_COM huart1
#define OLED_SPI hspi1
#define LCD_SPI hspi2
#define KEY2_Pin GPIO_PIN_13
#define KEY2_GPIO_Port GPIOC
#define KEY2_EXTI_IRQn EXTI15_10_IRQn
#define LCD_SDA_SM_Pin GPIO_PIN_0
#define LCD_SDA_SM_GPIO_Port GPIOC
#define OLED_RESET_Pin GPIO_PIN_4
#define OLED_RESET_GPIO_Port GPIOA
#define OLED_DC_Pin GPIO_PIN_10
#define OLED_DC_GPIO_Port GPIOB
#define OLED_CS_Pin GPIO_PIN_11
#define OLED_CS_GPIO_Port GPIOB
#define LED_RED_Pin GPIO_PIN_10
#define LED_RED_GPIO_Port GPIOH
#define LED_GREEN_Pin GPIO_PIN_11
#define LED_GREEN_GPIO_Port GPIOH
#define LED_BLUE_Pin GPIO_PIN_12
#define LED_BLUE_GPIO_Port GPIOH
#define LCD_RS_Pin GPIO_PIN_12
#define LCD_RS_GPIO_Port GPIOB
#define LCD_LED_Pin GPIO_PIN_14
#define LCD_LED_GPIO_Port GPIOB
#define LCD_RESET_Pin GPIO_PIN_6
#define LCD_RESET_GPIO_Port GPIOC
#define LCD_CS_Pin GPIO_PIN_8
#define LCD_CS_GPIO_Port GPIOC
#define USBUART_TX_Pin GPIO_PIN_9
#define USBUART_TX_GPIO_Port GPIOA
#define USBUART_RX_Pin GPIO_PIN_10
#define USBUART_RX_GPIO_Port GPIOA
#define LCD_SCK_SM_Pin GPIO_PIN_5
#define LCD_SCK_SM_GPIO_Port GPIOB

/* USER CODE BEGIN Private defines */

/* USER CODE END Private defines */

#ifdef __cplusplus
}
#endif

#endif /* __MAIN_H */
