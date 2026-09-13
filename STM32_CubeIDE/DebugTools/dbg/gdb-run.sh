#!/bin/bash
# 用指定 GDB 脚本做批量调试
# 用法: ./gdb-run.sh <script.gdb> [超时秒数，默认120]
HERE=$(cd "$(dirname "$0")" && pwd); source "$HERE/env.sh"
SCRIPT=$1; TIMEOUT=${2:-120}
timeout "$TIMEOUT" "$GDB" -nx -batch -x "$SCRIPT" "$ELF" 2>&1 || "$HERE/server-stop.sh" > /dev/null
