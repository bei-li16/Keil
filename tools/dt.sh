#!/usr/bin/env bash
# dt.sh - Git Bash / WSL 下的 dt 薄转发壳:转调 Windows 版 dt.bat
# 用法: ./dt.sh <子命令> [参数...]    行为与 dt.bat 完全一致
# 说明: dt.bat 输出为 GBK 中文,Git Bash 终端可能显示乱码;
#       判断成败以退出码和 [OK] / [ERROR] / [FAIL] ASCII 标记为准
HERE=$(cd "$(dirname "$0")" && pwd)
exec cmd //c "$(cygpath -w "$HERE/dt.bat")" "$@"
