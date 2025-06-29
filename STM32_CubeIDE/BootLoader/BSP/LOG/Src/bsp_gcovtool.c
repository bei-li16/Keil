/*
 * bsp_gcovtool.c
 *
 *  Created on: Apr 29, 2025
 *      Author: 18283
 */
#include "bsp_gcovtool.h"

#define GCOV_BUFFER_SIZE 4096    // 根据Flash/RAM容量调整
static unsigned char gcov_buffer[GCOV_BUFFER_SIZE];
static unsigned int gcov_buffer_idx = 0;

// 自定义内存写入回调（替代文件系统）
void gcov_write(const void *data, unsigned int len) 
{

}

// 初始化覆盖率数据结构[9](@ref)
void __gcov_init(void) 
{
    // 重定向GCOV输出到内存
    __gcov_set_write_fn(gcov_write);
    
}

void __gcov_exit(void) 
{
    // 强制刷新覆盖率数据到缓冲区[4](@ref)
    __gcov_dump();
    
}
