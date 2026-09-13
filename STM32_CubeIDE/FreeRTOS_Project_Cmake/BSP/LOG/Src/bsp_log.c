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

#define LOG_TX_WAIT_TIMEOUT_MS 100u

/* A debugger halt (e.g. dt gdb) can kill an in-flight UART DMA transfer, so
 * HAL_UART_TxCpltCallback never runs and Log_Tx_En would stay OFF forever -
 * every logging task then spins here without any timeout and the log channel
 * looks dead while the tasks are still alive. Bound the wait and self-heal. */
static void Log_Wait_Tx_Idle(void)
{
    uint32_t t0 = HAL_GetTick();
    while (Log_Tx_En != STD_ON)
    {
        if ((HAL_GetTick() - t0) >= LOG_TX_WAIT_TIMEOUT_MS)
        {
            Log_Tx_En = STD_ON;
            break;
        }
    }
}

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

    Log_Wait_Tx_Idle();
    Log_Tx_En = STD_OFF;
    currentTime = HAL_GetTick();
    tsLen = snprintf(TxMsg, sizeof(TxMsg), "%010u", currentTime);
    msgLen = (uint32_t)vsnprintf(TxMsg + tsLen, sizeof(TxMsg) - tsLen, format, args);
    if ((int)msgLen < 0)
    {
        msgLen = 0;
    }
    totalLen = tsLen + msgLen;

    va_end(args);

    if (totalLen >= sizeof(TxMsg))
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

    Log_Wait_Tx_Idle();
    Log_Tx_En = STD_OFF;
    msgLen = (uint32_t)vsnprintf(TxMsg, sizeof(TxMsg), format, args);
    if ((int)msgLen < 0)
    {
        msgLen = 0;
    }
    totalLen = msgLen;

    va_end(args);

    if (totalLen >= sizeof(TxMsg))
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
 
