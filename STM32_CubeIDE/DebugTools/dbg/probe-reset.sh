#!/bin/bash
# 探针恢复 + server 重启（克隆 J-Link V8 每次会话后都会退化，调试前先跑这个）
HERE=$(cd "$(dirname "$0")" && pwd); source "$HERE/env.sh"
cat > /tmp/jlink_rec.txt <<'EOF'
connect
STM32F429ZI
S
1000
h
r
w4 0xE0002000 0x3
w4 0xE0001020 0x0
w4 0xE0001030 0x0
w4 0xE0001040 0x0
w4 0xE0001050 0x0
g
qc
EOF

JLINK_EXE=$(dirname "$GDB_SERVER")/JLink.exe
"$JLINK_EXE" -if SWD -speed 1000 -device "$DBG_DEVICE" -commanderscript /tmp/jlink_rec.txt 2>&1 | grep -E "O.K|identified|Error" | head -3
"$HERE/server-stop.sh" > /dev/null; sleep 1
"$HERE/server-start.sh"
