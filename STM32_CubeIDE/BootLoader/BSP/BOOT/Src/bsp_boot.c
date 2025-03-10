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
void jump_to_app(uint32_t appAddr) {
    // 1. 关闭所有中断
    __disable_irq();
    for (int i = 0; i < 8; i++) {
        NVIC->ICER[i] = 0xFFFFFFFF;
        NVIC->ICPR[i] = 0xFFFFFFFF;
    }
    SysTick->CTRL = 0;

    // 2.设置中断向量表地址
    // 假设应用程序起始地址为 0x08008000
    /********************* 必须显式更新中断向量表地址 ***************************/
    SCB->VTOR = appAddr;  // 设置中断向量表地址

    // 3. 复位外设
    __HAL_RCC_APB1_FORCE_RESET();
    __HAL_RCC_APB2_FORCE_RESET();
    __HAL_RCC_AHB1_FORCE_RESET();
    __HAL_RCC_APB1_RELEASE_RESET();
    __HAL_RCC_APB2_RELEASE_RESET();
    __HAL_RCC_AHB1_RELEASE_RESET();

    // 4. 设置MSP并跳转
    AppEntry appEntry = (AppEntry)(*(__IO uint32_t*)(appAddr + 4));
    __set_MSP(*(__IO uint32_t*)appAddr);
    appEntry();

    // 5. 跳转失败则复位
    NVIC_SystemReset();
}

