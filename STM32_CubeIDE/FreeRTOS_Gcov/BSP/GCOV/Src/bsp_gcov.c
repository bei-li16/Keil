/*
 * bsp_gcov.c - 嵌入式 gcov 覆盖率数据导出(统一内核 + 三种传输层)
 *
 * 原理:插桩编译的每个 .c 在 .init_array 里注册构造函数调用 __gcov_init(info),
 * 本文件自定义 __gcov_init 收集各编译单元的 gcov_info 指针(用户符号优先于
 * libgcov.a 的 _gcov.o,故 fopen 文件路径不会被拉入)。导出时逐个调用
 * __gcov_info_to_gcda() 把"元数据+当前计数"序列化成标准 .gcda 字节流,
 * 经所选传输层送回主机。
 */
#include "bsp_gcov.h"
#include <gcov.h>
#include <string.h>

/* ============================ 内核:信息收集 ============================ */

#ifndef GCOV_MAX_INFO
#define GCOV_MAX_INFO   16          /* 最多支持的插桩编译单元数 */
#endif

static struct gcov_info *gcov_info_list[GCOV_MAX_INFO];
static unsigned gcov_info_count;

/* 覆盖 libgcov.a 中 _gcov.o 的同名符号:链接器优先取本定义,_gcov.o 不会被拉入。
 * __gcov_exit 由插桩对象的 .fini_array 引用,必须一并提供,否则 _gcov.o 仍会被
 * 拉入造成 __gcov_init 重复定义;MCU 上没有 exit 流程,空实现即可 */
void __gcov_init (struct gcov_info *info)
{
    if (gcov_info_count < GCOV_MAX_INFO) {
        gcov_info_list[gcov_info_count++] = info;
    }
}

void __gcov_exit (void)
{
}

/* 斩断依赖链:_gcov_merge_add.o(merge 函数在 info 表中只被取地址,从不执行)
 * 引用 __gcov_read_counter,若不提供本桩,链接器会拉入 _gcov.o —— 该成员自带
 * __gcov_init/__gcov_exit 定义(与本文件重复)并引入 fopen/getenv 等文件模式
 * 运行时。此桩永远不会被调用,仅用于满足链接引用。 */
long long __gcov_read_counter (void)
{
    return 0;
}

/* ============================ 传输层 ============================ */

/* 未定义任何传输宏时按 RAM 处理:普通(非 gcov)构建下整个传输层与
 * 缓冲都会被 --gc-sections 裁剪,零开销 */
#if !defined(GCOV_TRANSPORT_RTT) && !defined(GCOV_TRANSPORT_SEMIHOST)

#ifndef GCOV_BUF_SIZE
#define GCOV_BUF_SIZE   8192        /* 供 GDB dump 的静态缓冲,与 gcov-dump-ram.gdb 里的尺寸保持一致 */
#endif

static uint8_t  gcov_buf[GCOV_BUF_SIZE];
static uint32_t gcov_buf_used;
static uint8_t  gcov_buf_overflow;

static void sink_begin(void)
{
    gcov_buf_used = 0;
    gcov_buf_overflow = 0;
}

static void sink_write(const void *data, uint32_t len)
{
    if (gcov_buf_overflow) return;
    if (gcov_buf_used + len > sizeof(gcov_buf)) {
        gcov_buf_overflow = 1;      /* 超限丢弃本帧,调大 GCOV_BUF_SIZE */
        return;
    }
    memcpy(&gcov_buf[gcov_buf_used], data, len);
    gcov_buf_used += len;
}

static void sink_end(void) { }

#elif defined(GCOV_TRANSPORT_RTT)

#include "SEGGER_RTT.h"

#define sink_begin()    ((void)0)
#define sink_write(d,l) ((void)SEGGER_RTT_Write(0, (d), (l)))
#define sink_end()      ((void)0)

#elif defined(GCOV_TRANSPORT_SEMIHOST)

/* ARM semihosting 裸调用(BKPT 0xAB),不依赖 rdimon.specs。
 * 调试器需开启 semihosting:OpenOCD "monitor arm semihosting enable" */
#define SEMI_SYS_OPEN   0x01
#define SEMI_SYS_CLOSE  0x02
#define SEMI_SYS_WRITE  0x05

static int semi_call(int op, void *arg)
{
    register int   r0 __asm("r0") = op;
    register void *r1 __asm("r1") = arg;
    __asm volatile ("bkpt 0xAB" : "+r" (r0) : "r" (r1) : "memory");
    return r0;
}

static int semi_open(const char *name)
{
    /* mode 索引按 semihosting 规范:"r"=0 .. "wb"=5 */
    struct { const char *s; int mode; int len; } a = { name, 5, (int)strlen(name) };
    return semi_call(SEMI_SYS_OPEN, &a);
}

static int semi_write(int fd, const void *data, int len)
{
    struct { int fd; const void *p; int len; } a = { fd, data, len };
    return semi_call(SEMI_SYS_WRITE, &a);       /* 返回未写出的字节数,0 为全部成功 */
}

static void semi_close(int fd)
{
    struct { int fd; } a = { fd };
    (void)semi_call(SEMI_SYS_CLOSE, &a);
}

static int gcov_fd;

static void sink_begin(void)
{
    gcov_fd = semi_open("gcov_blob.bin");
}

static void sink_write(const void *data, uint32_t len)
{
    if (gcov_fd < 0) return;
    const uint8_t *p = (const uint8_t *)data;
    while (len > 0) {
        int w = semi_write(gcov_fd, p, (int)len);
        if (w <= 0 || w > (int)len) return;     /* w 为"未写出"数,异常即放弃 */
        p += len - w;
        len = w;
    }
}

static void sink_end(void)
{
    if (gcov_fd >= 0) {
        semi_close(gcov_fd);
        gcov_fd = -1;
    }
}

#endif /* 传输层选择 */

/* ============================ 记录流编码 ============================ */

#ifndef GCOV_ALLOC_POOL
#define GCOV_ALLOC_POOL 1024            /* libgcov 内部临时对象的家,静态池避开 malloc */
#endif

static uint8_t  alloc_pool[GCOV_ALLOC_POOL];
static uint32_t alloc_used;

static void *alloc_cb(unsigned size, void *arg)
{
    void *p = NULL;
    (void)arg;
    if (alloc_used + size <= sizeof(alloc_pool)) {
        p = &alloc_pool[alloc_used];
        alloc_used += size;
    }
    return p;                                /* 不足返回 NULL,由 libgcov 自行容错 */
}

static void write_u32_le(uint32_t v)
{
    uint8_t b[4];
    b[0] = (uint8_t)(v);
    b[1] = (uint8_t)(v >> 8);
    b[2] = (uint8_t)(v >> 16);
    b[3] = (uint8_t)(v >> 24);
    sink_write(b, 4);
}

static void filename_cb(const char *name, void *arg)
{
    (void)arg;
    if (name == NULL) name = "";
    write_u32_le((uint32_t)strlen(name) + 1);
    sink_write(name, (uint32_t)strlen(name) + 1);
}

static void dump_cb(const void *data, unsigned len, void *arg)
{
    (void)arg;
    write_u32_le((uint32_t)len);
    sink_write(data, (uint32_t)len);
}

void bsp_gcov_dump_all(void)
{
    unsigned i;

    alloc_used = 0;
    sink_begin();
    for (i = 0; i < gcov_info_count; i++) {
        __gcov_info_to_gcda(gcov_info_list[i], filename_cb, dump_cb, alloc_cb, NULL);
        write_u32_le(0);                    /* 当前文件的块流结束 */
    }
    write_u32_le(0);                        /* 整条流结束标记 */
    sink_end();
}

/* ============================ 周期入口 ============================ */

volatile uint8_t gcov_stream_enable = 0;

void bsp_gcov_periodic(void)
{
#if defined(GCOV_TRANSPORT_RAM)
    bsp_gcov_dump_all();                    /* RAM:每秒刷新,latest 即最新计数 */
#else
    if (gcov_stream_enable) {
        bsp_gcov_dump_all();                /* RTT/SEMIHOST:由 GDB 置位后按需导出 */
    }
#endif
}
