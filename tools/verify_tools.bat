@echo off
setlocal DisableDelayedExpansion
if not exist "%~dp0bin\python\python.exe" (
    echo [verify][ERROR] Missing bundled Python: copy the complete tools directory. 1>&2
    exit /b 2
)
"%~dp0bin\python\python.exe" -B "%~dp0verify_tools.py" %*
exit /b %errorlevel%
