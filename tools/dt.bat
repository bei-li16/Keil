@echo off
setlocal DisableDelayedExpansion
REM Keep the entry-point path and original arguments intact (no SHIFT).
if not exist "%~dp0bin\python\python.exe" (
    echo [dt][ERROR] Missing bundled Python: copy the complete tools directory. 1>&2
    exit /b 2
)
"%~dp0bin\python\python.exe" -B "%~dp0dt.py" %*
exit /b %errorlevel%
