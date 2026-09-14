/*
 * bsp_gcov.h - 嵌入式 gcov 覆盖率数据导出
 *
 * 把固件内 libgcov 序列化出的 .gcda 字节流导出到主机。传输方式在
 * 构建时由宏选择(经 AutoMakeTool/Makefile 的 GCOV_TRANSPORT 变量注入):
 *   GCOV_TRANSPORT_RAM      数据写入静态缓冲,由 GDB "dump binary memory" 取回(默认)
 *   GCOV_TRANSPORT_RTT      数据经 SEGGER RTT 上行通道 0 实时流出,由 JLinkRTTLogger 落盘
 *   GCOV_TRANSPORT_SEMIHOST 数据经 semihosting 文件调用直接写成主机文件 gcov_blob.bin
 *
 * 三种方式的导出内容为同一种"记录流"格式,主机端统一用 gcov-extract.py 解析:
 *   记录 = [u32 文件名长度][文件名(含NUL)] ([u32 块长度][块数据])* 直到块长度为0
 *   流尾 = u32 0 作为结束标记;同名文件多次出现时主机取最后一次(即最新计数)
 *
 * 用法见 AutoMakeTool/GCOV_EXPORT_README.md
 */
#ifndef BSP_GCOV_H
#define BSP_GCOV_H

#include <stdint.h>

/* 把当前所有插桩单元的 gcda 流写出到所选传输层(可在 GDB 里 call) */
void bsp_gcov_dump_all(void);

/* 周期调用入口(Task1000ms 在 GCOV_BUILD 下调用):
 * RAM 模式下刷新缓冲供 GDB 随时取走;RTT/SEMIHOST 模式下受 gcov_stream_enable 门控 */
void bsp_gcov_periodic(void);

/* RTT/SEMIHOST 模式的导出开关:默认 0,避免无接收端时阻塞/空写;
 * 由 GDB "set var gcov_stream_enable=1" 打开 */
extern volatile uint8_t gcov_stream_enable;

#endif /* BSP_GCOV_H */
