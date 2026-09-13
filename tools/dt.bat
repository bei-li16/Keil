@echo off
setlocal
REM ==========================================================================
 REM  dt.bat - STM32 console/AI debug toolkit, single entry (subcommand dispatch)
 REM  All configuration lives in config\paths.bat; firmware/elf/variable names
 REM  are always passed as arguments.
 REM  This file is pure ASCII on purpose: no encoding can garble it (a .bat with
 REM  non-ASCII text breaks under some console codepages, verified).
 REM
 REM  Usage: dt <subcommand> [args...]      (no args shows this help)
 REM   check                        J-Link link self-test
 REM   flash [--hold] <fw.hex|.bin> flash; --hold keeps target halted after reset
 REM   server                       start J-Link GDB Server (resident, background)
 REM   rtt [outfile]                capture RTT output (resident, default rtt.log)
 REM   read <elf> <var...>          one-shot variable read
 REM   watch <elf> <var...>         hardware watchpoints on variables (resident, with backtrace)
 REM   gdb <elf> <cmd...>           arbitrary gdb commands (one per arg, auto init/detach)
 REM   ocd-server                   start OpenOCD GDB Server (resident, port 3334)
 REM   ocd-flash <fw> [addr]        OpenOCD flash (bin needs an address)
 REM   uart [args...]               serial capture (resident, e.g.: dt uart --list)
 REM   halt                         halt the running target (stays halted; dt run to resume)
 REM   probe-reset                  probe recovery (mandatory for cloned J-Link V8)
 REM   run                          clear leftover breakpoints/watchpoints, reset and go
 REM   server-stop                  stop J-Link/OpenOCD GDB Server
 REM   go                           resume a halted target without reset (RAM preserved)
 REM   bp <hexaddr> [ms]            one-shot breakpoint via native JLink (gdb route broken on clones)
 REM   step                         single-step one instruction (target left halted)
 REM ==========================================================================

REM ---- load config (shared by all subcommands; help also reports current config) ----
call "%~dp0config\paths.bat"
if errorlevel 1 exit /b 1
 REM  interactive Commander scripts need the interface letter (S=SWD / J=JTAG)
set "IF_LETTER=J"
if /i "%JLINK_IF%"=="SWD" set "IF_LETTER=S"

set "SUB=%~1"
if "%SUB%"=="" goto USAGE
 REM  after shift %1..%9 become the args following the subcommand (%* is not
 REM  affected by shift, see the uart branch)
shift

if /i "%SUB%"=="check"      goto S_CHECK
if /i "%SUB%"=="flash"      goto S_FLASH
if /i "%SUB%"=="server"     goto S_SERVER
if /i "%SUB%"=="rtt"        goto S_RTT
if /i "%SUB%"=="read"       goto S_READ
if /i "%SUB%"=="watch"      goto S_WATCH
if /i "%SUB%"=="gdb"        goto S_GDB
if /i "%SUB%"=="ocd-server" goto S_OCDSERVER
if /i "%SUB%"=="ocd-flash"  goto S_OCDFLASH
if /i "%SUB%"=="uart"       goto S_UART
if /i "%SUB%"=="halt"       goto S_HALT
if /i "%SUB%"=="probe-reset" goto S_PROBERESET
if /i "%SUB%"=="run"        goto S_RUN
if /i "%SUB%"=="server-stop" goto S_SERVERSTOP
if /i "%SUB%"=="go"         goto S_GO
if /i "%SUB%"=="bp"         goto S_BP
if /i "%SUB%"=="step"       goto S_STEP
goto USAGE

REM ==================== check: J-Link link self-test ====================
:S_CHECK
call :NEED_JLINK || exit /b 1
 REM  exclusive probe access: a running GDB Server on the same probe corrupts the link
call :STOP_GDBSERVER_QUIET
 REM  generate Commander commands on the fly: > overwrites the first line, >>
 REM  appends; never put a REM at the end of these lines
set "CMDF=%TEMP%\dt_check.jlink"
>  "%CMDF%" echo device %JLINK_DEVICE%
>> "%CMDF%" echo si %JLINK_IF%
>> "%CMDF%" echo speed %JLINK_SPEED%
>> "%CMDF%" echo connect
>> "%CMDF%" echo h
>> "%CMDF%" echo regs
>> "%CMDF%" echo g
>> "%CMDF%" echo q
echo [check] connection test: %JLINK_DEVICE% / %JLINK_IF% / %JLINK_SPEED%kHz
"%JLINK_DIR%\JLink.exe" -CommandFile "%CMDF%" -AutoConnect 1 -ExitOnError 1 -NoGui 1
if errorlevel 1 (
    echo [check][FAIL] connect failed: check USB LED / power / interface mode and wiring ^(SWD needs SWDIO+SWCLK+GND^) / probe busy
    exit /b 1
)
echo [check][OK] J-Link link OK
exit /b 0

REM ==================== flash: J-Link flash ====================
:S_FLASH
call :NEED_JLINK || exit /b 1
 REM  exclusive probe access: flashing while a GDB Server runs corrupts the link
call :STOP_GDBSERVER_QUIET
set "HOLD=0"
if /i "%~1"=="--hold" set "HOLD=1"
if /i "%~1"=="--hold" shift
set "IMG=%~1"
if "%IMG%"=="" (
    echo [flash][ERROR] usage: dt flash ^<fw.hex or .bin^>
    exit /b 1
)
if not exist "%IMG%" (
    echo [flash][ERROR] file not found: %IMG%
    exit /b 1
)
set "CMDF=%TEMP%\dt_flash.jlink"
 REM  h: halt before writing; loadfile: auto-detects HEX/BIN by extension;
 REM  r: reset; g: go (skipped when --hold so the target stays halted)
>  "%CMDF%" echo device %JLINK_DEVICE%
>> "%CMDF%" echo si %JLINK_IF%
>> "%CMDF%" echo speed %JLINK_SPEED%
>> "%CMDF%" echo connect
>> "%CMDF%" echo h
>> "%CMDF%" echo loadfile "%IMG%"
>> "%CMDF%" echo r
if "%HOLD%"=="0" >> "%CMDF%" echo g
>> "%CMDF%" echo q
echo [flash] flashing %IMG% ^(%JLINK_DEVICE%, %JLINK_IF%, %JLINK_SPEED%kHz^) ...
"%JLINK_DIR%\JLink.exe" -CommandFile "%CMDF%" -AutoConnect 1 -ExitOnError 1 -NoGui 1
if errorlevel 1 (
    echo [flash][ERROR] flash failed: check J-Link USB / target power / interface mode and wiring
    exit /b 1
)
if "%HOLD%"=="1" (echo [flash][OK] flashed, target kept halted; use dt run to resume) else echo [flash][OK] flashed and reset to run
exit /b 0

REM ==================== server: J-Link GDB Server ====================
:S_SERVER
call :NEED_JLINK || exit /b 1
if not exist "%JLINK_DIR%\JLinkGDBServerCL.exe" (
    echo [server][ERROR] %JLINK_DIR%\JLinkGDBServerCL.exe not found
    echo [server]        only the full official pack ships the GDB Server; the trimmed CubeIDE plugin needs a separate install
    exit /b 1
)
echo [server] device=%JLINK_DEVICE% if=%JLINK_IF% speed=%JLINK_SPEED% port=%GDB_PORT%
echo [server] gdb connects via: target extended-remote :%GDB_PORT%   resident process, Ctrl+C stops
"%JLINK_DIR%\JLinkGDBServerCL.exe" -device %JLINK_DEVICE% -if %JLINK_IF% -speed %JLINK_SPEED% -port %GDB_PORT% -nogui -select USB
exit /b 0

REM ==================== rtt: RTT capture ====================
:S_RTT
call :NEED_JLINK || exit /b 1
if not exist "%JLINK_DIR%\JLinkRTTLogger.exe" (
    echo [rtt][ERROR] %JLINK_DIR%\JLinkRTTLogger.exe not found
    exit /b 1
)
set "OUT=%~1"
if "%OUT%"=="" set "OUT=rtt.log"
echo [rtt] logging to %OUT% ^(Ctrl+C stops^)
 REM  -RTTChannel 0: read up-channel 0; the logger scans RAM for the "SEGGER RTT" control block
"%JLINK_DIR%\JLinkRTTLogger.exe" -Device %JLINK_DEVICE% -If %JLINK_IF% -Speed %JLINK_SPEED% -RTTChannel 0 "%OUT%"
exit /b 0

REM ==================== read: one-shot variable read ====================
:S_READ
call :NEED_GDB || exit /b 1
set "ELF=%~1"
if "%ELF%"=="" (
    echo [read][ERROR] usage: dt read ^<project.elf^> ^<varname...^>
    exit /b 1
)
if not exist "%ELF%" (
    echo [read][ERROR] elf not found: %ELF%
    exit /b 1
)
if "%~2"=="" (
    echo [read][ERROR] at least one variable name required
    exit /b 1
)
set "CMDF=%TEMP%\dt_read.gdb"
>  "%CMDF%" echo set confirm off
>> "%CMDF%" echo set pagination off
>> "%CMDF%" echo target extended-remote :%GDB_PORT%
:RD_LOOP
if "%~2"=="" goto RD_DONE
 REM  p <var>: resolves the symbol via DWARF debug info and prints it (with type)
>> "%CMDF%" echo p %~2
shift
goto RD_LOOP
:RD_DONE
 REM  detach: disconnect and let the target run; -batch exits automatically here
>> "%CMDF%" echo detach
"%GDB%" "%ELF%" -batch -x "%CMDF%" > "%TEMP%\dt_read_out.log" 2>&1
type "%TEMP%\dt_read_out.log"
if errorlevel 1 (
    echo [read][ERROR] read failed: make sure the server runs in the background and the variable exists in this elf
    findstr /C:"Cannot access memory" "%TEMP%\dt_read_out.log" >nul && echo [read][HINT] probe likely degraded ^(cloned J-Link^), recover with: dt probe-reset
    exit /b 1
)
exit /b 0

REM ==================== watch: hardware watchpoints on variables ====================
:S_WATCH
call :NEED_GDB || exit /b 1
set "ELF=%~1"
if "%ELF%"=="" (
    echo [watch][ERROR] usage: dt watch ^<project.elf^> ^<varname...^>
    exit /b 1
)
if not exist "%ELF%" (
    echo [watch][ERROR] elf not found: %ELF%
    exit /b 1
)
if "%~2"=="" (
    echo [watch][ERROR] at least one variable name required
    exit /b 1
)
set "CMDF=%TEMP%\dt_watch.gdb"
>  "%CMDF%" echo set confirm off
>> "%CMDF%" echo set pagination off
>> "%CMDF%" echo target extended-remote :%GDB_PORT%
:WT_LOOP
if "%~2"=="" goto WT_DONE
 REM  watch: CPU hardware watchpoint, hits on any write path (including ISRs)
>> "%CMDF%" echo watch %~2
>> "%CMDF%" echo commands
>> "%CMDF%" echo   silent
 REM  printf prints the label only; the value is printed with output - using the
 REM  variable's own type, so int/float/enum all work
>> "%CMDF%" echo   printf ">>> [watch] %~2 = "
>> "%CMDF%" echo   output %~2
>> "%CMDF%" echo   printf "\n"
 REM  bt 3: 3 stack frames to locate which code path did the write
>> "%CMDF%" echo   bt 3
>> "%CMDF%" echo   continue
>> "%CMDF%" echo end
shift
goto WT_LOOP
:WT_DONE
 REM  enter the watch loop until manually stopped; run it as a background task and read its output
>> "%CMDF%" echo continue
"%GDB%" "%ELF%" -batch -x "%CMDF%"
exit /b 0

REM ==================== gdb: arbitrary gdb commands ====================
:S_GDB
call :NEED_GDB || exit /b 1
set "ELF=%~1"
if "%ELF%"=="" (
    echo [gdb][ERROR] usage: dt gdb ^<project.elf^> ^<gdb command...^>
    echo [gdb]        one gdb command per argument; connection is initialized and the target released at the end
    echo [gdb]        e.g.: dt gdb app.elf "info registers" "x/16xw 0x08000000"
    exit /b 1
)
if not exist "%ELF%" (
    echo [gdb][ERROR] elf not found: %ELF%
    exit /b 1
)
if "%~2"=="" (
    echo [gdb][ERROR] at least one gdb command required
    exit /b 1
)
set "CMDF=%TEMP%\dt_gdb.gdb"
>  "%CMDF%" echo set confirm off
>> "%CMDF%" echo set pagination off
>> "%CMDF%" echo target extended-remote :%GDB_PORT%
:GB_LOOP
if "%~2"=="" goto GB_DONE
 REM  user commands are written verbatim; avoid cmd redirect chars ^< ^> ^| inside gdb commands
>> "%CMDF%" echo %~2
shift
goto GB_LOOP
:GB_DONE
 REM  detach releases the target - same "use and return" semantics as read/watch
>> "%CMDF%" echo detach
"%GDB%" "%ELF%" -batch -x "%CMDF%" > "%TEMP%\dt_gdb_out.log" 2>&1
type "%TEMP%\dt_gdb_out.log"
if errorlevel 1 (
    echo [gdb][ERROR] execution failed: make sure the server runs in the background and the command/symbols are correct
    findstr /C:"Cannot access memory" "%TEMP%\dt_gdb_out.log" >nul && echo [gdb][HINT] probe likely degraded ^(cloned J-Link^), recover with: dt probe-reset
    exit /b 1
)
exit /b 0

REM ==================== ocd-server: OpenOCD GDB Server ====================
:S_OCDSERVER
if not defined OPENOCD_DIR (
    echo [ocd][ERROR] OpenOCD not found: install xpack-openocd / put it in bin\ / edit config\paths.bat
    exit /b 1
)
if not exist "%OPENOCD_DIR%\openocd.exe" (
    echo [ocd][ERROR] %OPENOCD_DIR%\openocd.exe not found
    exit /b 1
)
echo [ocd-server] interface=%OPENOCD_IF% target=stm32f4x.cfg gdb_port=%OPENOCD_PORT%
echo [ocd-server] gdb connects via: target extended-remote :%OPENOCD_PORT%   resident process, Ctrl+C stops
"%OPENOCD_DIR%\openocd.exe" -f "interface/%OPENOCD_IF%" -f "target/stm32f4x.cfg" -c "adapter speed 4000" -c "gdb_port %OPENOCD_PORT%"
exit /b 0

REM ==================== ocd-flash: OpenOCD flash ====================
:S_OCDFLASH
if not defined OPENOCD_DIR (
    echo [ocd][ERROR] OpenOCD not found: install xpack-openocd / put it in bin\ / edit config\paths.bat
    exit /b 1
)
if not exist "%OPENOCD_DIR%\openocd.exe" (
    echo [ocd][ERROR] %OPENOCD_DIR%\openocd.exe not found
    exit /b 1
)
set "IMG=%~1"
if "%IMG%"=="" (
    echo [ocd-flash][ERROR] usage: dt ocd-flash ^<fw^> [addr]
    exit /b 1
)
if not exist "%IMG%" (
    echo [ocd-flash][ERROR] file not found: %IMG%
    exit /b 1
)
 REM  BIN has no embedded address: pass it as the second argument, defaults to flash base
set "ADDR=%~2"
if "%ADDR%"=="" set "ADDR=0x08000000"
echo [ocd-flash] flashing %IMG% @%ADDR% ...
 REM  program does it all: write -> verify -> reset run -> exit
"%OPENOCD_DIR%\openocd.exe" -f "interface/%OPENOCD_IF%" -f "target/stm32f4x.cfg" -c "adapter speed 4000" -c "program \"%IMG%\" %ADDR% verify reset exit"
if errorlevel 1 (
    echo [ocd-flash][ERROR] flash failed: check debugger connection / OPENOCD_IF matches your debugger
    exit /b 1
)
echo [ocd-flash][OK] flashed and reset to run
exit /b 0

REM ==================== uart: serial capture ====================
:S_UART
 REM  %* is not affected by shift and still contains the subcommand itself;
 REM  drop the first token to get the remaining args
for /f "tokens=1,* delims= " %%a in ("%*") do set "UART_ARGS=%%b"
python "%~dp0uart_capture.py" %UART_ARGS%
exit /b %errorlevel%

REM ==================== halt: halt the running target ====================
:S_HALT
call :NEED_JLINK || exit /b 1
call :ASSERT_NO_GDBSERVER || exit /b 1
 REM  JLink.exe takes the probe exclusively, executes h and exits; the target
 REM  stays halted (confirmed by the LED stopping)
set "CMDF=%TEMP%\dt_halt.jlink"
>  "%CMDF%" echo connect
>> "%CMDF%" echo %JLINK_DEVICE%
>> "%CMDF%" echo %IF_LETTER%
>> "%CMDF%" echo %JLINK_SPEED%
>> "%CMDF%" echo h
>> "%CMDF%" echo qc
echo [halt] halting target ^(%JLINK_DEVICE%, %JLINK_SPEED%kHz^)...
"%JLINK_DIR%\JLink.exe" -if %JLINK_IF% -speed %JLINK_SPEED% -device %JLINK_DEVICE% -CommandFile "%CMDF%" -NoGui 1 > "%TEMP%\dt_halt.log" 2>&1
call :CHECK_JLINK_LOG "%TEMP%\dt_halt.log" halt || exit /b 1
echo [halt][OK] target halted; use dt run to resume, or start dt server and use gdb
exit /b 0

REM ==================== probe-reset: probe recovery (cloned J-Link V8) ====================
:S_PROBERESET
call :NEED_JLINK || exit /b 1
 REM  cloned V8 degrades after every session (slow / Cannot access memory);
 REM  exclusive low-speed reconnect + reset recovers it
call :STOP_GDBSERVER_QUIET
set "CMDF=%TEMP%\dt_probe_reset.jlink"
>  "%CMDF%" echo connect
>> "%CMDF%" echo %JLINK_DEVICE%
>> "%CMDF%" echo %IF_LETTER%
>> "%CMDF%" echo %PROBE_SPEED%
>> "%CMDF%" echo h
>> "%CMDF%" echo r
>> "%CMDF%" echo g
>> "%CMDF%" echo qc
echo [probe-reset] low-speed reconnect and reset ^(%PROBE_SPEED%kHz^)...
"%JLINK_DIR%\JLink.exe" -if %JLINK_IF% -speed %PROBE_SPEED% -device %JLINK_DEVICE% -CommandFile "%CMDF%" -NoGui 1 > "%TEMP%\dt_probe_reset.log" 2>&1
call :CHECK_JLINK_LOG "%TEMP%\dt_probe_reset.log" probe-reset || exit /b 1
echo [probe-reset][OK] probe recovered; if the server was stopped by this operation, restart dt server
exit /b 0

REM ==================== run: clear leftover BP/WP, reset and go ====================
:S_RUN
call :NEED_JLINK || exit /b 1
call :STOP_GDBSERVER_QUIET
set "CMDF=%TEMP%\dt_run.jlink"
>  "%CMDF%" echo connect
>> "%CMDF%" echo %JLINK_DEVICE%
>> "%CMDF%" echo %IF_LETTER%
>> "%CMDF%" echo %PROBE_SPEED%
>> "%CMDF%" echo h
>> "%CMDF%" echo r
 REM  FPB breakpoints and DWT watchpoints survive a system reset; leftovers
 REM  freeze the CPU the moment it runs into them. Clear FP_COMPn (0xE0002008+,
 REM  used by gdb breakpoints) AND DWT COMPn/FUNCTIONn (watchpoints) - verified
 REM  in the field: a stale FP_COMP kept freezing the app at the breakpoint addr
>> "%CMDF%" echo w4 0xE0002000 0x3
>> "%CMDF%" echo w4 0xE0002008 0x0
>> "%CMDF%" echo w4 0xE000200C 0x0
>> "%CMDF%" echo w4 0xE0002010 0x0
>> "%CMDF%" echo w4 0xE0002014 0x0
>> "%CMDF%" echo w4 0xE0002018 0x0
>> "%CMDF%" echo w4 0xE000201C 0x0
>> "%CMDF%" echo w4 0xE0001020 0x0
>> "%CMDF%" echo w4 0xE0001030 0x0
>> "%CMDF%" echo w4 0xE0001040 0x0
>> "%CMDF%" echo w4 0xE0001050 0x0
>> "%CMDF%" echo w4 0xE0001028 0x0
>> "%CMDF%" echo w4 0xE0001038 0x0
>> "%CMDF%" echo w4 0xE0001048 0x0
>> "%CMDF%" echo w4 0xE0001058 0x0
>> "%CMDF%" echo g
>> "%CMDF%" echo qc
echo [run] clearing leftover breakpoints/watchpoints, reset and go...
"%JLINK_DIR%\JLink.exe" -if %JLINK_IF% -speed %PROBE_SPEED% -device %JLINK_DEVICE% -CommandFile "%CMDF%" -NoGui 1 > "%TEMP%\dt_run.log" 2>&1
call :CHECK_JLINK_LOG "%TEMP%\dt_run.log" run || exit /b 1
echo [run][OK] target running freely (breakpoint/watchpoint leftovers cleared)
exit /b 0

REM ==================== server-stop: stop GDB Server ====================
:S_SERVERSTOP
call :STOP_GDBSERVER_QUIET
tasklist 2>nul | findstr /I "JLinkGDBServerCL.exe openocd.exe" >nul && (
    echo [server-stop][FAIL] debug server process still alive, check tasklist manually
    exit /b 1
)
echo [server-stop][OK] J-Link/OpenOCD GDB Server stopped, port released
exit /b 0

REM ==================== go: resume halted target (no reset) ====================
:S_GO
call :NEED_JLINK || exit /b 1
call :STOP_GDBSERVER_QUIET
set "CMDF=%TEMP%\dt_go.jlink"
>  "%CMDF%" echo connect
>> "%CMDF%" echo %JLINK_DEVICE%
>> "%CMDF%" echo %IF_LETTER%
>> "%CMDF%" echo %JLINK_SPEED%
>> "%CMDF%" echo g
>> "%CMDF%" echo qc
echo [go] resuming target (no reset, RAM state preserved)...
"%JLINK_DIR%\JLink.exe" -if %JLINK_IF% -speed %JLINK_SPEED% -device %JLINK_DEVICE% -CommandFile "%CMDF%" -NoGui 1 > "%TEMP%\dt_go.log" 2>&1
echo [go][OK] target resumed; note dt go does NOT clear leftover BP/WP, use dt run for that
exit /b 0

REM ==================== bp: one-shot breakpoint (native JLink) ====================
:S_BP
call :NEED_JLINK || exit /b 1
call :STOP_GDBSERVER_QUIET
set "ADDR=%~1"
if "%ADDR%"=="" (
    echo [bp][ERROR] usage: dt bp ^<hex address^> [wait ms, default 3000]
    echo [bp]        resolve the address first, e.g.: nm app.elf ^| findstr Task1000ms
    exit /b 1
)
set "WAIT=%~2"
if "%WAIT%"=="" set "WAIT=3000"
 REM  normalize: strip the 0x/0X prefix; regs prints PC without it
set "ADDR=%ADDR:0x=%"
set "ADDR=%ADDR:0X=%"
set "CMDF=%TEMP%\dt_bp.jlink"
 REM  NOTE: no raw w4 scrub here - writing FP_COMP behind the DLL's back breaks
 REM  its breakpoint state (verified: bp then never hits). Clear leftovers with
 REM  dt run BEFORE dt bp instead; each bp session is clean on its own.
>  "%CMDF%" echo connect
>> "%CMDF%" echo %JLINK_DEVICE%
>> "%CMDF%" echo %IF_LETTER%
>> "%CMDF%" echo %JLINK_SPEED%
>> "%CMDF%" echo h
>> "%CMDF%" echo r
>> "%CMDF%" echo setbp %ADDR%
>> "%CMDF%" echo g
>> "%CMDF%" echo Sleep %WAIT%
>> "%CMDF%" echo h
>> "%CMDF%" echo regs
>> "%CMDF%" echo qc
echo [bp] breakpoint at %ADDR%, waiting up to %WAIT% ms ...
"%JLINK_DIR%\JLink.exe" -if %JLINK_IF% -speed %JLINK_SPEED% -device %JLINK_DEVICE% -CommandFile "%CMDF%" -NoGui 1 > "%TEMP%\dt_bp.log" 2>&1
call :CHECK_JLINK_LOG "%TEMP%\dt_bp.log" bp || exit /b 1
findstr /I /C:"PC = %ADDR%" "%TEMP%\dt_bp.log" >nul && (
    echo [bp][OK] breakpoint HIT at %ADDR%, target left halted; dt step to walk, dt go to resume
) || (
    echo [bp][MISS] not hit within %WAIT% ms, target left halted where it was, log at %TEMP%\dt_bp.log; dt run to resume
)
exit /b 0

REM ==================== step: single-step one instruction ====================
:S_STEP
call :NEED_JLINK || exit /b 1
call :STOP_GDBSERVER_QUIET
set "CMDF=%TEMP%\dt_step.jlink"
>  "%CMDF%" echo connect
>> "%CMDF%" echo %JLINK_DEVICE%
>> "%CMDF%" echo %IF_LETTER%
>> "%CMDF%" echo %JLINK_SPEED%
>> "%CMDF%" echo h
>> "%CMDF%" echo s
>> "%CMDF%" echo regs
>> "%CMDF%" echo qc
echo [step] single-stepping one instruction ^(halts the target first if running^)...
"%JLINK_DIR%\JLink.exe" -if %JLINK_IF% -speed %JLINK_SPEED% -device %JLINK_DEVICE% -CommandFile "%CMDF%" -NoGui 1 > "%TEMP%\dt_step.log" 2>&1
call :CHECK_JLINK_LOG "%TEMP%\dt_step.log" step || exit /b 1
 REM  show where the step landed
findstr /C:"PC = " "%TEMP%\dt_step.log"
echo [step][OK] stepped one instruction, target left halted; repeat dt step or dt go to resume
exit /b 0

REM ==================== help ====================
:USAGE
echo Usage: dt ^<subcommand^> [args...]
echo   check                       J-Link link self-test
echo   flash [--hold] ^<fw.hex^|.bin^>  flash; --hold keeps target halted after reset
echo   server                      start J-Link GDB Server ^(resident, port %GDB_PORT%^)
echo   rtt [outfile]               capture RTT output ^(resident, default rtt.log^)
echo   read ^<elf^> ^<var...^>         one-shot variable read
echo   watch ^<elf^> ^<var...^>        hardware watchpoints on variables ^(resident, with backtrace^)
echo   gdb ^<elf^> ^<cmd...^>          arbitrary gdb commands ^(auto init/detach^)
echo   ocd-server                  start OpenOCD GDB Server ^(resident, port %OPENOCD_PORT%^)
echo   ocd-flash ^<fw^> [addr]       OpenOCD flash ^(bin needs an address^)
echo   uart [args...]              serial capture ^(e.g.: dt uart --list^)
echo   halt                        halt the running target ^(dt run to resume^)
echo   probe-reset                 probe recovery ^(mandatory for cloned J-Link V8^)
echo   run                         clear leftover breakpoints/watchpoints, reset and go
echo   server-stop                 stop J-Link/OpenOCD GDB Server and free the port
echo   go                          resume a halted target without reset ^(RAM kept^)
echo   bp ^<hexaddr^> [ms]           restart target, run until breakpoint ^(unreliable on clone probes^)
echo   step                        single-step one instruction ^(disconnect auto-resumes after^)
echo.
echo Examples: dt flash build\app.hex
echo           dt watch build\app.elf g_counter g_fsm_state
echo           dt read  build\app.elf g_counter
echo           dt gdb   build\app.elf "info registers" "x/16xw 0x08000000"
echo Config file: %~dp0config\paths.bat
exit /b 1

REM ==================== subroutines: dependency checks ====================
:NEED_JLINK
if not defined JLINK_DIR (
    echo [dt][ERROR] J-Link software pack not found: install official SEGGER pack / put portable version in bin\ / edit config\paths.bat
    exit /b 1
)
if not exist "%JLINK_DIR%\JLink.exe" (
    echo [dt][ERROR] %JLINK_DIR%\JLink.exe not found
    exit /b 1
)
exit /b 0

:NEED_GDB
if not defined TOOLCHAIN_DIR (
    echo [dt][ERROR] arm-none-eabi-gdb not found: install ARM toolchain / put portable version in bin\ / edit config\paths.bat
    exit /b 1
)
if not exist "%TOOLCHAIN_DIR%\arm-none-eabi-gdb.exe" (
    echo [dt][ERROR] %TOOLCHAIN_DIR%\arm-none-eabi-gdb.exe not found
    exit /b 1
)
 REM  read/watch/gdb talk to the GDB Server; fail fast with a precise hint if it is down
tasklist 2>nul | findstr /I "JLinkGDBServerCL.exe" >nul || (
    echo [dt][ERROR] J-Link GDB Server is not running, start it first: dt server
    exit /b 1
)
set "GDB=%TOOLCHAIN_DIR%\arm-none-eabi-gdb.exe"
exit /b 0

REM ==================== subroutines: probe/server helpers ====================
:ASSERT_NO_GDBSERVER
tasklist 2>nul | findstr /I "JLinkGDBServerCL.exe" >nul && (
    echo [dt][ERROR] GDB Server is holding the probe, run first: dt server-stop
    exit /b 1
)
exit /b 0

:STOP_GDBSERVER_QUIET
taskkill /IM JLinkGDBServerCL.exe /F >nul 2>&1
taskkill /IM openocd.exe /F >nul 2>&1
 REM  wait 1s so the probe handle is released
ping -n 2 127.0.0.1 >nul
exit /b 0

:CHECK_JLINK_LOG
 REM  %1=logfile %2=subcommand name; JLink.exe interactive exit codes are
 REM  unreliable, success is judged by the O.K/identified markers in the output
findstr /C:"O.K" "%~1" >nul && exit /b 0
findstr /C:"identified" "%~1" >nul && exit /b 0
echo [%~2][FAIL] no connection-success marker (O.K/identified) found, full log:
type "%~1"
exit /b 1
