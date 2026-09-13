#!/bin/bash
# 命令行构建工程（等同 CubeIDE 的 Build）
# 用法: ./build.sh [clean]
HERE=$(cd "$(dirname "$0")" && pwd); source "$HERE/env.sh"
export PATH="$GCC_BIN:$PATH"
cd "$PROJ/Debug" || exit 1
if [ "$1" = clean ]; then "$MAKE" clean || exit 1; fi
"$MAKE" -j8 all 2>&1 | tail -15
ls -l "$ELF"
