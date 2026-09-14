/*
 * SEGGER_RTT.c - 精简版 SEGGER RTT(仅上行写),供 bsp_gcov.c 的 RTT 传输层使用
 * 控制块布局与 SEGGER 官方 RTT 规范一致(见 SEGGER_RTT.h)
 */
#include "SEGGER_RTT.h"
#include <string.h>

typedef struct {
    const char *sName;
    char       *pBuffer;
    int         SizeOfBuffer;
    volatile int WrOff;
    volatile int RdOff;
    int         Flags;
} SEGGER_RTT_BUFFER_UP;

typedef struct {
    const char *sName;
    char       *pBuffer;
    int         SizeOfBuffer;
    volatile int RdOff;
    volatile int WrOff;
    int         Flags;
} SEGGER_RTT_BUFFER_DOWN;

typedef struct {
    char                   acID[16];             /* "SEGGER RTT\0..." — 最后才写入 */
    int                    MaxNumUpBuffers;
    int                    MaxNumDownBuffers;
    SEGGER_RTT_BUFFER_UP   aUp[SEGGER_RTT_MAX_NUM_UP_BUFFERS];
    SEGGER_RTT_BUFFER_DOWN aDown[SEGGER_RTT_MAX_NUM_DOWN_BUFFERS];
} SEGGER_RTT_CB;

static char         _acUpBuffer[SEGGER_RTT_BUFFER_SIZE_UP];
static char         _acDownBuffer[SEGGER_RTT_BUFFER_SIZE_DOWN];
static SEGGER_RTT_CB _SEGGER_RTT;

static const char _RTTUpName[]   = "gcov";
static const char _RTTDownName[] = "gin";

/* acID 最后写:主机一旦识别到 ID,其余字段必须已就绪 */
static void _DoInit(void)
{
    memset(&_SEGGER_RTT, 0, sizeof(_SEGGER_RTT));
    _SEGGER_RTT.MaxNumUpBuffers   = SEGGER_RTT_MAX_NUM_UP_BUFFERS;
    _SEGGER_RTT.MaxNumDownBuffers = SEGGER_RTT_MAX_NUM_DOWN_BUFFERS;
    _SEGGER_RTT.aUp[0].sName       = _RTTUpName;
    _SEGGER_RTT.aUp[0].pBuffer     = _acUpBuffer;
    _SEGGER_RTT.aUp[0].SizeOfBuffer = SEGGER_RTT_BUFFER_SIZE_UP;
    _SEGGER_RTT.aUp[0].Flags       = SEGGER_RTT_MODE_BLOCK_IF_FIFO_FULL;
    _SEGGER_RTT.aDown[0].sName       = _RTTDownName;
    _SEGGER_RTT.aDown[0].pBuffer     = _acDownBuffer;
    _SEGGER_RTT.aDown[0].SizeOfBuffer = SEGGER_RTT_BUFFER_SIZE_DOWN;
    _SEGGER_RTT.aDown[0].Flags       = SEGGER_RTT_MODE_NO_BLOCK_SKIP;
    memcpy(_SEGGER_RTT.acID, "SEGGER RTT", sizeof("SEGGER RTT"));
}

int SEGGER_RTT_Write(unsigned BufferIndex, const void *pBuffer, unsigned NumBytes)
{
    SEGGER_RTT_BUFFER_UP *p;
    unsigned rd, wr, free_cnt, after, cnt;

    if (_SEGGER_RTT.acID[0] == '\0') {
        _DoInit();
    }
    if (BufferIndex >= (unsigned)SEGGER_RTT_MAX_NUM_UP_BUFFERS) return 0;
    p = &_SEGGER_RTT.aUp[BufferIndex];

    rd = p->RdOff;
    wr = p->WrOff;
    free_cnt = (rd - wr - 1u) & (p->SizeOfBuffer - 1u);   /* SizeOfBuffer 必须为 2 的幂 */

    if (NumBytes > free_cnt) {
        if (p->Flags != SEGGER_RTT_MODE_BLOCK_IF_FIFO_FULL) return 0;
        do {                                              /* 阻塞等主机取走,数据零丢失 */
            rd = p->RdOff;
            free_cnt = (rd - wr - 1u) & (p->SizeOfBuffer - 1u);
        } while (NumBytes > free_cnt);
    }

    after = (wr + NumBytes) & (p->SizeOfBuffer - 1u);
    if (after > wr) {
        memcpy(&p->pBuffer[wr], pBuffer, NumBytes);
    } else {
        cnt = (unsigned)p->SizeOfBuffer - wr;
        memcpy(&p->pBuffer[wr], pBuffer, cnt);
        memcpy(&p->pBuffer[0], (const uint8_t *)pBuffer + cnt, NumBytes - cnt);
    }
    __asm volatile ("dmb sy" ::: "memory");               /* 先落数据,后推 WrOff */
    p->WrOff = after;
    return (int)NumBytes;
}
