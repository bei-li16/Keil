/*
 * bsp_I2C_eeprom.c
 *
 *  Created on: Feb 23, 2025
 *      Author: 18283
 */
#include "bsp_I2C_eeprom.h"

uint8_t EEPROM_TX_STA = STD_ON;
uint8_t EEPROM_RX_STA = STD_ON;
uint8_t wbuff[EEPROM_WRITE_LEN] ={0};
uint8_t rbuff[EEPROM_WRITE_LEN] ={0};
uint8_t I2C_TxBuff[I2C_PageSize + 1] ={0};
uint8_t I2C_TEST1_EEPROM = STD_ON;

void I2C_WritePage(uint8_t* pBuffer, uint8_t WriteAddr, uint8_t len)
{
#if (I2C_EEPROM_COM == I2C_NORMAL_IT)
	I2C_TxBuff[0] = WriteAddr;
    for(uint8_t i = 0; i < len; i++)
    {
        I2C_TxBuff[i + 1] = pBuffer[i];
    }
    while (EEPROM_TX_STA != STD_ON);
    EEPROM_TX_STA = STD_OFF;
    HAL_I2C_Master_Transmit_IT(&hi2c1, EEPROM_ADDRESS, I2C_TxBuff, len + 1);
#elif (I2C_EEPROM_COM == I2C_MEM_DMA)
    while (EEPROM_TX_STA != STD_ON);
    EEPROM_TX_STA = STD_OFF;
    HAL_I2C_Mem_Write_DMA(&hi2c1, EEPROM_ADDRESS, WriteAddr, I2C_MEMADD_SIZE_8BIT, pBuffer, len);
#else
    LOG_INFO("I2C_EEPROM_COM is not defined.\n");
#endif
    while (HAL_I2C_IsDeviceReady(&hi2c1, EEPROM_ADDRESS, EEPROM_TRIAL_TIMES, 100) != HAL_OK);
}

void I2C_ReadPage(uint8_t* pBuffer, uint8_t ReadAddr, uint8_t len)
{
#if (I2C_EEPROM_COM == I2C_NORMAL_IT)
    uint8_t ret = 0;
	do{
		ret = HAL_I2C_Master_Transmit(&hi2c1, EEPROM_ADDRESS, &ReadAddr, 1, 1000);
	}while(ret != 0);
    while (EEPROM_RX_STA != STD_ON);
    EEPROM_RX_STA = STD_OFF;
    HAL_I2C_Master_Receive_IT(&hi2c1, EEPROM_ADDRESS, pBuffer, len);
#elif (I2C_EEPROM_COM == I2C_MEM_DMA)
    while (EEPROM_RX_STA != STD_ON);
    EEPROM_RX_STA = STD_OFF;
    HAL_I2C_Mem_Read_DMA(&hi2c1, EEPROM_ADDRESS, ReadAddr, I2C_MEMADD_SIZE_8BIT, pBuffer, len);
#else
    LOG_INFO("I2C_EEPROM_COM is not defined.\n");
#endif
}

void I2C_EE_BufferWrite(uint8_t* pBuffer, uint8_t WriteAddr, uint16_t len)
{
    uint8_t NumOfPage = 0;
    uint8_t NumOfSingle = 0;
    uint8_t count = 0;
    uint16_t Addr = 0;
    Addr = WriteAddr % I2C_PageSize;
    count = I2C_PageSize - Addr;
    NumOfPage = len / I2C_PageSize;
    NumOfSingle = len % I2C_PageSize;
    if(Addr == 0)
    {
        if(NumOfPage == 0)
        {
            I2C_WritePage(pBuffer, WriteAddr, len);
        }
        else
        {
            while(NumOfPage--)
            {
                I2C_WritePage(pBuffer, WriteAddr, I2C_PageSize);
                WriteAddr += I2C_PageSize;
                pBuffer += I2C_PageSize;
            }
            if(NumOfSingle != 0)
            {
                I2C_WritePage(pBuffer, WriteAddr, NumOfSingle);
            }
        }
    }
    else
    {
        if(NumOfPage == 0)
        {
            if(NumOfSingle > count)
            {
                I2C_WritePage(pBuffer, WriteAddr, count);
                WriteAddr += count;
                pBuffer += count;
                I2C_WritePage(pBuffer, WriteAddr, NumOfSingle - count);
            }
            else
            {
                I2C_WritePage(pBuffer, WriteAddr, len);
            }
        }
        else
        {
            len -= count;
            NumOfPage = len / I2C_PageSize;
            NumOfSingle = len % I2C_PageSize;
            I2C_WritePage(pBuffer, WriteAddr, count);
            WriteAddr += count;
            pBuffer += count;
            while(NumOfPage--)
            {
                I2C_WritePage(pBuffer, WriteAddr, I2C_PageSize);
                WriteAddr += I2C_PageSize;
                pBuffer += I2C_PageSize;
            }
            if(NumOfSingle != 0)
            {
                I2C_WritePage(pBuffer, WriteAddr, NumOfSingle);
            }
        }
    }
}

uint32_t I2C_EE_BufferRead(uint8_t* pBuffer, uint8_t ReadAddr, uint16_t NumByteToRead)
{
    uint8_t Frontsize = 0;
    uint8_t Endsize = 0;
    uint8_t NumOfPage = 0;
    Frontsize = I2C_PageSize - ReadAddr % I2C_PageSize;
    Endsize = (NumByteToRead - Frontsize) % I2C_PageSize;
    NumOfPage = (NumByteToRead - Frontsize - Endsize) / I2C_PageSize;
    if(Frontsize == 0)
    {
        if(NumOfPage == 0)
        {
            I2C_ReadPage(pBuffer, ReadAddr, NumByteToRead);
        }
        else
        {
            I2C_ReadPage(pBuffer, ReadAddr, Frontsize);
            pBuffer += Frontsize;
            ReadAddr += Frontsize;
            while(NumOfPage--)
            {
                I2C_ReadPage(pBuffer, ReadAddr, I2C_PageSize);
                pBuffer += I2C_PageSize;
                ReadAddr += I2C_PageSize;
            }
            if(Endsize != 0)
            {
                I2C_ReadPage(pBuffer, ReadAddr, Endsize);
            }
        }
    }
    else
    {
        if(NumOfPage == 0)
        {
            if(NumByteToRead > Frontsize)
            {
                I2C_ReadPage(pBuffer, ReadAddr, Frontsize);
                pBuffer += Frontsize;
                ReadAddr += Frontsize;
                I2C_ReadPage(pBuffer, ReadAddr, NumByteToRead - Frontsize);
            }
            else
            {
                I2C_ReadPage(pBuffer, ReadAddr, NumByteToRead);
            }
        }
        else
        {
            I2C_ReadPage(pBuffer, ReadAddr, Frontsize);
            pBuffer += Frontsize;
            ReadAddr += Frontsize;
            while(NumOfPage--)
            {
                I2C_ReadPage(pBuffer, ReadAddr, I2C_PageSize);
                pBuffer += I2C_PageSize;
                ReadAddr += I2C_PageSize;
            }
            if(Endsize != 0)
            {
                I2C_ReadPage(pBuffer, ReadAddr, Endsize);
            }
        }
    }

}


uint8_t I2C_Test_2Byte(void)
{
    for(uint8_t i = 0; i < 2 + 1; i++)
    {
        wbuff[i] = i;
    }
    uint8_t ret = HAL_I2C_Master_Transmit(&hi2c1, EEPROM_ADDRESS, wbuff, 3, 1000);
    while (ret != 0);
    /* write read address */
    do{
    	ret = HAL_I2C_Master_Transmit(&hi2c1, EEPROM_ADDRESS, wbuff, 1, 1000);
    }while(ret != 0);
    /* read data */
    ret = HAL_I2C_Master_Receive(&hi2c1, EEPROM_ADDRESS, rbuff, 2, 1000);
    EEPROM_INFO("Read data: 0x%02X 0x%02X.\n", rbuff[0], rbuff[1]);
    return 1;
}

uint8_t I2C_Test_TwoByte(void)
{
	uint8_t i = 0;
	uint8_t ret = 0;
    for(i = 0; i < 9; i++)
    {
        wbuff[i] = i;
    }
    while (EEPROM_TX_STA != STD_ON);
    EEPROM_TX_STA = STD_OFF;
    HAL_I2C_Master_Transmit_IT(&hi2c1, EEPROM_ADDRESS, wbuff, 9);
    while (EEPROM_RX_STA != 1);
    /* write read address */
	do{
		ret = HAL_I2C_Master_Transmit(&hi2c1, EEPROM_ADDRESS, wbuff, 1, 1000);
	}while(ret != 0);
    while (EEPROM_RX_STA != STD_ON);
    EEPROM_RX_STA = STD_OFF;
    HAL_I2C_Master_Receive_IT(&hi2c1, EEPROM_ADDRESS, rbuff, 8);
    EEPROM_INFO("Read data IT: 0x%02X 0x%02X 0x%02X 0x%02X.\n", rbuff[0], rbuff[1], rbuff[2], rbuff[3]);
    EEPROM_INFO("Rx_Status: %d.\n", EEPROM_RX_STA);
    return 1;
}

void I2C_Test1(void)
{
    uint8_t ret = 1;
    uint16_t i;
    if(I2C_TEST1_EEPROM == STD_ON)
    {
        EEPROM_INFO("---------I2C_Test2_Begin----------\n");
        for(i = 0; i < EEPROM_WRITE_LEN; i++)
        {
            wbuff[i] = (uint8_t)i;
            LOG_INFO("0x%02X ", wbuff[i]);
            if(i%16 == 15)
            {
                LOG_INFO("\n\r");
            }
        }
        LOG_INFO("\n\r");
        I2C_EE_BufferWrite(wbuff, 0x00, EEPROM_WRITE_LEN);
        EEPROM_INFO("Write Success\n");
    
        EEPROM_INFO("Read Data.\n");
        I2C_EE_BufferRead(rbuff, 0x00, EEPROM_WRITE_LEN);
        //将I2c_Buf_Read中的数据通过串口打印
        for (i = 0; i < EEPROM_WRITE_LEN; i++)
        {	
            if(wbuff[i] != rbuff[i])
            {
                LOG_INFO("0x%02X ", rbuff[i]);
                EEPROM_ERROR("Error: I2C EEPROM Read/Write Test Failed\n");
                ret = 0;
                EEPROM_INFO("---------I2C_Test1 End Fail-------------\n");
                goto I2C_Test1_Endlabel;
            }
            LOG_INFO("0x%02X ", rbuff[i]);
            if(i%16 == 15)
            {
                LOG_INFO("\n\r");
            }
        }
        LOG_INFO("\n\r");
        EEPROM_INFO("I2C(AT24C02) EEPROM Read/Write Test Success\n");
        ret = 1;
        EEPROM_INFO("---------I2C_Test1 End Success----------\n");
        goto I2C_Test1_Endlabel;
    }
I2C_Test1_Endlabel:
    if(ret == 1)
    {
        I2C_TEST1_EEPROM = STD_OFF;
    }
    else
    {
        I2C_TEST1_EEPROM = STD_ON;
    }
}


/************ Interrupt Function *****************/
void HAL_I2C_MasterTxCpltCallback(I2C_HandleTypeDef *hi2c)
{
    if(EEPROM_I2C == hi2c)
    {
        EEPROM_TX_STA = STD_ON;
    }
}

void HAL_I2C_MasterRxCpltCallback(I2C_HandleTypeDef *hi2c)
{
    if(EEPROM_I2C == hi2c)
    {
        EEPROM_RX_STA = STD_ON;
    }
}

void HAL_I2C_MemTxCpltCallback(I2C_HandleTypeDef *hi2c)
{
    if(EEPROM_I2C == hi2c)
    {
        EEPROM_TX_STA = STD_ON;
    }
}

void HAL_I2C_MemRxCpltCallback(I2C_HandleTypeDef *hi2c)
{
    if(EEPROM_I2C == hi2c)
    {
        EEPROM_RX_STA = STD_ON;
    }
}
