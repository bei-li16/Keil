/*
 * tools_bsp.c
 *
 *  Created on: Feb 15, 2025
 *      Author: 18283
 */
#include "tools_bsp.h"

char TxMsg[TX_MESSAGE_LEN];
char RxMsg[RX_MESSAGE_LEN];
char msg_log[MSGLOG_LEN];
uint8_t TxStatus = STD_ON;
MsgLog msg;

void Msg_Init(void)
{
	msg.msgptr = msg_log;
	msg.msglen = 0;
	msg.msghead = 0;
	msg.msgtail = 0;
	msg.emptylen = MSGLOG_LEN;
}
int i = 0;
void Msg_Copy(uint32_t SrcAddress, uint32_t DataLength)
{
	if(msg.emptylen >= DataLength)
	{
		if((MSGLOG_LEN - msg.msgtail) >= DataLength)
		{
			i = HAL_DMA_GetState(MEMCOPY_DMA);
			while(!(HAL_DMA_GetState(MEMCOPY_DMA)== HAL_DMA_STATE_READY));
			HAL_DMA_Start_IT(MEMCOPY_DMA, SrcAddress, msg.msgptr[msg.msgtail], DataLength);
			msg.msgtail += DataLength;
			msg.emptylen -= DataLength;
			msg.msglen += DataLength;
		}
		else
		{
			while(!(HAL_DMA_GetState(MEMCOPY_DMA)== HAL_DMA_STATE_READY));
			HAL_DMA_Start_IT(MEMCOPY_DMA, SrcAddress, msg.msgptr[msg.msgtail], (MSGLOG_LEN - msg.msgtail));
			msg.msgtail = (msg.msgtail + DataLength) % MSGLOG_LEN;
			while(!(HAL_DMA_GetState(MEMCOPY_DMA)== HAL_DMA_STATE_READY));
			HAL_DMA_Start_IT(MEMCOPY_DMA, SrcAddress + (MSGLOG_LEN - msg.msgtail), msg.msgptr[0], msg.msgtail);
			msg.emptylen -= DataLength;
			msg.msglen += DataLength;
		}
	}
	else
	{
		/* Not enough space. */
	}
}

void Msg_Send(void)
{
	if(msg.msglen > 0)
	{
		if(msg.msgtail > msg.msghead)
		{
			HAL_UART_Transmit_DMA(TRANSMIT_COMPORT, (const uint8_t *)msg.msgptr[msg.msghead], msg.msglen);
		}
		else
		{
			HAL_UART_Transmit_DMA(TRANSMIT_COMPORT, (const uint8_t *)msg.msgptr[msg.msghead], msg.msglen - msg.msghead);
			HAL_UART_Transmit_DMA(TRANSMIT_COMPORT, (const uint8_t *)msg.msgptr, msg.msgtail);
		}
		msg.msghead = msg.msgtail;
		msg.msglen = 0;
		msg.emptylen = MSGLOG_LEN;
	}
}

uint32_t DEBUG_PRINTF(const char *format, ...) {
    va_list args;
    va_start(args, format);

    uint8_t ret = 0;
    uint32_t tsLen = 0;
    uint32_t msgLen = 0;
    uint32_t totalLen = 0;

    uint32_t currentTime = 0;

    while(TxStatus != STD_ON);
    TxStatus = STD_OFF;
    currentTime = HAL_GetTick();
	tsLen = snprintf(TxMsg, sizeof(TxMsg), "%010u", currentTime);
	msgLen = vsnprintf(TxMsg+tsLen, sizeof(TxMsg), format, args);
	totalLen = tsLen + msgLen;

    va_end(args);

    if (totalLen == sizeof(TxMsg))
    {
    	totalLen = sizeof(TxMsg) - 1;
    }
//    while(!(HAL_UART_STATE_READY == HAL_UART_GetState(TRANSMIT_COMPORT)));
#if (MSG_PRINT_METHOD == PRINT_IMM)
#if (TRANSMIT_METHOD == POLLING)
    ret = HAL_UART_Transmit(TRANSMIT_COMPORT, (const uint8_t *)TxMsg, totalLen, TRANSMIT_TIMEOUT);
#elif (TRANSMIT_METHOD == DMA)
    ret = HAL_UART_Transmit_DMA(TRANSMIT_COMPORT, (const uint8_t *)TxMsg, totalLen);
#elif (TRANSMIT_METHOD == INTERRUPT)
//    while(!(HAL_UART_GetState(TRANSMIT_COMPORT)== HAL_UART_STATE_READY));
    ret = HAL_UART_Transmit_IT(TRANSMIT_COMPORT, (const uint8_t *)TxMsg, totalLen);
#endif
#elif (MSG_PRINT_METHOD == PRINT_TASK)
    Msg_Copy(TxMsg, totalLen);
#endif
    return ((totalLen<< 2) | ret);
}


void HAL_UARTEx_RxEventCallback(UART_HandleTypeDef *huart, uint16_t Size)
{
	if(RECEIVE_COMPORT == huart)
	{
		HAL_UART_Transmit_DMA(TRANSMIT_COMPORT, (const uint8_t *)RxMsg, Size);
		HAL_UARTEx_ReceiveToIdle_DMA(RECEIVE_COMPORT, RxMsg, RX_MESSAGE_LEN);
		__HAL_DMA_DISABLE_IT(RECEIVE_DMA, DMA_IT_HT);
	}
}

void HAL_UART_TxCpltCallback(UART_HandleTypeDef *huart)
{
	if(RECEIVE_COMPORT == huart)
	{
		TxStatus = STD_ON;
	}
}

