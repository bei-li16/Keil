/*
 * bsp_gcovtool.h
 *
 *  Created on: Apr 29, 2025
 *      Author: 18283
 */

#ifndef LOG_INC_BSP_GCOVTOOL_H_
#define LOG_INC_BSP_GCOVTOOL_H_

#include <gcov.h>

extern void gcov_write(const void *data, unsigned len);

extern void __gcov_init(void);

extern void __gcov_exit(void);

#endif /* LOG_INC_BSP_GCOVTOOL_H_ */
