#!/bin/bash
# 一键调试入口：编译 -> 探针唤醒 -> 烧录停到 main
# 用法: ./debug.sh [clean]     带 clean 参数则全量重建
# 执行后芯片停在 main()，可直接用 gdb-run.sh 跑自定义调试脚本
HERE=$(cd "$(dirname "$0")" && pwd)
"$HERE/build.sh" "$@" || exit 1
"$HERE/probe-reset.sh" || exit 1
cat > /tmp/flash_only.gdb <<'EOF'
set pagination off
target extended-remote localhost:3333
monitor reset
load
break main
continue
EOF
"$HERE/gdb-run.sh" /tmp/flash_only.gdb 60 | tail -3
echo "--- 就绪：芯片停在 main，可执行 ./gdb-run.sh <你的脚本.gdb> ---"
