/*
 * usart_bsp.h
 *
 *  Created on: Feb 13, 2025
 *      Author: 18283
 */

#ifndef INC_USART_BSP_H_
#define INC_USART_BSP_H_
#include "usart.h"

extern void HAL_UART_TxCpltCallback(UART_HandleTypeDef *huart);
//extern void Usart_SendString(USART_TypeDef * pUSARTx, char *str);

#endif /* INC_USART_BSP_H_ */
