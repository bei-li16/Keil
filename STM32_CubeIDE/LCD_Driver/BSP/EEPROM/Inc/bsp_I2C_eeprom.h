/*
 * bsp_I2C_eeprom.h
 *
 *  Created on: Feb 23, 2025
 *      Author: 18283
 */

#ifndef EEPROM_INC_BSP_I2C_EEPROM_H_
#define EEPROM_INC_BSP_I2C_EEPROM_H_
#include "i2c.h"
#include "bsp_log.h"

/* AT24C01/02每页有8个字节 */
#define I2C_PageSize           8
#define EEPROM_WRITE_LEN       258
#define EEPROM_TRIAL_TIMES     10

#define I2C_MEM_DMA            0
#define I2C_NORMAL_IT          1
#define I2C_EEPROM_COM         I2C_MEM_DMA

/* AT24C04/08A/16A每页有16个字节 */
//#define I2C_PageSize           16			



/* STM32 I2C fast speed */
#define I2C_Speed              400000
#define I2C_OWN_ADDRESS7       0X0A   

/*I2C interface*/
#define EEPROM_I2C                          &hi2c1
// #define EEPROM_I2C                          I2C1
// #define EEPROM_I2C_CLK                      RCC_APB1Periph_I2C1
// #define EEPROM_I2C_CLK_INIT					RCC_APB1PeriphClockCmd

// #define EEPROM_I2C_SCL_PIN                  GPIO_Pin_6                 
// #define EEPROM_I2C_SCL_GPIO_PORT            GPIOB                       
// #define EEPROM_I2C_SCL_GPIO_CLK             RCC_AHB1Periph_GPIOB
// #define EEPROM_I2C_SCL_SOURCE               GPIO_PinSource6
// #define EEPROM_I2C_SCL_AF                   GPIO_AF_I2C1

// #define EEPROM_I2C_SDA_PIN                  GPIO_Pin_7                  
// #define EEPROM_I2C_SDA_GPIO_PORT            GPIOB                       
// #define EEPROM_I2C_SDA_GPIO_CLK             RCC_AHB1Periph_GPIOB
// #define EEPROM_I2C_SDA_SOURCE               GPIO_PinSource7
// #define EEPROM_I2C_SDA_AF                   GPIO_AF_I2C1

/* Timeout*/
#define I2CT_FLAG_TIMEOUT                   ((uint32_t)0x1000)
#define I2CT_LONG_TIMEOUT                   ((uint32_t)(10 * I2CT_FLAG_TIMEOUT))

/* Infomation printf*/
#define EEPROM_DEBUG_ON                     0

#define EEPROM_INFO(fmt,arg...)           LOG_RELEASE("<<-EEPROM-INFO->> "fmt"\n",##arg)
#define EEPROM_ERROR(fmt,arg...)          LOG_RELEASE("<<-EEPROM-ERROR->> "fmt"\n",##arg)
#define EEPROM_DEBUG(fmt,arg...)          do{\
                                            if(EEPROM_DEBUG_ON)\
                                            LOG_RELEASE("<<-EEPROM-DEBUG->> [%d]"fmt"\n",__LINE__, ##arg);\
                                          }while(0)

/* 
 * AT24C02 2kb = 2048bit = 2048/8 B = 256 B
 * 32 pages of 8 bytes each
 *
 * Device Address
 * 1 0 1 0 A2 A1 A0 R/W
 * 1 0 1 0 0  0  0  0 = 0XA0
 * 1 0 1 0 0  0  0  1 = 0XA1 
 */

/* EEPROM Addresses defines */
#define EEPROM_ADDRESS 0xA0   /* E2 = 0 */
//#define EEPROM_Block1_ADDRESS 0xA2 /* E2 = 0 */
//#define EEPROM_Block2_ADDRESS 0xA4 /* E2 = 0 */
//#define EEPROM_Block3_ADDRESS 0xA6 /* E2 = 0 */



// void I2C_EE_Init(void);
// void I2C_EE_BufferWrite(uint8_t* pBuffer, uint8_t WriteAddr, uint16_t NumByteToWrite);
// uint32_t I2C_EE_ByteWrite(uint8_t* pBuffer, uint8_t WriteAddr);
// uint32_t I2C_EE_PageWrite(uint8_t* pBuffer, uint8_t WriteAddr, uint8_t NumByteToWrite);
// uint32_t I2C_EE_BufferRead(uint8_t* pBuffer, uint8_t ReadAddr, uint16_t NumByteToRead);
// void I2C_EE_WaitEepromStandbyState(void);
extern void I2C_Test1(void);
extern uint8_t I2C_Test_2Byte(void);
extern uint8_t I2C_Test_TwoByte(void);

#endif /* EEPROM_INC_BSP_I2C_EEPROM_H_ */
