/*
 * bsp_log.c
 *
 *  Created on: Feb 26, 2025
 *      Author: 18283
 */
#include "bsp_log.h"

static uint8_t Log_Tx_En = STD_ON;

char TxMsg[TX_MESSAGE_LEN];
char RxMsg[RX_MESSAGE_LEN];
char msg_log[MSGLOG_LEN];
MsgLog msg;

void Msg_Init(void)
{
    msg.msgptr = msg_log;
    msg.msglen = 0;
    msg.msghead = 0;
    msg.msgtail = 0;
    msg.emptylen = MSGLOG_LEN;
}

uint32_t DEBUG_PRINTF(const char *format, ...) {
    va_list args;
    va_start(args, format);

    uint8_t ret = 0;
    uint32_t tsLen = 0;
    uint32_t msgLen = 0;
    uint32_t totalLen = 0;
    uint32_t currentTime = 0;

    while(Log_Tx_En != STD_ON);
    Log_Tx_En = STD_OFF;
    currentTime = HAL_GetTick();
    tsLen = snprintf(TxMsg, sizeof(TxMsg), "%010u", currentTime);
    msgLen = vsnprintf(TxMsg+tsLen, sizeof(TxMsg), format, args);
    totalLen = tsLen + msgLen;

    va_end(args);

    if (totalLen == sizeof(TxMsg))
    {
        totalLen = sizeof(TxMsg) - 1;
    }
#if (MSG_PRINT_METHOD == PRINT_IMM)
#if (TRANSMIT_METHOD == POLLING)
    ret = HAL_UART_Transmit(TRANSMIT_COMPORT, (const uint8_t *)TxMsg, totalLen, TRANSMIT_TIMEOUT);
#elif (TRANSMIT_METHOD == DMA)
    ret = HAL_UART_Transmit_DMA(TRANSMIT_COMPORT, (const uint8_t *)TxMsg, totalLen);
#elif (TRANSMIT_METHOD == INTERRUPT)
    ret = HAL_UART_Transmit_IT(TRANSMIT_COMPORT, (const uint8_t *)TxMsg, totalLen);
#endif
#elif (MSG_PRINT_METHOD == PRINT_TASK)
    Msg_Copy(TxMsg, totalLen);
#endif
    return ((totalLen<< 2) | ret);
}

uint32_t SIMPLY_PRINTF(const char *format, ...) 
{
    va_list args;
    va_start(args, format);

    uint8_t ret = 0;
    uint32_t msgLen = 0;
    uint32_t totalLen = 0;

    while(Log_Tx_En != STD_ON);
    Log_Tx_En = STD_OFF;
    msgLen = vsnprintf(TxMsg, sizeof(TxMsg), format, args);
    totalLen = msgLen;

    va_end(args);

    if (totalLen == sizeof(TxMsg))
    {
        totalLen = sizeof(TxMsg) - 1;
    }

#if (MSG_PRINT_METHOD == PRINT_IMM)
#if (TRANSMIT_METHOD == POLLING)
    ret = HAL_UART_Transmit(TRANSMIT_COMPORT, (const uint8_t *)TxMsg, totalLen, TRANSMIT_TIMEOUT);
#elif (TRANSMIT_METHOD == DMA)
    ret = HAL_UART_Transmit_DMA(TRANSMIT_COMPORT, (const uint8_t *)TxMsg, totalLen);
#elif (TRANSMIT_METHOD == INTERRUPT)
    ret = HAL_UART_Transmit_IT(TRANSMIT_COMPORT, (const uint8_t *)TxMsg, totalLen);
#endif
#elif (MSG_PRINT_METHOD == PRINT_TASK)
    Msg_Copy(TxMsg, totalLen);
#endif
    return ((totalLen<< 2) | ret);
}

void Log_Init(void)
{
    Msg_Init();
    HAL_UARTEx_ReceiveToIdle_DMA(RECEIVE_COMPORT, RxMsg, RX_MESSAGE_LEN);
}


/********************* Interrupt Functions *********************/
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
        Log_Tx_En = STD_ON;
    }
}
 
