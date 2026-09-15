"""Offline portable-bundle verification. Does not connect to a debug probe."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import dt

ROOT = Path(__file__).resolve().parent


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--full', action='store_true', help='also verify every bundled file SHA-256')
    ap.add_argument('--json', type=Path, help='save results to this file')
    args = ap.parse_args(argv)
    results = []

    def record(name, ok, detail):
        results.append({'name': name, 'ok': bool(ok), 'detail': detail})
        print(f"[{'OK' if ok else 'FAIL'}] {name}: {detail}", flush=True)

    def inside(path):
        return Path(path).resolve().is_relative_to(ROOT)

    record('Python', inside(sys.executable), f'{sys.version.split()[0]} {sys.executable}')
    try:
        import serial
        record('pyserial', inside(serial.__file__), f'{serial.__version__} {serial.__file__}')
    except ImportError as exc:
        record('pyserial', False, str(exc))

    # Only Windows system paths are allowed for executable/DLL lookup in checks.
    system = Path(os.environ['SystemRoot'])
    os.environ['PATH'] = os.pathsep.join(map(str, [system / 'System32', system]))
    dt.load_config()
    configured = {
        'JLINK_DIR': 'JLink.exe', 'GDB_DIR': 'arm-none-eabi-gdb.exe',
        'OPENOCD_DIR': 'openocd.exe', 'OPENOCD_SCRIPTS': 'target/stm32f4x.cfg',
    }
    for key, filename in configured.items():
        directory = os.environ.get(key, '')
        path = Path(directory) / filename
        record(key, bool(directory) and inside(path) and path.is_file(), str(path.resolve()))

    for relative in ('bin/gdb/arm-none-eabi/share/gdb/auto-load', 'bin/gdb/lib/debug',
                     'bin/gdb/lib/gdb', 'config/openocd-portable.tcl'):
        path = dt.bundled_path(relative)
        record('Bundled resource', inside(path), str(path))

    kit = dt.Toolkit()

    commands = {
        'J-Link GDB Server': [ROOT / 'bin/jlink/JLinkGDBServerCL.exe', '-version'],
        'GDB': dt.gdb_argv() + ['--version'],
        'OpenOCD': [ROOT / 'xpack-openocd/bin/openocd.exe', '--version'],
        'OpenOCD scripts': kit.openocd_args() + ['-c', 'echo PORTABLE_CONFIG_OK; shutdown'],
    }
    for name, command in commands.items():
        try:
            result = subprocess.run(command, cwd=ROOT, stdout=subprocess.PIPE,
                                    stderr=subprocess.STDOUT, timeout=15,
                                    creationflags=subprocess.CREATE_NO_WINDOW)
            output = result.stdout.decode('utf-8', 'replace').strip()
            ok = result.returncode == 0
            if name == 'OpenOCD scripts':
                ok = ok and 'PORTABLE_CONFIG_OK' in output
            detail = output if not ok else next(iter(output.splitlines()), '')
            record(name, ok, f'exit={result.returncode}; {detail}')
        except (OSError, subprocess.TimeoutExpired) as exc:
            record(name, False, str(exc))

    queries = ['show data-directory', 'show debug-file-directory',
               'show auto-load scripts-directory', 'show auto-load safe-path']
    for name, base in [('GDB default resources', [ROOT / 'bin/gdb/bin/arm-none-eabi-gdb.exe', '-nx']),
                       ('GDB launch resources', dt.gdb_argv())]:
        command = base + ['-batch']
        for query in queries:
            command += ['-ex', query]
        result = subprocess.run(command, cwd=ROOT, capture_output=True, text=True,
                                timeout=15, creationflags=subprocess.CREATE_NO_WINDOW)
        lines = result.stdout.strip().splitlines()
        prefix = ROOT.as_posix().lower()
        # Raw GDB uses $debugdir/$datadir aliases, both checked above.
        ok = result.returncode == 0 and len(lines) == 4 and all(
            prefix in line.replace('\\', '/').lower() or '$debugdir:$datadir/auto-load' in line
            for line in lines)
        record(name, ok, result.stdout.strip() + result.stderr.strip())

    try:
        manifest = json.loads((ROOT / 'dependencies.lock.json').read_text(encoding='utf-8'))
        missing, changed = [], []
        for relative, expected in manifest['files'].items():
            path = ROOT / relative
            if not inside(path):
                raise ValueError(f'manifest path outside tools: {relative}')
            if not path.is_file():
                missing.append(relative)
            elif path.stat().st_size != expected['bytes']:
                changed.append(relative)
            elif args.full:
                with path.open('rb') as file:
                    if hashlib.file_digest(file, 'sha256').hexdigest() != expected['sha256']:
                        changed.append(relative)
        count = len(manifest['files'])
        record('Bundle files', not missing and not changed,
               f'{count} checked; SHA-256={args.full}; missing={missing[:10]}; changed={changed[:10]}')
    except (OSError, ValueError, KeyError) as exc:
        record('Bundle files', False, str(exc))

    ok = all(item['ok'] for item in results)
    if args.json:
        args.json.parent.mkdir(parents=True, exist_ok=True)
        args.json.write_text(json.dumps({'root': str(ROOT), 'ok': ok, 'checks': results},
                                       ensure_ascii=False, indent=2), encoding='utf-8')
    print('[verify] PASS (software only; USB drivers/target not tested)' if ok else '[verify] FAIL')
    return 0 if ok else 1


if __name__ == '__main__':
    sys.stdout.reconfigure(errors='replace')
    try:
        sys.exit(main())
    except (OSError, ValueError, KeyError, dt.DebugError) as exc:
        print(f'[verify][ERROR] {exc}', file=sys.stderr)
        sys.exit(1)
