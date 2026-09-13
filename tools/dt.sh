#!/usr/bin/env bash
# dt.sh - thin forwarder for Git Bash / WSL: calls the Windows dt.bat
# Usage: ./dt.sh <subcommand> [args...]    behavior is identical to dt.bat
# Note:  dt.bat and paths.bat are pure ASCII (English comments/output), so no
#        console can garble them; success is judged by the exit code and the
#        [OK] / [ERROR] / [FAIL] markers
HERE=$(cd "$(dirname "$0")" && pwd)
exec cmd //c "$(cygpath -w "$HERE/dt.bat")" "$@"
