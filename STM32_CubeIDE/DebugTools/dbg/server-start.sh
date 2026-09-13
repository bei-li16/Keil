#!/bin/bash
# 启动 J-Link GDB Server（后台，写日志到 /tmp/gdbserver_ai.log）
# 注意：启动前确保没有其它程序占用 J-Link（IDE 调试、J-Link Commander 等）
HERE=$(cd "$(dirname "$0")" && pwd); source "$HERE/env.sh"
if powershell -NoProfile -Command "(Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue | Where-Object LocalPort -eq $DBG_PORT | Measure-Object).Count" | grep -q '[1-9]'; then
  echo "端口 $DBG_PORT 已被占用，先执行 server-stop.sh"; exit 1
fi
"$GDB_SERVER" -select USB -device "$DBG_DEVICE" -if "$DBG_IF" -speed "$DBG_SPEED" \
  -port "$DBG_PORT" -logtofile -log /tmp/gdbserver_ai.log > /tmp/gdbserver_ai_stdout.log 2>&1 &
sleep 5
if grep -q "Waiting for GDB connection" /tmp/gdbserver_ai_stdout.log; then
  echo "OK: server 已监听 $DBG_PORT，日志 /tmp/gdbserver_ai.log"
else
  echo "启动异常，输出:"; cat /tmp/gdbserver_ai_stdout.log; exit 1
fi
