/*
 * bsp_boot.h
 *
 *  Created on: Mar 3, 2025
 *      Author: 18283
 */

#ifndef BOOT_INC_BSP_BOOT_H_
#define BOOT_INC_BSP_BOOT_H_

#include "stm32f4xx_hal.h"

#define     APPA_ADDR       0x08008000  /* offset 32K */
#define     APPB_ADDR       0x08040000  /* offset 256K */

extern void jump_to_app(uint32_t appAddr);

#endif /* BOOT_INC_BSP_BOOT_H_ */
