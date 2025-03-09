/*
 * bsp_boot.c
 *
 *  Created on: Mar 3, 2025
 *      Author: 18283
 */
#include "bsp_boot.h"

/* 定义应用程序入口函数指针类型 */
typedef void (*AppEntry)(void);  // 无参数、无返回值的函数指针

/* 跳转函数 */
void jump_to_app(uint32_t appAddr) 
{
    // 1. 禁用所有中断
    __disable_irq();
    // __set_PRIMASK(1);

    /* 2. 设置主堆栈指针 (MSP) */
    // - appAddr 是应用程序中断向量表的第一个字（4字节）
    // - __IO 表示 volatile（防止编译器优化）
    // - __set_MSP 是 CMSIS 函数，用于设置 MSP
    __set_MSP(*(__IO uint32_t*)appAddr);

    /* 3. 获取应用程序入口地址 */
    // - appAddr + 4 是中断向量表的第二个字（复位向量）
    // - 强制转换为函数指针
    AppEntry appEntry = (AppEntry)(*(__IO uint32_t*)(appAddr + 4));

    /* 4. 关闭所有中断（避免跳转后残留中断触发） */
    __disable_irq();

    /* 5. 复位外设（可选，避免外设状态冲突） */
    __HAL_RCC_APB1_FORCE_RESET();
    __HAL_RCC_APB2_FORCE_RESET();
    __HAL_RCC_AHB1_FORCE_RESET();
    __HAL_RCC_APB1_RELEASE_RESET();
    __HAL_RCC_APB2_RELEASE_RESET();
    __HAL_RCC_AHB1_RELEASE_RESET();

    /* 6. 跳转到应用程序 */
    appEntry();  // 此时 CPU 开始执行应用程序的 Reset_Handler

    // 7. 此处不会返回，若跳转失败需触发复位
    NVIC_SystemReset();
}

