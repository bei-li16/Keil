@echo off
rem gcov-rtt-capture.bat —— 方案 C(RTT 流式)的主机端采集
rem 前置:固件为 GCOV_TRANSPORT=rtt 构建产物;J-Link 已接板
rem 用法: 先用 JLinkRTTLogger 挂上通道 0,再复位/运行板子并触发导出
rem       (GDB: set var gcov_stream_enable=1; call bsp_gcov_dump_all()
rem        或直接跑一段时间让 Task1000ms 周期导出)
rem 产物: gcov_blob.bin -> python gcov-extract.py gcov_blob.bin -o build -> make gcov-report

rem JLinkRTTLogger 随 J-Link 驱动包分发,按实际安装位置调整
set "JLINK_DIR=C:\Program Files\SEGGER\JLink"
if not exist "%JLINK_DIR%\JLinkRTTLogger.exe" set "JLINK_DIR=C:\Program Files (x86)\SEGGER\JLink"
if not exist "%JLINK_DIR%\JLinkRTTLogger.exe" (
    echo [!] 未找到 JLinkRTTLogger.exe,请把 JLINK_DIR 改成本机 J-Link 驱动目录
    exit /b 1
)

"%JLINK_DIR%\JLinkRTTLogger.exe" -Device STM32F429IG -If SWD -Speed 1000 -RTTChannel 0 gcov_blob.bin
