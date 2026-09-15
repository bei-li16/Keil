#!/usr/bin/env python3
"""STM32 debug command runner. The Windows entry point is dt.bat.

Only the standard library is required (pyserial is optional for uart).
Commands are passed to executables as argument arrays, never through a shell.
"""
import argparse
from collections import deque
from contextlib import contextmanager
import ctypes
from ctypes import wintypes
from dataclasses import dataclass
import json
import math
import os
from pathlib import Path
import re
import socket
import subprocess
import sys
import tempfile
import threading
import time
import uuid

ROOT = Path(__file__).resolve().parent
HIDDEN = getattr(subprocess, "CREATE_NO_WINDOW", 0)
TOOL_DIRS = {
    "JLINK_DIR": "bin/jlink", "GDB_DIR": "bin/gdb/bin",
    "OPENOCD_DIR": "xpack-openocd/bin",
    "OPENOCD_SCRIPTS": "xpack-openocd/openocd/scripts",
}


def bundled_path(relative):
    """Resolve dependencies inside this copy, including directory junctions."""
    path = (ROOT / relative).resolve()
    if not path.is_relative_to(ROOT.resolve()):
        raise DebugError(f"dependency outside tools: {relative}")
    if not path.exists():
        raise DebugError(f"missing bundled dependency: {path}; copy the complete tools directory")
    return path


def gdb_argv():
    """Set resource paths before reading an ELF or loading any user scripts."""
    executable = bundled_path("bin/gdb/bin/arm-none-eabi-gdb.exe")
    data = bundled_path("bin/gdb/arm-none-eabi/share/gdb")
    symbols = bundled_path("bin/gdb/lib/debug")
    autoload = bundled_path("bin/gdb/arm-none-eabi/share/gdb/auto-load")
    # GDB 'set ... directory' treats the rest of the line as an unquoted path.
    return [str(executable), "-nx", "--data-directory=" + str(data),
            "-iex", "set debug-file-directory " + symbols.as_posix(),
            "-iex", "set auto-load scripts-directory " + autoload.as_posix(),
            "-iex", "set auto-load safe-path " + autoload.as_posix()]


def load_config():
    """Load the shared batch config also for direct Python/PowerShell entry."""
    command = f'call "{ROOT / "config" / "paths.bat"}" >nul && set'
    # CMD has its own quoting rules, not the C-runtime quoting used for exe argv.
    cmd = Path(os.environ["SystemRoot"]) / "System32/cmd.exe"
    invocation = f'"{cmd}" /d /u /s /c "{command}"'
    result = subprocess.run(invocation,
                            capture_output=True, creationflags=HIDDEN)
    if result.returncode:
        raise DebugError("cannot load config/paths.bat")
    for line in result.stdout.decode("utf-16-le").splitlines():
        key, separator, value = line.partition("=")
        if separator and key:
            os.environ[key] = value


class DebugError(Exception):
    pass


def positive(value):
    number = float(value)
    if not math.isfinite(number) or number <= 0:
        raise argparse.ArgumentTypeError("must be finite and greater than zero")
    return number


def address(value):
    try:
        number = int(value, 0)
    except ValueError:
        raise argparse.ArgumentTypeError("use an integer address, e.g. 0x08000000")
    if not 0 <= number <= 0xFFFFFFFF:
        raise argparse.ArgumentTypeError("address must fit in 32 bits")
    return number


def image_args(filename, addr, backend):
    """BIN has an absolute address; HEX/ELF already carry their addresses."""
    path = Path(filename).resolve()
    if not path.is_file():
        raise DebugError(f"firmware not found: {path}")
    if path.suffix.lower() not in (".bin", ".hex", ".elf", ".srec", ".s19", ".mot"):
        raise DebugError("unsupported image format")
    if path.suffix.lower() == ".bin":
        if addr is None:
            raise DebugError("BIN requires an explicit address, e.g. 0x08000000")
        suffix = f" 0x{addr:08X}"
    else:
        if addr is not None:
            raise DebugError("HEX/ELF/SREC already contain addresses; omit the address")
        suffix = ""
    if backend == "openocd":
        # Tcl braces plus forward slashes preserve spaces and Windows paths.
        if any(c in str(path) for c in "{}\r\n"):
            raise DebugError("OpenOCD image path cannot contain braces or newlines")
        return f"program {{{path.as_posix()}}}{suffix} verify reset exit"
    if any(c in str(path) for c in '\"\r\n'):
        raise DebugError("invalid image filename")
    return f'loadfile "{path}"{suffix}'


def jlink_commands(action, *, load=None, hold=False, addr=None, wait=3000):
    commands = ["connect"]
    if action == "flash":
        commands += ["h", load, "r", "h"]
        if not hold:
            commands += ["g"]
    elif action in ("run", "probe-reset"):
        commands += ["h", "r"]
        if action == "run":
            commands += ["w4 0xE0002000 0x3"]
            registers = list(range(0xE0002008, 0xE0002020, 4))
            registers += list(range(0xE0001020, 0xE0001060, 16))
            registers += list(range(0xE0001028, 0xE0001068, 16))
            commands += [f"w4 0x{reg:08X} 0x0" for reg in registers]
        commands += ["g"]
    elif action == "check":
        commands += ["h", "regs", "g"]
    elif action == "halt":
        commands += ["h", "regs"]
    elif action == "go":
        commands += ["g"]
    elif action == "step":
        commands += ["h", "s", "regs"]
    elif action == "bp":
        commands += ["h", "r", f"setbp 0x{addr:08X}", "g", f"Sleep {wait}", "h", "regs"]
    else:
        raise DebugError(f"unknown Commander action: {action}")
    if hold or action in ("halt", "step", "bp"):
        # Retain core/debug state across Commander processes.
        commands += ["exec SetRestartOnClose = 0", "exec SetSkipDebugDeInit = 1"]
    commands += ["qc"]
    return commands


JLINK_ERROR = re.compile(
    r"(?im)(?:^\s*(?:\*+\s*)?error\b|unknown command|cannot (?:access|connect)|"
    r"failed to |could not |cannot read|no emulator|no j-link|unable to |"
    r"verification failed|programming failed)"
)


def check_jlink(result):
    if result.code or JLINK_ERROR.search(result.text):
        raise DebugError(f"J-Link failed (exit {result.code}); see {result.log}")
    if "Script processing completed." not in result.text or "identified." not in result.text:
        raise DebugError(f"J-Link did not complete the target session; see {result.log}")


def gdb_commands(action, expressions, port, marker):
    commands = ["set confirm off", "set pagination off", "set remotetimeout 5",
                "set tcp auto-retry on", "set tcp connect-timeout 5",
                f"target extended-remote localhost:{port}", "monitor halt",
                "maintenance flush register-cache", "echo [gdb] target synchronized and halted\\n"]
    for expr in expressions:
        if "\n" in expr or "\r" in expr:
            raise DebugError("each argument must contain one GDB command/expression")
        if action == "read":
            commands += [f"p {expr}"]
        elif action == "gdb":
            commands += [expr]
        else:
            label = json.dumps(f">>> [watch] {expr} = ", ensure_ascii=True)
            commands += [f"watch {expr}", "commands", "silent", f"printf {label}",
                         f"output {expr}", 'printf "\\n"', "bt 3", "continue", "end"]
    if action == "watch":
        commands += ["continue"]
    commands += [f"echo {marker}\\n"]
    return commands


@dataclass
class Result:
    code: int
    text: str
    log: Path
    timed_out: bool = False


def run_program(argv, log, timeout=None, *, env=None):
    """Stream complete output to disk; keep a bounded tail for validation."""
    tail = deque(maxlen=10000)
    with log.open("w", encoding="utf-8", newline="\n") as out:
        process = subprocess.Popen([str(a) for a in argv], stdin=subprocess.DEVNULL,
                                   stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                   creationflags=HIDDEN, env=env)

        def drain():
            for raw in iter(process.stdout.readline, b""):
                line = raw.decode("utf-8", "replace").replace("\r\n", "\n")
                out.write(line)
                out.flush()
                tail.append(line)
                print(line, end="", flush=True)

        reader = threading.Thread(target=drain, daemon=True)
        reader.start()
        timed_out = False
        try:
            code = process.wait(timeout=timeout)
        except subprocess.TimeoutExpired:
            timed_out = True
            process.terminate()
            process.wait(timeout=5)
            code = 124
        except KeyboardInterrupt:
            process.terminate()
            process.wait(timeout=5)
            code = 130
        finally:
            reader.join(timeout=5)
            process.stdout.close()
    return Result(code, "".join(tail), log, timed_out)


def _kernel32():
    kernel = ctypes.WinDLL("kernel32", use_last_error=True)
    kernel.OpenProcess.argtypes = [wintypes.DWORD, wintypes.BOOL, wintypes.DWORD]
    kernel.OpenProcess.restype = wintypes.HANDLE
    kernel.CloseHandle.argtypes = [wintypes.HANDLE]
    kernel.GetProcessTimes.argtypes = [wintypes.HANDLE] + [ctypes.POINTER(wintypes.FILETIME)] * 4
    kernel.QueryFullProcessImageNameW.argtypes = [wintypes.HANDLE, wintypes.DWORD,
                                               wintypes.LPWSTR, ctypes.POINTER(wintypes.DWORD)]
    kernel.TerminateProcess.argtypes = [wintypes.HANDLE, wintypes.UINT]
    kernel.WaitForSingleObject.argtypes = [wintypes.HANDLE, wintypes.DWORD]
    kernel.GetExitCodeProcess.argtypes = [wintypes.HANDLE, ctypes.POINTER(wintypes.DWORD)]
    return kernel


def _identity(kernel, handle, pid):
    code = wintypes.DWORD()
    if not kernel.GetExitCodeProcess(handle, ctypes.byref(code)) or code.value != 259:
        return None
    times = [wintypes.FILETIME() for _ in range(4)]
    name = ctypes.create_unicode_buffer(32768)
    length = wintypes.DWORD(len(name))
    if not kernel.GetProcessTimes(handle, *(ctypes.byref(x) for x in times)):
        raise DebugError("cannot verify server creation time")
    if not kernel.QueryFullProcessImageNameW(handle, 0, name, ctypes.byref(length)):
        raise DebugError("cannot verify server executable")
    created = (times[0].dwHighDateTime << 32) | times[0].dwLowDateTime
    return {"pid": pid, "image": name.value.lower(), "created": created}


def process_identity(pid):
    kernel = _kernel32()
    handle = kernel.OpenProcess(0x1000, False, pid)
    if not handle:
        if ctypes.get_last_error() == 87:  # PID no longer exists
            return None
        raise DebugError(f"cannot inspect server PID {pid}")
    try:
        return _identity(kernel, handle, pid)
    finally:
        kernel.CloseHandle(handle)


def stop_process(record):
    """Verify PID, creation time AND image on the same handle before stopping."""
    kernel = _kernel32()
    handle = kernel.OpenProcess(0x1000 | 0x100000 | 1, False, record["pid"])
    if not handle:
        if ctypes.get_last_error() == 87:
            return
        raise DebugError(f"cannot stop owned server PID {record['pid']}")
    try:
        identity = _identity(kernel, handle, record["pid"])
        expected = {key: record[key] for key in ("pid", "image", "created")}
        if identity != expected:
            # A stale PID must never kill an unrelated process.
            return
        if not kernel.TerminateProcess(handle, 0):
            raise DebugError(f"failed to stop server PID {record['pid']}")
        if kernel.WaitForSingleObject(handle, 5000) != 0:
            raise DebugError("server did not stop within five seconds")
    finally:
        kernel.CloseHandle(handle)


@contextmanager
def operation_lock(state):
    import msvcrt
    state.mkdir(parents=True, exist_ok=True)
    with (state / "operation.lock").open("a+b") as lock:
        lock.seek(0, os.SEEK_END)
        if lock.tell() == 0:
            lock.write(b"0")
            lock.flush()
        lock.seek(0)
        try:
            msvcrt.locking(lock.fileno(), msvcrt.LK_NBLCK, 1)
        except OSError:
            raise DebugError("another dt command is using this debug session; finish it first")
        try:
            yield
        finally:
            lock.seek(0)
            msvcrt.locking(lock.fileno(), msvcrt.LK_UNLCK, 1)


class Toolkit:
    def __init__(self, env=None):
        self.env = dict(os.environ if env is None else env)
        system = Path(os.environ["SystemRoot"])
        self.env["PATH"] = os.pathsep.join(str(ROOT / relative) for relative in TOOL_DIRS.values())
        self.env["PATH"] += os.pathsep + str(system / "System32") + os.pathsep + str(system)
        self.state = Path(self.env.get("DT_STATE_DIR", ROOT / "runtime/state"))
        log_base = self.env.get("DT_LOG_DIR") or ROOT / "runtime/logs"
        Path(log_base).mkdir(parents=True, exist_ok=True)
        self.logs = Path(tempfile.mkdtemp(prefix="dt-", dir=log_base))
        print(f"[dt] logs: {self.logs}")

    def value(self, name, fallback):
        return self.env.get(name) or fallback

    def exe(self, directory, filename):
        path = bundled_path(Path(TOOL_DIRS[directory]) / filename)
        if not path.is_file():
            raise DebugError(f"missing bundled executable: {path}")
        return str(path)

    def script(self, filename, lines):
        path = self.logs / filename
        path.write_text("\n".join(lines) + "\n", encoding="utf-8")
        return path

    def stop_servers(self):
        stopped = False
        for path in self.state.glob("server-*.json"):
            record = json.loads(path.read_text(encoding="utf-8"))
            stop_process(record)
            path.unlink()
            stopped = True
        if stopped:
            time.sleep(0.2)

    def commander(self, args):
        executable = self.exe("JLINK_DIR", "JLink.exe")
        load = image_args(args.image, args.address, "jlink") if args.action == "flash" else None
        lines = jlink_commands(args.action, load=load, hold=getattr(args, "hold", False),
                               addr=getattr(args, "address", None), wait=getattr(args, "wait", 3000))
        speed = self.value("PROBE_SPEED", "1000") if args.action in ("run", "probe-reset") else self.value("JLINK_SPEED", "4000")
        script = self.script(f"{args.action}.jlink", lines)
        with operation_lock(self.state):
            self.stop_servers()
            result = run_program([executable, "-device", self.value("JLINK_DEVICE", "STM32F429IG"),
                                  "-if", self.value("JLINK_IF", "SWD"), "-speed", speed,
                                  "-ExitOnError", "1", "-NoGui", "1", "-CommandFile", script],
                                 self.logs / "commander.log", args.timeout, env=self.env)
        check_jlink(result)
        if args.action == "bp":
            pcs = re.findall(r"PC = ([0-9a-fA-F]+)", result.text)
            if not pcs or int(pcs[-1], 16) != args.address:
                raise DebugError("breakpoint not hit; target left halted, use dt go or dt run")
        print(f"[{args.action}][OK] completed")
        return 0

    def openocd_args(self):
        scripts = bundled_path(TOOL_DIRS["OPENOCD_SCRIPTS"])
        configs = []
        for name in ("interface/" + self.value("OPENOCD_IF", "jlink.cfg"),
                     self.value("OPENOCD_TARGET", "target/stm32f4x.cfg")):
            config = bundled_path(scripts / name)
            if not config.is_relative_to(scripts) or not config.is_file():
                raise DebugError(f"OpenOCD config must be a file inside {scripts}: {name}")
            configs.append(config.as_posix())
        return [self.exe("OPENOCD_DIR", "openocd.exe"), "-s", scripts.as_posix(),
                "-f", bundled_path("config/openocd-portable.tcl").as_posix(),
                "-f", configs[0],
                "-c", "transport select " + self.value("OPENOCD_TRANSPORT", "swd"),
                "-f", configs[1],
                "-c", "adapter speed " + self.value("OPENOCD_SPEED", "4000"),
                "-c", "bindto 127.0.0.1"]

    def server_argv(self, backend, port):
        if backend == "openocd":
            return self.openocd_args() + ["-c", f"gdb port {port}", "-c", "init; halt"]
        return [self.exe("JLINK_DIR", "JLinkGDBServerCL.exe"), "-device", self.value("JLINK_DEVICE", "STM32F429IG"),
                "-if", self.value("JLINK_IF", "SWD"), "-speed", self.value("JLINK_SPEED", "4000"),
                "-port", str(port), "-nogui", "-select", "USB", "-localhostonly", "-halt"]

    @contextmanager
    def session_server(self, backend, port):
        """A fresh server per client avoids stale V8 probe sessions, without reset."""
        argv = self.server_argv(backend, port)
        self.stop_servers()
        with socket.socket() as guard:
            guard.setsockopt(socket.SOL_SOCKET, socket.SO_EXCLUSIVEADDRUSE, 1)
            try:
                guard.bind(('127.0.0.1', int(port)))
            except OSError as exc:
                raise DebugError(f'port {port} is occupied by an unmanaged server; use --reuse-server to connect explicitly') from exc
        record_path = self.state / f'server-{backend}.json'
        with (self.logs / 'server.log').open('wb') as log:
            process = subprocess.Popen(argv, stdout=log, stderr=subprocess.STDOUT, creationflags=HIDDEN, env=self.env)
            identity = None
            try:
                identity = process_identity(process.pid)
                if identity is None:
                    raise DebugError(f'server exited during startup; see {self.logs / "server.log"}')
                identity.update(backend=backend, port=int(port))
                record_path.write_text(json.dumps(identity), encoding='utf-8')
                yield
            finally:
                if identity:
                    stop_process(identity)
                elif process.poll() is None:
                    process.terminate()
                process.wait(timeout=5)
                if record_path.exists() and json.loads(record_path.read_text()) == identity:
                    record_path.unlink()

    def server(self, args):
        backend = "openocd" if args.action == "ocd-server" else "jlink"
        port = self.value("OPENOCD_PORT" if backend == "openocd" else "GDB_PORT", "3334" if backend == "openocd" else "3333")
        if not 1 <= int(port) <= 65535:
            raise DebugError('invalid TCP port')
        argv = self.server_argv(backend, port)
        record_path = self.state / f"server-{backend}.json"
        with operation_lock(self.state):
            for path in self.state.glob("server-*.json"):
                old = json.loads(path.read_text(encoding="utf-8"))
                current = process_identity(old["pid"])
                if current and all(current[k] == old[k] for k in current):
                    raise DebugError("a managed server is already running; use dt server-stop first")
                path.unlink()
            print(f"[server] {backend}, localhost:{port}; starting server halts the target", flush=True)
            process = subprocess.Popen(argv, creationflags=HIDDEN, env=self.env)
            identity = process_identity(process.pid)
            if identity is None:
                return process.wait() or 1
            identity.update(backend=backend, port=int(port))
            try:
                record_path.write_text(json.dumps(identity), encoding="utf-8")
            except OSError:
                stop_process(identity)
                process.wait(timeout=5)
                raise
        try:
            return process.wait()
        except KeyboardInterrupt:
            stop_process(identity)
            return 130
        finally:
            # server-stop may have already removed the record or started another process.
            try:
                with operation_lock(self.state):
                    if record_path.exists() and json.loads(record_path.read_text()) == identity:
                        record_path.unlink()
            except DebugError:
                pass  # harmless stale record is checked by creation time next time

    def gdb(self, args):
        elf = Path(args.elf).resolve()
        if not elf.is_file():
            raise DebugError(f"ELF not found: {elf}")
        backend = args.backend or self.value("DEBUG_BACKEND", "jlink")
        if backend not in ('jlink', 'openocd'):
            raise DebugError('DEBUG_BACKEND must be jlink or openocd')
        port = args.port or self.value("OPENOCD_PORT" if backend == "openocd" else "GDB_PORT", "3334" if backend == "openocd" else "3333")
        if not 1 <= int(port) <= 65535:
            raise DebugError('invalid TCP port')
        marker = "DT_COMMANDS_COMPLETED_" + uuid.uuid4().hex
        commands = gdb_commands(args.action, args.expressions, port, marker)
        script = self.script("commands.gdb", commands)
        resume = "monitor resume" if backend == "openocd" else "monitor go"
        # GDB without Python supports cleanup via later -ex arguments even when
        # -x aborts. Later successes can reset GDB's exit code, so require marker.
        cleanup_marker = "DT_CLEANUP_COMPLETED_" + uuid.uuid4().hex
        cleanup = self.script("cleanup.gdb", ["delete breakpoints", resume, "detach",
                                               f"echo {cleanup_marker}\\n"])
        argv = [*gdb_argv(), str(elf), "-batch", "-x", str(script),
                "-x", str(cleanup)]
        timeout = args.duration if args.action == "watch" else args.timeout
        with operation_lock(self.state):
            if args.reuse_server:
                result = run_program(argv, self.logs / "gdb.log", timeout, env=self.env)
            else:
                with self.session_server(backend, port):
                    result = run_program(argv, self.logs / "gdb.log", timeout, env=self.env)
        if result.timed_out or result.code == 130:
            print("[gdb] session stopped; use dt run to clear remaining hardware watchpoints")
            return result.code
        if result.code or marker not in result.text or cleanup_marker not in result.text or re.search(r"MIS-MATCHED|Error in sourced|Cannot access memory|Remote communication error|\[dt-error\]", result.text, re.I):
            raise DebugError(f"GDB command/cleanup failed; see {result.log}. For a broken link use dt probe-reset")
        print(f"[{args.action}][OK] commands completed; target resumed")
        return 0


def parser():
    ap = argparse.ArgumentParser(description="STM32 console debugger (Windows / Python 3.9+)")
    sub = ap.add_subparsers(dest="action", required=True)
    sub.add_parser("uart", help="capture/count UART lines; use uart --help")
    for name in ("check", "run", "probe-reset", "halt", "go", "step", "bp", "flash"):
        item = sub.add_parser(name)
        item.add_argument("--timeout", type=positive, default=30)
        if name == "flash":
            item.add_argument("--hold", action="store_true")
            item.add_argument("image")
            item.add_argument("address", nargs="?", type=address)
        elif name == "bp":
            item.add_argument("address", type=address)
            item.add_argument("wait", nargs="?", type=int, default=3000)
    for name in ("server", "server-stop", "ocd-server"):
        sub.add_parser(name)
    item = sub.add_parser("ocd-flash")
    item.add_argument("image")
    item.add_argument("address", nargs="?", type=address)
    item.add_argument("--timeout", type=positive, default=60)
    item = sub.add_parser("rtt")
    item.add_argument("output", nargs="?", default="rtt.log")
    item.add_argument("--timeout", type=positive)
    for name in ("read", "gdb", "watch"):
        item = sub.add_parser(name)
        item.add_argument("--backend", choices=("jlink", "openocd"))
        item.add_argument("--reuse-server", action="store_true", help="connect to an existing server instead of a fresh session")
        item.add_argument("--port", type=int)
        item.add_argument("--timeout", type=positive, default=30)
        item.add_argument("--duration", type=positive)
        item.add_argument("elf")
        item.add_argument("expressions", nargs="+")
    return ap


def main(argv=None):
    argv = list(sys.argv[1:] if argv is None else argv)
    # Forward UART args directly, with no shell token reconstruction or shift.
    if argv and argv[0].lower() == "uart":
        from uart_capture import main as uart_main
        return uart_main(argv[1:])
    if argv:
        argv[0] = argv[0].lower()
    args = parser().parse_args(argv)
    if args.action == "bp" and args.wait < 0:
        raise DebugError("breakpoint wait must not be negative")
    if getattr(args, "port", None) is not None and not 1 <= args.port <= 65535:
        raise DebugError("invalid TCP port")
    kit = Toolkit()
    if args.action in ("server", "ocd-server"):
        return kit.server(args)
    if args.action == "server-stop":
        with operation_lock(kit.state):
            kit.stop_servers()
        print("[server-stop][OK] servers started by this tools checkout stopped")
        return 0
    if args.action in ("read", "gdb", "watch"):
        return kit.gdb(args)
    if args.action == "ocd-flash":
        command = image_args(args.image, args.address, "openocd")
        with operation_lock(kit.state):
            kit.stop_servers()
            result = run_program(kit.openocd_args() + ["-c", command], kit.logs / "openocd.log", args.timeout, env=kit.env)
        if result.code or re.search(r"(?im)^Error\s*:", result.text):
            raise DebugError(f"OpenOCD flash failed; see {result.log}")
        print("[ocd-flash][OK] programmed and verified")
        return 0
    if args.action == "rtt":
        with operation_lock(kit.state):
            kit.stop_servers()
            result = run_program([kit.exe("JLINK_DIR", "JLinkRTTLogger.exe"), "-Device", kit.value("JLINK_DEVICE", "STM32F429IG"),
                                  "-If", kit.value("JLINK_IF", "SWD"), "-Speed", kit.value("JLINK_SPEED", "4000"),
                                  "-RTTChannel", "0", args.output], kit.logs / "rtt.log", args.timeout, env=kit.env)
        return result.code or (1 if re.search(r"(?im)\berror\b|could not|failed to", result.text) else 0)
    return kit.commander(args)


if __name__ == "__main__":
    sys.stdout.reconfigure(errors="replace")
    try:
        load_config()
        sys.exit(main())
    except (DebugError, OSError, ValueError) as exc:
        print(f"[dt][ERROR] {exc}", file=sys.stderr)
        sys.exit(1)
