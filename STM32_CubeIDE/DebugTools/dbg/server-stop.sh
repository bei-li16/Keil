#!/bin/bash
# 停止 GDB Server 并释放端口
powershell -NoProfile -Command "Get-Process JLinkGDBServerCL -ErrorAction SilentlyContinue | Stop-Process -Force"
sleep 1; echo "server 已停止"
