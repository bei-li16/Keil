#!/usr/bin/env bash
# Run Windows Python directly; preserve GDB expressions without CMD expansion.
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
if command -v cygpath >/dev/null 2>&1; then
    winpath() { cygpath -aw "$1"; }
elif command -v wslpath >/dev/null 2>&1; then
    winpath() { wslpath -aw "$1"; }
else
    echo '[dt][ERROR] requires Git Bash or WSL with Windows interop' >&2
    exit 2
fi
args=()
for arg in "$@"; do
    if [[ -e "$arg" ]]; then arg=$(winpath "$arg"); fi
    args+=("$arg")
done
export MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL='*'
if [[ ! -f "$HERE/bin/python/python.exe" ]]; then
    echo '[dt][ERROR] Missing bundled Python: copy the complete tools directory.' >&2
    exit 2
fi
exec "$HERE/bin/python/python.exe" -B "$(winpath "$HERE/dt.py")" "${args[@]}"
