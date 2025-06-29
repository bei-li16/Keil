/* USER CODE BEGIN Header */
/**
  ******************************************************************************
  * File Name          : freertos.c
  * Description        : Code for freertos applications
  ******************************************************************************
  * @attention
  *
  * Copyright (c) 2025 STMicroelectronics.
  * All rights reserved.
  *
  * This software is licensed under terms that can be found in the LICENSE file
  * in the root directory of this software component.
  * If no LICENSE file comes with this software, it is provided AS-IS.
  *
  ******************************************************************************
  */
/* USER CODE END Header */

/* Includes ------------------------------------------------------------------*/
#include "FreeRTOS.h"
#include "task.h"
#include "main.h"
//#include "cmsis_os.h"

/* Private includes ----------------------------------------------------------*/
/* USER CODE BEGIN Includes */
#include "user_task.h"
/* #include "cmsis_os.h" */
#include "FreeRTOS.h"
#include "task.h"
#include "timers.h"
#include "queue.h"
#include "semphr.h"
#include "event_groups.h"
/* USER CODE END Includes */

/* Private typedef -----------------------------------------------------------*/
/* USER CODE BEGIN PTD */

/* USER CODE END PTD */

/* Private define ------------------------------------------------------------*/
/* USER CODE BEGIN PD */

/* USER CODE END PD */

/* Private macro -------------------------------------------------------------*/
/* USER CODE BEGIN PM */

/* USER CODE END PM */

/* Private variables ---------------------------------------------------------*/
/* USER CODE BEGIN Variables */
TaskHandle_t user50msTask;
TaskHandle_t user100msTask;
TaskHandle_t user1000msTask;
/* USER CODE END Variables */
TaskHandle_t defaultTaskHandle;

/* Private function prototypes -----------------------------------------------*/
/* USER CODE BEGIN FunctionPrototypes */

/* USER CODE END FunctionPrototypes */

void StartDefaultTask(void * argument);

void MX_FREERTOS_Init(void); /* (MISRA C 2004 rule 8.1) */

/* GetIdleTaskMemory prototype (linked to static allocation support) */
void vApplicationGetIdleTaskMemory( StaticTask_t **ppxIdleTaskTCBBuffer, StackType_t **ppxIdleTaskStackBuffer, uint32_t *pulIdleTaskStackSize );

/* USER CODE BEGIN GET_IDLE_TASK_MEMORY */
static StaticTask_t xIdleTaskTCBBuffer;
static StackType_t xIdleStack[configMINIMAL_STACK_SIZE];

void vApplicationGetIdleTaskMemory( StaticTask_t **ppxIdleTaskTCBBuffer, StackType_t **ppxIdleTaskStackBuffer, uint32_t *pulIdleTaskStackSize )
{
  *ppxIdleTaskTCBBuffer = &xIdleTaskTCBBuffer;
  *ppxIdleTaskStackBuffer = &xIdleStack[0];
  *pulIdleTaskStackSize = configMINIMAL_STACK_SIZE;
  /* place for user code */
}
/* USER CODE END GET_IDLE_TASK_MEMORY */

/**
  * @brief  FreeRTOS initialization
  * @param  None
  * @retval None
  */
void MX_FREERTOS_Init(void) {
  /* USER CODE BEGIN Init */
  Led_Init();
  Log_Init();
  SPI_FLASH_Init();
  /* USER CODE END Init */

  /* USER CODE BEGIN RTOS_MUTEX */
  /* add mutexes, ... */
  /* USER CODE END RTOS_MUTEX */

  /* USER CODE BEGIN RTOS_SEMAPHORES */
  /* add semaphores, ... */
  /* USER CODE END RTOS_SEMAPHORES */

  /* USER CODE BEGIN RTOS_TIMERS */
  /* start timers, add new ones, ... */
  /* USER CODE END RTOS_TIMERS */

  /* USER CODE BEGIN RTOS_QUEUES */
  /* add queues, ... */
  /* USER CODE END RTOS_QUEUES */

  /* Create the thread(s) */
  /* definition and creation of defaultTask */
  // osThreadDef(defaultTask, StartDefaultTask, osPriorityNormal, 0, 128);
  // defaultTaskHandle = osThreadCreate(osThread(defaultTask), NULL);
  xTaskCreate(
              StartDefaultTask,   /* Function that implements the task. */
              "defaultTask",     /* Text name for the task. */
              128,               /* Stack size in words, not bytes. */
              NULL,              /* Parameter passed into the task. */
              TASKDEFAULT_PRIORITY,  /* Priority at which the task is created. */
              NULL               /* Pointer to the task's stack. */
              );

  /* USER CODE BEGIN RTOS_THREADS */
  // osThreadDef(TASK100MS_NAME, Task100ms, TASK100MS_PRIORITY, 0, TASK100MS_STACK_SIZE);
  // defaultTaskHandle = osThreadCreate(osThread(TASK100MS_NAME), NULL);
  xTaskCreate(
              Task100ms,       /* Function that implements the task. */
              "Task100ms",     /* Text name for the task. */
              TASK100MS_STACK_SIZE, /* Stack size in words, not bytes. */
              NULL,             /* Parameter passed into the task. */
              TASK100MS_PRIORITY, /* Priority at which the task is created. */
              NULL              /* Pointer to the task's stack. */
              );

  // osThreadDef(TASK1000MS_NAME, Task1000ms, TASK1000MS_PRIORITY, 0, TASK1000MS_STACK_SIZE);
  // defaultTaskHandle = osThreadCreate(osThread(TASK1000MS_NAME), NULL);
  xTaskCreate(
              Task1000ms,      /* Function that implements the task. */
              "Task1000ms",    /* Text name for the task. */
              TASK1000MS_STACK_SIZE, /* Stack size in words, not bytes. */
              NULL,             /* Parameter passed into the task. */
              TASK1000MS_PRIORITY, /* Priority at which the task is created. */
              NULL              /* Pointer to the task's stack. */
              );
  /* USER CODE END RTOS_THREADS */

}

/* USER CODE BEGIN Header_StartDefaultTask */
/**
  * @brief  Function implementing the defaultTask thread.
  * @param  argument: Not used
  * @retval None
  */
/* USER CODE END Header_StartDefaultTask */
void StartDefaultTask(void * argument)
{
  /* USER CODE BEGIN StartDefaultTask */
  /* Infinite loop */
  for(;;)
  {
    // osDelay(1);
    vTaskDelay(1);
  }
  /* USER CODE END StartDefaultTask */
}

/* Private application code --------------------------------------------------*/
/* USER CODE BEGIN Application */

/* USER CODE END Application */
