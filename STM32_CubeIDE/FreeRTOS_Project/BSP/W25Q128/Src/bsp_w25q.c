/*
 * bsp_w25q.c
 *
 *  Created on: Feb 27, 2025
 *      Author: 18283
 */
#include "bsp_w25q.h"

static uint16_t SPI_TIMEOUT_UserCallback(uint8_t errorCode);



uint32_t SPI_WriteData(uint8_t Data)
{
    uint8_t *pData = &Data;
    uint32_t ret = 0;
#if (SPI_TRANSMIT_IM == STD_ON)
    ret = HAL_SPI_Transmit(W25Q_SPI5, pData, 1, W25Q_SPI5_TRANSMIT_TIMEOUT);
#elif (SPI_TRANSMIT_DMA == STD_ON)
    while (LCD_TX_STATUS == STD_OFF);
    LCD_TX_STATUS = STD_OFF;
    HAL_SPI_Transmit_DMA(W25Q_SPI5, pData, 1);
#endif
    return ret;
}

uint32_t SPI_ReaData(uint8_t Data)
{
#if (SPI_TRANSMIT_IM == STD_ON)
    uint32_t ret = 0;
    ret = HAL_SPI_Receive(W25Q_SPI5, &Data, 1, W25Q_SPI5_RECIEVE_TIMEOUT);
#endif
    return ret;
}


void SPI_FLASH_Init(void)
{
    /* NULL */
    SPI_FLASH_CS_HIGH();
}

/**
* @brief  擦除FLASH扇区
* @param  SectorAddr：要擦除的扇区地址
* @retval 无
*/
void SPI_FLASH_SectorErase(uint32_t SectorAddr)
{
    SPI_FLASH_WriteEnable();
    SPI_FLASH_WaitForWriteEnd();
    /* 擦除扇区 */
    /* 选择FLASH: CS低电平 */
    SPI_FLASH_CS_LOW();
    /* 发送扇区擦除指令*/
    SPI_FLASH_SendByte(W25X_SectorErase);
    /*发送擦除扇区地址的高位*/
    SPI_FLASH_SendByte((SectorAddr & 0xFF0000) >> 16);
    /* 发送擦除扇区地址的中位 */
    SPI_FLASH_SendByte((SectorAddr & 0xFF00) >> 8);
    /* 发送擦除扇区地址的低位 */
    SPI_FLASH_SendByte(SectorAddr & 0xFF);
    /* 停止信号 FLASH: CS 高电平 */
    SPI_FLASH_CS_HIGH();
    /* 等待擦除完毕*/
    SPI_FLASH_WaitForWriteEnd();
}


/**
* @brief  擦除FLASH扇区，整片擦除
* @param  无
* @retval 无
*/
void SPI_FLASH_BulkErase(void)
{
    /* 发送FLASH写使能命令 */
    SPI_FLASH_WriteEnable();

    /* 整块 Erase */
    /* 选择FLASH: CS低电平 */
    SPI_FLASH_CS_LOW();
    /* 发送整块擦除指令*/
    SPI_FLASH_SendByte(W25X_ChipErase);
    /* 停止信号 FLASH: CS 高电平 */
    SPI_FLASH_CS_HIGH();

    /* 等待擦除完毕*/
    SPI_FLASH_WaitForWriteEnd();
}



/**
* @brief  对FLASH按页写入数据，调用本函数写入数据前需要先擦除扇区
* @param	pBuffer，要写入数据的指针
* @param WriteAddr，写入地址
* @param  NumByteToWrite，写入数据长度，必须小于等于SPI_FLASH_PerWritePageSize
* @retval 无
*/
void SPI_FLASH_PageWrite(uint8_t* pBuffer, uint32_t WriteAddr, uint16_t NumByteToWrite)
{
    /* 发送FLASH写使能命令 */
    SPI_FLASH_WriteEnable();

    /* 选择FLASH: CS低电平 */
    SPI_FLASH_CS_LOW();
    /* 写页写指令*/
    SPI_FLASH_SendByte(W25X_PageProgram);
    /*发送写地址的高位*/
    SPI_FLASH_SendByte((WriteAddr & 0xFF0000) >> 16);
    /*发送写地址的中位*/
    SPI_FLASH_SendByte((WriteAddr & 0xFF00) >> 8);
    /*发送写地址的低位*/
    SPI_FLASH_SendByte(WriteAddr & 0xFF);

    if(NumByteToWrite > SPI_FLASH_PerWritePageSize)
    {
        NumByteToWrite = SPI_FLASH_PerWritePageSize;
        FLASH_ERROR("SPI_FLASH_PageWrite too large!");
    }

    /* 写入数据*/
    while (NumByteToWrite--)
    {
        /* 发送当前要写入的字节数据 */
        SPI_FLASH_SendByte(*pBuffer);
        /* 指向下一字节数据 */
        pBuffer++;
    }

    /* 停止信号 FLASH: CS 高电平 */
    SPI_FLASH_CS_HIGH();

    /* 等待写入完毕*/
    SPI_FLASH_WaitForWriteEnd();
}


/**
* @brief  对FLASH写入数据，调用本函数写入数据前需要先擦除扇区
* @param	pBuffer，要写入数据的指针
* @param  WriteAddr，写入地址
* @param  NumByteToWrite，写入数据长度
* @retval 无
*/
void SPI_FLASH_BufferWrite(uint8_t* pBuffer, uint32_t WriteAddr, uint16_t NumByteToWrite)
{
    uint8_t NumOfPage = 0, NumOfSingle = 0, Addr = 0, count = 0, temp = 0;
        
        /*mod运算求余，若writeAddr是SPI_FLASH_PageSize整数倍，运算结果Addr值为0*/
    Addr = WriteAddr % SPI_FLASH_PageSize;
        
        /*差count个数据值，刚好可以对齐到页地址*/
    count = SPI_FLASH_PageSize - Addr;	
        /*计算出要写多少整数页*/
    NumOfPage =  NumByteToWrite / SPI_FLASH_PageSize;
        /*mod运算求余，计算出剩余不满一页的字节数*/
    NumOfSingle = NumByteToWrite % SPI_FLASH_PageSize;

        /* Addr=0,则WriteAddr 刚好按页对齐 aligned  */
    if (Addr == 0) 
    {
            /* NumByteToWrite < SPI_FLASH_PageSize */
        if (NumOfPage == 0) 
        {
        SPI_FLASH_PageWrite(pBuffer, WriteAddr, NumByteToWrite);
        }
        else /* NumByteToWrite > SPI_FLASH_PageSize */
        {
                /*先把整数页都写了*/
        while (NumOfPage--)
        {
            SPI_FLASH_PageWrite(pBuffer, WriteAddr, SPI_FLASH_PageSize);
            WriteAddr +=  SPI_FLASH_PageSize;
            pBuffer += SPI_FLASH_PageSize;
        }
                
                /*若有多余的不满一页的数据，把它写完*/
        SPI_FLASH_PageWrite(pBuffer, WriteAddr, NumOfSingle);
        }
    }
        /* 若地址与 SPI_FLASH_PageSize 不对齐  */
    else 
    {
            /* NumByteToWrite < SPI_FLASH_PageSize */
        if (NumOfPage == 0) 
        {
                /*当前页剩余的count个位置比NumOfSingle小，写不完*/
        if (NumOfSingle > count) 
        {
            temp = NumOfSingle - count;
                    
                    /*先写满当前页*/
            SPI_FLASH_PageWrite(pBuffer, WriteAddr, count);
            WriteAddr +=  count;
            pBuffer += count;
                    
                    /*再写剩余的数据*/
            SPI_FLASH_PageWrite(pBuffer, WriteAddr, temp);
        }
        else /*当前页剩余的count个位置能写完NumOfSingle个数据*/
        {				
            SPI_FLASH_PageWrite(pBuffer, WriteAddr, NumByteToWrite);
        }
        }
        else /* NumByteToWrite > SPI_FLASH_PageSize */
        {
                /*地址不对齐多出的count分开处理，不加入这个运算*/
        NumByteToWrite -= count;
        NumOfPage =  NumByteToWrite / SPI_FLASH_PageSize;
        NumOfSingle = NumByteToWrite % SPI_FLASH_PageSize;

        SPI_FLASH_PageWrite(pBuffer, WriteAddr, count);
        WriteAddr +=  count;
        pBuffer += count;
                
                /*把整数页都写了*/
        while (NumOfPage--)
        {
            SPI_FLASH_PageWrite(pBuffer, WriteAddr, SPI_FLASH_PageSize);
            WriteAddr +=  SPI_FLASH_PageSize;
            pBuffer += SPI_FLASH_PageSize;
        }
                /*若有多余的不满一页的数据，把它写完*/
        if (NumOfSingle != 0)
        {
            SPI_FLASH_PageWrite(pBuffer, WriteAddr, NumOfSingle);
        }
        }
    }
}


void SPI_FLASH_BufferRead(uint8_t* pBuffer, uint32_t ReadAddr, uint16_t NumByteToRead)
{
    /* 选择FLASH: CS低电平 */
    SPI_FLASH_CS_LOW();

    /* 发送 读 指令 */
    SPI_FLASH_SendByte(W25X_ReadData);

    /* 发送 读 地址高位 */
    SPI_FLASH_SendByte((ReadAddr & 0xFF0000) >> 16);
    /* 发送 读 地址中位 */
    SPI_FLASH_SendByte((ReadAddr& 0xFF00) >> 8);
    /* 发送 读 地址低位 */
    SPI_FLASH_SendByte(ReadAddr & 0xFF);

        /* 读取数据 */
    while (NumByteToRead--)
    {
        /* 读取一个字节*/
        *pBuffer = SPI_FLASH_SendByte(Dummy_Byte);
        /* 指向下一个字节缓冲区 */
        pBuffer++;
    }

    /* 停止信号 FLASH: CS 高电平 */
    SPI_FLASH_CS_HIGH();
}


/**
* @brief  读取FLASH ID
* @param 	无
* @retval FLASH ID
*/
uint32_t SPI_FLASH_ReadID(void)
{
    uint32_t Temp = 0, Temp0 = 0, Temp1 = 0, Temp2 = 0;

    /* 开始通讯：CS低电平 */
    SPI_FLASH_CS_LOW();

    /* 发送JEDEC指令，读取ID */
    SPI_FLASH_SendByte(W25X_JedecDeviceID);

    /* 读取一个字节数据 */
    Temp0 = SPI_FLASH_SendByte(Dummy_Byte);

    /* 读取一个字节数据 */
    Temp1 = SPI_FLASH_SendByte(Dummy_Byte);

    /* 读取一个字节数据 */
    Temp2 = SPI_FLASH_SendByte(Dummy_Byte);

    /* 停止通讯：CS高电平 */
    SPI_FLASH_CS_HIGH();

        /*把数据组合起来，作为函数的返回值*/
    Temp = (Temp0 << 16) | (Temp1 << 8) | Temp2;

    return Temp;
}

/**
* @brief  读取FLASH Device ID
* @param 	无
* @retval FLASH Device ID
*/
uint32_t SPI_FLASH_ReadDeviceID(void)
{
    uint32_t Temp = 0;

    /* Select the FLASH: Chip Select low */
    SPI_FLASH_CS_LOW();

    /* Send "RDID " instruction */
    Temp = SPI_FLASH_SendByte(W25X_DeviceID);
    Temp = SPI_FLASH_SendByte(Dummy_Byte);
    Temp = SPI_FLASH_SendByte(Dummy_Byte);
    Temp = SPI_FLASH_SendByte(Dummy_Byte);

    /* Read a byte from the FLASH */
    Temp = SPI_FLASH_SendByte(Dummy_Byte);

    /* Deselect the FLASH: Chip Select high */
    SPI_FLASH_CS_HIGH();

    return Temp;
}
/*******************************************************************************
 * Function Name  : SPI_FLASH_StartReadSequence
 * Description    : Initiates a read data byte (READ) sequence from the Flash.
 *                  This is done by driving the /CS line low to select the device,
 *                  then the READ instruction is transmitted followed by 3 bytes
 *                  address. This function exit and keep the /CS line low, so the
 *                  Flash still being selected. With this technique the whole
 *                  content of the Flash is read with a single READ instruction.
 * Input          : - ReadAddr : FLASH's internal address to read from.
 * Output         : None
 * Return         : None
 *******************************************************************************/
void SPI_FLASH_StartReadSequence(uint32_t ReadAddr)
{
    /* Select the FLASH: Chip Select low */
    SPI_FLASH_CS_LOW();

    /* Send "Read from Memory " instruction */
    SPI_FLASH_SendByte(W25X_ReadData);

    /* Send the 24-bit address of the address to read from -----------------------*/
    /* Send ReadAddr high nibble address byte */
    SPI_FLASH_SendByte((ReadAddr & 0xFF0000) >> 16);
    /* Send ReadAddr medium nibble address byte */
    SPI_FLASH_SendByte((ReadAddr& 0xFF00) >> 8);
    /* Send ReadAddr low nibble address byte */
    SPI_FLASH_SendByte(ReadAddr & 0xFF);
}


/**
* @brief  使用SPI读取一个字节的数据
* @param  无
* @retval 返回接收到的数据
*/
uint8_t SPI_FLASH_ReadByte(void)
{
    return (SPI_FLASH_SendByte(Dummy_Byte));
}


/**
* @brief  使用SPI发送一个字节的数据
* @param  byte：要发送的数据
* @retval 返回接收到的数据
*/
uint8_t SPI_FLASH_SendByte(uint8_t byte)
{
    uint8_t retdata = 0;
    uint8_t ret = 0;
    SPI_FLASH_CS_LOW();
    ret = SPI_WriteData(byte);
    ret = SPI_ReaData(&retdata);
    SPI_FLASH_CS_HIGH();
    return retdata;
}

/*******************************************************************************
 * Function Name  : SPI_FLASH_SendHalfWord
 * Description    : Sends a Half Word through the SPI interface and return the
 *                  Half Word received from the SPI bus.
 * Input          : Half Word : Half Word to send.
 * Output         : None
 * Return         : The value of the received Half Word.
 *******************************************************************************/
// uint16_t SPI_FLASH_SendHalfWord(uint16_t HalfWord)
// {

//     SPITimeout = SPIT_FLAG_TIMEOUT;

//     /* Loop while DR register in not emplty */
//     while (SPI_I2S_GetFlagStatus(FLASH_SPI, SPI_I2S_FLAG_TXE) == RESET)
//     {
//         if((SPITimeout--) == 0) return SPI_TIMEOUT_UserCallback(2);
//         }

//     /* Send Half Word through the FLASH_SPI peripheral */
//     SPI_I2S_SendData(FLASH_SPI, HalfWord);

//     SPITimeout = SPIT_FLAG_TIMEOUT;

//     /* Wait to receive a Half Word */
//     while (SPI_I2S_GetFlagStatus(FLASH_SPI, SPI_I2S_FLAG_RXNE) == RESET)
//         {
//         if((SPITimeout--) == 0) return SPI_TIMEOUT_UserCallback(3);
//         }
//     /* Return the Half Word read from the SPI bus */
//     return SPI_I2S_ReceiveData(FLASH_SPI);
// }


/**
* @brief  向FLASH发送 写使能 命令
* @param  none
* @retval none
*/
void SPI_FLASH_WriteEnable(void)
{
/* 通讯开始：CS低 */
    SPI_FLASH_CS_LOW();

    /* 发送写使能命令*/
    SPI_FLASH_SendByte(W25X_WriteEnable);

    /*通讯结束：CS高 */
    SPI_FLASH_CS_HIGH();
}

/**
// * @brief  等待WIP(BUSY)标志被置0，即等待到FLASH内部数据写入完毕
// * @param  none
// * @retval none
// */
// void SPI_FLASH_WaitForWriteEnd(void)
// {
//     uint8_t FLASH_Status = 0;

//     /* 选择 FLASH: CS 低 */
//     SPI_FLASH_CS_LOW();

//     /* 发送 读状态寄存器 命令 */
//     SPI_FLASH_SendByte(W25X_ReadStatusReg);

//     SPITimeout = SPIT_FLAG_TIMEOUT;
//     /* 若FLASH忙碌，则等待 */
//     do
//     {
//         /* 读取FLASH芯片的状态寄存器 */
//         FLASH_Status = SPI_FLASH_SendByte(Dummy_Byte);	 

//         {
//         if((SPITimeout--) == 0) 
//         {
//             SPI_TIMEOUT_UserCallback(4);
//             return;
//         }
//         } 
//     }
//     while ((FLASH_Status & WIP_Flag) == SET); /* 正在写入标志 */

//     /* 停止信号  FLASH: CS 高 */
//     SPI_FLASH_CS_HIGH();
// }


//进入掉电模式
void SPI_Flash_PowerDown(void)   
{ 
/* 选择 FLASH: CS 低 */
    SPI_FLASH_CS_LOW();

    /* 发送 掉电 命令 */
    SPI_FLASH_SendByte(W25X_PowerDown);

    /* 停止信号  FLASH: CS 高 */
    SPI_FLASH_CS_HIGH();
}   

/* Wakeup */
//void SPI_Flash_WAKEUP(void)
//{
//    /*选择 FLASH: CS 低 */
//    SPI_FLASH_CS_LOW();
//
//    /* 发上 上电 命令 */
//    SPI_FLASH_SendByte(W25X_ReleasePowerDown);
//
//    /* 停止信号 FLASH: CS 高 */
//    SPI_FLASH_BufferRead();                   //等待TRES1
//}

void W25Q_ReadID_Test(void)
{
    static Test_times = 0;
    uint32_t FlashID = 0;
    uint32_t DeviceID = 0;
    if(Test_times < W25Q_TEST_1_TIMES)
    {
        FLASH_INFO("W25Q128 Read ID Test Start!");
        DeviceID = SPI_FLASH_ReadDeviceID();
        FLASH_INFO("W25Q128 DeviceID = 0x%X",DeviceID);
        HAL_Delay(200);
        FlashID = SPI_FLASH_ReadID();
        FLASH_INFO("W25Q128 FlashID = 0x%X",FlashID);
    }
    Test_times++;
}

/**
* @brief  等待超时回调函数
* @param  None.
* @retval None.
*/
static uint16_t SPI_TIMEOUT_UserCallback(uint8_t errorCode)
{
    FLASH_ERROR("SPI Timeout! ErrorCode = %d",errorCode);
    return 0;
}
    
/*********************************************END OF FILE**********************/

