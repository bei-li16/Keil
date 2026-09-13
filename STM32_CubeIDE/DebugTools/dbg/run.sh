#!/bin/bash
# 放行芯片自由运行（清残留硬件断点/观察点 + 复位 + go）
# 关键点：FPB/DWT 调试寄存器跨系统复位不清零，GDB 会话异常退出时残留的
# 断点会让 CPU 复位后一跑到断点地址就被冻住 —— 所以放行前必须手动清除
HERE=$(cd "$(dirname "$0")" && pwd); source "$HERE/env.sh"
"$HERE/server-stop.sh" > /dev/null
cat > /tmp/jlink_run.txt <<'EOF'
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
"$JLINK_EXE" -if SWD -speed 1000 -device "$DBG_DEVICE" -commanderscript /tmp/jlink_run.txt 2>&1 | grep -E "O.K|Error" | head -3
echo "--- 芯片已清除断点、复位、自由运行（LED 应闪烁）---"
