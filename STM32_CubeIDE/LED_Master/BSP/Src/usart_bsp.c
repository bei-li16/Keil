/*
 * usart_bsp.c
 *
 *  Created on: Feb 13, 2025
 *      Author: 18283
 */
#include "usart_bsp.h"
#include "usart.h"

void HAL_UART_TxCpltCallback(UART_HandleTypeDef *huart)
{

}

void HAL_UART_RxCpltCallback(UART_HandleTypeDef *huart)
{

}


//void Usart_SendString(USART_TypeDef * pUSARTx, char *str)
//{
//
//	HAL_StatusTypeDef HAL_UART_Transmit(UART_HandleTypeDef *huart, const uint8_t *pData, uint16_t Size, uint32_t Timeout);
//	unsigned int k=0;
//  do
//  {
//      Usart_SendByte( pUSARTx, *(str + k) );
//      k++;
//  } while(*(str + k)!='\0');
//
//  while(USART_GetFlagStatus(pUSARTx,USART_FLAG_TC)==RESET)
//  {}
//}

