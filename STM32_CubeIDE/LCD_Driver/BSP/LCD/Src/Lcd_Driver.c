/*
 * Lcd_Driver.c
 *
 *  Created on: Feb 20, 2025
 *      Author: 18283
 */

#include "Lcd_Driver.h"
#include <stdint.h>


//本测试程序使用的是模拟SPI接口驱动
//可自由更改接口IO配置，使用任意最少4 IO即可完成本款液晶驱动显示
/******************************************************************************
接口定义在Lcd_Driver.h内定义，请根据接线修改并修改相应IO初始化LCD_GPIO_Init()
#define LCD_CTRL   	  	GPIOB		//定义TFT数据端口
#define LCD_LED        	GPIO_Pin_9  //PB9--->>TFT --BL
#define LCD_RS         	GPIO_Pin_10	//PB11--->>TFT --RS/DC
#define LCD_CS        	GPIO_Pin_11 //PB11--->>TFT --CS/CE
#define LCD_RST     		GPIO_Pin_12	//PB10--->>TFT --RST
#define LCD_SCL        	GPIO_Pin_13	//PB13--->>TFT --SCL/SCK
#define LCD_SDA        	GPIO_Pin_15	//PB15 MOSI--->>TFT --SDA/DIN
*******************************************************************************/
 
void delay_ms(uint16_t ms)
{
    HAL_Delay(ms);
}
 
// //液晶IO初始化配置
// void LCD_GPIO_Init(void)
// {
//     GPIO_InitTypeDef  GPIO_InitStructure;
//     RCC_AHB1PeriphClockCmd( RCC_AHB1Periph_GPIOA|RCC_AHB1Periph_GPIOB ,ENABLE);
//     //GPIO初始化设置
//     GPIO_InitStructure.GPIO_Pin = LCD_PIN_LED|LCD_PIN_SCL|LCD_PIN_SDA|LCD_PIN_RS|LCD_PIN_RST|LCD_PIN_CS;
//     GPIO_InitStructure.GPIO_Mode = GPIO_Mode_OUT;					//普通输出模式
//     GPIO_InitStructure.GPIO_OType = GPIO_OType_PP;					//推挽输出
//     GPIO_InitStructure.GPIO_Speed = GPIO_Speed_100MHz;			    //设置引脚速率为100MHz
//     GPIO_InitStructure.GPIO_PuPd = GPIO_PuPd_UP;					//设置引脚为上拉模式
//     GPIO_Init(LCD_CTRLA, &GPIO_InitStructure);						//初始化
//     GPIO_InitStructure.GPIO_Pin = LCD_PIN_RST|LCD_PIN_CS;
//     GPIO_Init(LCD_CTRLB, &GPIO_InitStructure);						//初始化
// }

//向SPI总线传输一个8位数据
void  SPI_WriteData(uint8_t Data)
{
#if (VIRTUAL_SPI_LCD == STD_ON)
    unsigned char i=0;
    for(i=8;i>0;i--)
    {
        if(Data&0x80)
        {
            LCD_SDA_SET; //输出数据
        }
        else
        {
            LCD_SDA_CLR;
        }
        LCD_SCL_CLR;       
        LCD_SCL_SET;
        Data<<=1; 
    }
#else
    extern uint8_t LCD_Tx_Status;
    uint8_t *pData = &Data;
    while(LCD_Tx_Status != STD_ON);
    LCD_Tx_Status = STD_OFF;
    HAL_SPI_Transmit_DMA(&LCD_SPI, pData, 1);
#endif
}
 
 //向液晶屏写一个8位指令
 void Lcd_WriteIndex(uint8_t Index)
 {
    //SPI 写命令时序开始
    LCD_CS_CLR;
    LCD_RS_CLR;
    SPI_WriteData(Index);
    LCD_CS_SET;
 }
 
 //向液晶屏写一个8位数据
 void Lcd_WriteData(uint8_t Data)
 {
    LCD_CS_CLR;
    LCD_RS_SET;
    SPI_WriteData(Data);
    LCD_CS_SET; 
 }
 //向液晶屏写一个16位数据
 void LCD_WriteData_16Bit(uint16_t Data)
 {
    LCD_CS_CLR;
    LCD_RS_SET;
    SPI_WriteData(Data>>8); 	//写入高8位数据
    SPI_WriteData(Data); 			//写入低8位数据
    LCD_CS_SET; 
 }
 
void Lcd_WriteReg(uint8_t Index,uint8_t Data)
{
    Lcd_WriteIndex(Index);
    Lcd_WriteData(Data);
}
 
void Lcd_Reset(void)
{
     LCD_RST_CLR;
     HAL_Delay(100);
     LCD_RST_SET;
     HAL_Delay(100);
}
 
 //LCD Init For 1.44Inch LCD Panel with ST7735R.
 void Lcd_Init(void)
 {	
//     LCD_GPIO_Init();
     Lcd_Reset(); //Reset before LCD Init.
 
     //LCD Init For 1.44Inch LCD Panel with ST7735R.
     Lcd_WriteIndex(0x11);//Sleep exit 
     HAL_Delay (120);
     //ST7735R Frame Rate
     Lcd_WriteIndex(0xB1); 
     Lcd_WriteData(0x01); 
     Lcd_WriteData(0x2C); 
     Lcd_WriteData(0x2D); 
 
     Lcd_WriteIndex(0xB2); 
     Lcd_WriteData(0x01); 
     Lcd_WriteData(0x2C); 
     Lcd_WriteData(0x2D); 
 
     Lcd_WriteIndex(0xB3); 
     Lcd_WriteData(0x01); 
     Lcd_WriteData(0x2C); 
     Lcd_WriteData(0x2D); 
     Lcd_WriteData(0x01); 
     Lcd_WriteData(0x2C); 
     Lcd_WriteData(0x2D); 
     
     Lcd_WriteIndex(0xB4); //Column inversion 
     Lcd_WriteData(0x07); 
     
     //ST7735R Power Sequence
     Lcd_WriteIndex(0xC0); 
     Lcd_WriteData(0xA2); 
     Lcd_WriteData(0x02); 
     Lcd_WriteData(0x84); 
     Lcd_WriteIndex(0xC1); 
     Lcd_WriteData(0xC5); 
 
     Lcd_WriteIndex(0xC2); 
     Lcd_WriteData(0x0A); 
     Lcd_WriteData(0x00); 
 
     Lcd_WriteIndex(0xC3); 
     Lcd_WriteData(0x8A); 
     Lcd_WriteData(0x2A); 
     Lcd_WriteIndex(0xC4); 
     Lcd_WriteData(0x8A); 
     Lcd_WriteData(0xEE); 
     
     Lcd_WriteIndex(0xC5); //VCOM 
     Lcd_WriteData(0x0E); 
     
     Lcd_WriteIndex(0x36); //MX, MY, RGB mode 
     Lcd_WriteData(0xC8); 
     
     //ST7735R Gamma Sequence
     Lcd_WriteIndex(0xe0); 
     Lcd_WriteData(0x0f); 
     Lcd_WriteData(0x1a); 
     Lcd_WriteData(0x0f); 
     Lcd_WriteData(0x18); 
     Lcd_WriteData(0x2f); 
     Lcd_WriteData(0x28); 
     Lcd_WriteData(0x20); 
     Lcd_WriteData(0x22); 
     Lcd_WriteData(0x1f); 
     Lcd_WriteData(0x1b); 
     Lcd_WriteData(0x23); 
     Lcd_WriteData(0x37); 
     Lcd_WriteData(0x00); 	
     Lcd_WriteData(0x07); 
     Lcd_WriteData(0x02); 
     Lcd_WriteData(0x10); 
 
     Lcd_WriteIndex(0xe1); 
     Lcd_WriteData(0x0f); 
     Lcd_WriteData(0x1b); 
     Lcd_WriteData(0x0f); 
     Lcd_WriteData(0x17); 
     Lcd_WriteData(0x33); 
     Lcd_WriteData(0x2c); 
     Lcd_WriteData(0x29); 
     Lcd_WriteData(0x2e); 
     Lcd_WriteData(0x30); 
     Lcd_WriteData(0x30); 
     Lcd_WriteData(0x39); 
     Lcd_WriteData(0x3f); 
     Lcd_WriteData(0x00); 
     Lcd_WriteData(0x07); 
     Lcd_WriteData(0x03); 
     Lcd_WriteData(0x10);  
     
     Lcd_WriteIndex(0x2a);
     Lcd_WriteData(0x00);
     Lcd_WriteData(0x00);
     Lcd_WriteData(0x00);
     Lcd_WriteData(0x7f);
 
     Lcd_WriteIndex(0x2b);
     Lcd_WriteData(0x00);
     Lcd_WriteData(0x00);
     Lcd_WriteData(0x00);
     Lcd_WriteData(0x9f);
     
     Lcd_WriteIndex(0xF0); //Enable test command  
     Lcd_WriteData(0x01); 
     Lcd_WriteIndex(0xF6); //Disable ram power save mode 
     Lcd_WriteData(0x00); 
     
     Lcd_WriteIndex(0x3A); //65k mode 
     Lcd_WriteData(0x05); 
     
     
     Lcd_WriteIndex(0x29);//Display on	 
 }
 
 
 /*************************************************
 函数名：LCD_Set_Region
 功能：设置lcd显示区域，在此区域写点数据自动换行
 入口参数：xy起点和终点
 返回值：无
 *************************************************/
void Lcd_SetRegion(uint16_t x_start,uint16_t y_start,uint16_t x_end,uint16_t y_end)
{		
    Lcd_WriteIndex(0x2a);
    Lcd_WriteData(0x00);
    Lcd_WriteData(x_start+2);
    Lcd_WriteData(0x00);
    Lcd_WriteData(x_end+2);

    Lcd_WriteIndex(0x2b);
    Lcd_WriteData(0x00);
    Lcd_WriteData(y_start+3);
    Lcd_WriteData(0x00);
    Lcd_WriteData(y_end+3);
    
    Lcd_WriteIndex(0x2c);

}
 
/*************************************************
 函数名：LCD_Set_XY
功能：设置lcd显示起始点
入口参数：xy坐标
返回值：无
*************************************************/
void Lcd_SetXY(uint16_t x,uint16_t y)
{
    Lcd_SetRegion(x,y,x,y);
}
 
     
 /*************************************************
 函数名：LCD_DrawPoint
 功能：画一个点
 入口参数：无
 返回值：无
 *************************************************/
 void Gui_DrawPoint(uint16_t x,uint16_t y,uint16_t Data)
 {
     Lcd_SetRegion(x,y,x+1,y+1);
     LCD_WriteData_16Bit(Data);
 
 }    
 
 /*************************************************
 函数名：LCD_DrawBMP_8BIT
 功能：画一个图 使用8位数组
 入口参数：无
 返回值：无
 *************************************************/
 void LCD_DrawBMP_8BIT(const unsigned char *p)
 {
   int i; 
     unsigned char picH,picL;
 //	Lcd_Clear(WHITE); 															//清屏 
     Lcd_SetRegion(0,0,127,79);		//坐标设置
     for(i=0;i<128*80;i++)
     {
         picL=*(p+i*2);														//数据低位在前
         picH=*(p+i*2+1);				
         LCD_WriteData_16Bit(picH<<8|picL);  						
     }	
 }
 
 /*************************************************
 函数名：LCD_DrawBMP_16BIT
 功能：画一个图 使用16位数组
 入口参数：无
 返回值：无
 *************************************************/
 void LCD_DrawBMP_16BIT(const unsigned short *p)
 {
    int i; 
    unsigned short Pic;
//	Lcd_Clear(WHITE); 															//清屏 
    Lcd_SetRegion(0,24,127,103);		//坐标设置
    for(i=0;i<128*80;i++)
    {
        Pic=*(p+i);			
        LCD_WriteData_16Bit(Pic);  						
    }	
 ////	   unsigned int i,m;
 ////   Lcd_SetRegion(0,0,X_MAX_PIXEL-1,Y_MAX_PIXEL-1);
 ////   Lcd_WriteIndex(0x2C);
 ////   for(i=0;i<X_MAX_PIXEL;i++)
 ////    for(m=0;m<Y_MAX_PIXEL;m++)
 ////    {	
 ////	  	LCD_WriteData_16Bit(Color);
 ////    } 
 }
 /*************************************************
 函数名：LCD_DrawBMP_BAPBIT
 功能：画一个图 使用16位数组
 入口参数：无
 返回值：无
 *************************************************/
void LCD_DrawBMP_BAPBIT(const unsigned short *p)
{
    int i; 
    unsigned short Pic;
//	Lcd_Clear(WHITE); 															//清屏 
    Lcd_SetRegion(0,16,127,112);		//坐标设置
    for(i=0;i<128*96;i++)
    {
        Pic=*(p+i);			
        LCD_WriteData_16Bit(Pic);  						
    }
}

/*****************************************
 函数功能：读TFT某一点的颜色                          
出口参数：color  点颜色值                                 
******************************************/
unsigned int Lcd_ReadPoint(uint16_t x,uint16_t y)
{
    unsigned int Data;
    Lcd_SetXY(x,y);

    //Lcd_ReadData();//丢掉无用字节
    //Data=Lcd_ReadData();
    Lcd_WriteData(Data);
    return Data;
}
/*************************************************
 函数名：Lcd_Clear
功能：全屏清屏函数
入口参数：填充颜色COLOR
返回值：无
*************************************************/
void Lcd_Clear(uint16_t Color)               
{	
    unsigned int i,m;
    Lcd_SetRegion(0,0,X_MAX_PIXEL-1,Y_MAX_PIXEL-1);
    Lcd_WriteIndex(0x2C);
    for(i=0;i<X_MAX_PIXEL;i++)
        for(m=0;m<Y_MAX_PIXEL;m++)
        {	
            LCD_WriteData_16Bit(Color);
        }   
}
 
 
