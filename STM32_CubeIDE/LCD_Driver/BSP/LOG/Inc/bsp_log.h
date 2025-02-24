/*
 * bsp_log.h
 *
 *  Created on: Feb 23, 2025
 *      Author: 18283
 */

#ifndef LOG_INC_BSP_LOG_H_
#define LOG_INC_BSP_LOG_H_

#include <stdarg.h>
#include <stdio.h>
#include "usart.h"
#include "dma.h"

#define 	STD_ON 				1
#define 	STD_OFF 			0
#define 	POLLING 			1
#define 	DMA 				2
#define 	INTERRUPT 			3
#define 	TRANSMIT_METHOD 	DMA
#define 	TRANSMIT_TIMEOUT 	0xFFFFFF
#define 	TRANSMIT_COMPORT 	&LOG_COM
#define 	RECEIVE_COMPORT 	&LOG_COM
#define 	RX_MESSAGE_LEN 		256
#define 	TX_MESSAGE_LEN 		256
#define 	MSGLOG_LEN 		    1514
#define 	PRINT_IMM			1
#define 	PRINT_TASK			2
#define 	MSG_PRINT_METHOD	PRINT_IMM



extern  uint32_t DEBUG_PRINTF(const char *format, ...);
extern  DMA_HandleTypeDef hdma_usart1_rx;
extern  DMA_HandleTypeDef hdma_usart1_tx;

#define 	RECEIVE_DMA 		    &hdma_usart1_rx
#define 	TRANSMIT_DMA 		    &hdma_usart1_tx
#define     LOG_DEBUG(fmt, ...) 	DEBUG_PRINTF("|[DEBUG]|" fmt, ##__VA_ARGS__)
#define     LOG_WARN(fmt, ...) 		DEBUG_PRINTF("|[WARN]|" fmt, ##__VA_ARGS__)
#define     LOG_RELEASE(fmt, ...) 	DEBUG_PRINTF("|[RELEASE]|" fmt, ##__VA_ARGS__)
#define     LOG_INFO(fmt, ...) 		SIMPLY_PRINTF(fmt, ##__VA_ARGS__)



typedef struct {
	char* msgptr;
	uint16_t msglen;
	uint16_t msghead;
	uint16_t msgtail;
	uint16_t emptylen;
}MsgLog;

extern char TxMsg[TX_MESSAGE_LEN];
extern char RxMsg[RX_MESSAGE_LEN];

extern MsgLog msg;
extern void Msg_Init(void);

#endif /* LOG_INC_BSP_LOG_H_ */
