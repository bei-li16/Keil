/*
 * SEGGER_RTT.h - 精简版 SEGGER RTT(仅保留上行写)
 *
 * 控制块结构与 SEGGER 官方定义逐字段一致,J-Link 工具(RTT Viewer /
 * JLinkRTTLogger)按 "SEGGER RTT" ID 扫描 RAM 即可自动识别。
 * 只需通道 0 的上行方向,缓冲大小可按需调整(必须为 2 的幂)。
 */
#ifndef SEGGER_RTT_H
#define SEGGER_RTT_H

#include <stdint.h>

#define SEGGER_RTT_MAX_NUM_UP_BUFFERS    (1)
#define SEGGER_RTT_MAX_NUM_DOWN_BUFFERS  (1)
#define SEGGER_RTT_BUFFER_SIZE_UP        (8192)   /* 2 的幂;大 blob 调这里 */
#define SEGGER_RTT_BUFFER_SIZE_DOWN      (16)

/* 工作模式 */
#define SEGGER_RTT_MODE_NO_BLOCK_SKIP    (0)      /* 满则丢弃,不阻塞 */
#define SEGGER_RTT_MODE_NO_BLOCK_TRIM    (1)      /* 满则截断 */
#define SEGGER_RTT_MODE_BLOCK_IF_FIFO_FULL (2)    /* 满则阻塞,直到主机读走(默认,保证 blob 完整) */

int SEGGER_RTT_Write(unsigned BufferIndex, const void *pBuffer, unsigned NumBytes);

#endif /* SEGGER_RTT_H */
