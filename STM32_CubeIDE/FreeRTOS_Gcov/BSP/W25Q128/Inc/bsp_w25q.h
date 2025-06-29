/*
 * bsp_w25q.h
 *
 *  Created on: Feb 27, 2025
 *      Author: 18283
 */
#include "spi.h"
#include "bsp_log.h"

#ifndef W25Q128_INC_BSP_W25Q_H_
#define W25Q128_INC_BSP_W25Q_H_

/* Private typedef -----------------------------------------------------------*/
// #define  sFLASH_ID                       0xEF3015     //W25X16
// #define  sFLASH_ID                       0xEF4015	 //W25Q16
// #define  sFLASH_ID                       0XEF4017     //W25Q64
#define  sFLASH_ID                       0XEF4018     //W25Q128


//#define SPI_FLASH_PageSize            4096
#define SPI_FLASH_PageSize              256
#define SPI_FLASH_PerWritePageSize      256

/* Private define ------------------------------------------------------------*/
#define W25X_WriteEnable		      0x06 
#define W25X_WriteDisable		      0x04 
#define W25X_ReadStatusReg		      0x05 
#define W25X_WriteStatusReg		      0x01 
#define W25X_ReadData			      0x03 
#define W25X_FastReadData		      0x0B 
#define W25X_FastReadDual		      0x3B 
#define W25X_PageProgram		      0x02 
#define W25X_BlockErase			      0xD8 
#define W25X_SectorErase		      0x20 
#define W25X_ChipErase			      0xC7 
#define W25X_PowerDown			      0xB9 
#define W25X_ReleasePowerDown	      0xAB 
#define W25X_DeviceID			      0xAB 
#define W25X_ManufactDeviceID   	  0x90 
#define W25X_JedecDeviceID		      0x9F 

#define WIP_Flag                      0x01  /* Write In Progress (WIP) flag */
#define Dummy_Byte                    0xFF

#define W25Q_SPI5                        &hspi5
#define SPI_FLASH_CS_LOW()               HAL_GPIO_WritePin(W25Q_SPI5_CS_GPIO_Port, W25Q_SPI5_CS_Pin, GPIO_PIN_RESET)
#define SPI_FLASH_CS_HIGH()              HAL_GPIO_WritePin(W25Q_SPI5_CS_GPIO_Port, W25Q_SPI5_CS_Pin, GPIO_PIN_RESET)

#define SPI_TRANSMIT_IM                  STD_ON
#define SPI_TRANSMIT_DMA                 STD_OFF
#define SPIT_FLAG_TIMEOUT                ((uint32_t)0x1000)
#define SPIT_LONG_TIMEOUT                ((uint32_t)(10 * SPIT_FLAG_TIMEOUT))
#define W25Q_SPI5_RECIEVE_TIMEOUT        0x1000
#define W25Q_SPI5_TRANSMIT_TIMEOUT       1000

#define FLASH_DEBUG_ON                   1

#define FLASH_INFO(fmt,arg...)           LOG_RELEASE("<<-FLASH-INFO->> "fmt"\n",##arg)
#define FLASH_ERROR(fmt,arg...)          LOG_ERROR("<<-FLASH-ERROR->> "fmt"\n",##arg)
#define FLASH_DEBUG(fmt,arg...)          do{\
                                            if(FLASH_DEBUG_ON)\
                                                LOG_DEBUG("<<-FLASH-DEBUG->> [%d]"fmt"\n",__LINE__, ##arg);\
                                          }while(0)

#define W25Q_TEST_1_TIMES                1
#define W25Q_TEST_2_TIMES                2
#define W25Q_TEST_3_TIMES                3
#define W25Q_TEST_4_TIMES                4
#define W25Q_TEST_5_TIMES                5


void SPI_FLASH_Init(void);
void SPI_FLASH_SectorErase(uint32_t SectorAddr);
void SPI_FLASH_BulkErase(void);
void SPI_FLASH_PageWrite(uint8_t* pBuffer, uint32_t WriteAddr, uint16_t NumByteToWrite);
void SPI_FLASH_BufferWrite(uint8_t* pBuffer, uint32_t WriteAddr, uint16_t NumByteToWrite);
void SPI_FLASH_BufferRead(uint8_t* pBuffer, uint32_t ReadAddr, uint16_t NumByteToRead);
uint32_t SPI_FLASH_ReadID(void);
uint32_t SPI_FLASH_ReadDeviceID(void);
void SPI_FLASH_StartReadSequence(uint32_t ReadAddr);
void SPI_Flash_PowerDown(void);
void SPI_Flash_WAKEUP(void);


uint8_t SPI_FLASH_ReadByte(void);
uint8_t SPI_FLASH_SendByte(uint8_t byte);
uint16_t SPI_FLASH_SendHalfWord(uint16_t HalfWord);
void SPI_FLASH_WriteEnable(void);
void SPI_FLASH_WaitForWriteEnd(void);


void W25Q_ReadID_Test(void);


#endif /* W25Q128_INC_BSP_W25Q_H_ */
