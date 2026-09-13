#!/bin/bash
# 看日志一条龙：放行芯片自由运行 -> 串口监听统计
# 用法: ./logs.sh [监听秒数，默认15]
# 前提：固件已烧录；判据——脚本开头会先放行，若 LED 不闪说明固件没跑起来
HERE=$(cd "$(dirname "$0")" && pwd)
"$HERE/run.sh" > /dev/null 2>&1
sleep 1
powershell -NoProfile -ExecutionPolicy Bypass -File "$HERE/com3-listen2.ps1" -sec "${1:-15}"
