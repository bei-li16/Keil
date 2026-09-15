#!/usr/bin/env python3
"""UART capture with complete-line timestamps and independent regex counts."""
import argparse
import math
import os
from pathlib import Path
import re
import sys
import time


def default_value(name, fallback):
    if name in os.environ:
        return os.environ[name]
    try:
        text = (Path(__file__).parent / 'config' / 'paths.bat').read_text(encoding='ascii')
        match = re.search(r'set "' + re.escape(name) + r'=([^"%]+)"', text, re.I)
        if match:
            return match.group(1)
    except OSError:
        pass
    return fallback


def default_port():
    return default_value('UART_PORT', 'COM3')


def sanitize(data):
    return ''.join(chr(b) if 32 <= b < 127 or b in (9, 10, 13) else f'<{b:02x}>' for b in data)


def positive_seconds(value):
    number = float(value)
    if not math.isfinite(number) or number <= 0:
        raise argparse.ArgumentTypeError('duration must be finite and greater than zero')
    return number


def capture(ser, args, log, clock=time.monotonic):
    patterns = [re.compile(p) for p in (args.count or [])]
    hits = [0] * len(patterns)
    samples = [[] for _ in patterns]
    total = 0
    started = clock()
    deadline = started + args.duration if args.duration is not None else None
    buffer = b''
    interrupted = False

    def emit(message):
        print(message, flush=True)
        log.write(message + '\n')
        log.flush()

    def line_received(raw, complete=True):
        line = sanitize(raw.rstrip(b'\r'))
        suffix = '' if complete else ' [partial; excluded from counts]'
        emit(f'[{clock()-started:10.3f}s] {line}{suffix}')
        if complete:
            for i, pattern in enumerate(patterns):
                if pattern.search(line):
                    hits[i] += 1
                    if len(samples[i]) < 3:
                        samples[i].append(line)

    try:
        while deadline is None or clock() < deadline:
            ser.timeout = 0.2 if deadline is None else max(0, min(0.2, deadline-clock()))
            data = ser.read(min(256, ser.in_waiting or 1))
            total += len(data)
            buffer += data
            while b'\n' in buffer:
                line, buffer = buffer.split(b'\n', 1)
                line_received(line)
            if len(buffer) >= 65536:
                # Bound memory for a binary stream or missing line delimiters.
                line_received(buffer, complete=False)
                buffer = b''
    except KeyboardInterrupt:
        interrupted = True
    finally:
        if buffer:
            line_received(buffer, complete=False)
    elapsed = clock() - started
    emit(f'[uart] elapsed={elapsed:.3f}s bytes={total}')
    for pattern, count, found in zip(args.count or [], hits, samples):
        emit(f'[uart] count[{pattern}] = {count}')
        for sample in found:
            emit(f'[uart] sample[{pattern}]: {sample}')
    return {'bytes': total, 'counts': hits, 'elapsed': elapsed, 'interrupted': interrupted}


def main(argv=None):
    ap = argparse.ArgumentParser(description='Capture UART logs and count matching complete lines')
    ap.add_argument('--port', default=default_port())
    ap.add_argument('--baud', type=int, default=default_value('UART_BAUD', '115200'))
    ap.add_argument('--out', default='uart.log', help='append timestamped lines and summary')
    ap.add_argument('--list', action='store_true')
    ap.add_argument('--count', action='append', metavar='REGEX', help='independent count per regex')
    ap.add_argument('--duration', type=positive_seconds, help='seconds; default 15 for --count, otherwise unlimited')
    args = ap.parse_args(argv)
    if args.baud <= 0:
        ap.error('--baud must be positive')
    if args.count:
        try:
            for pattern in args.count:
                re.compile(pattern)
        except re.error as exc:
            ap.error(f'invalid --count regex: {exc}')
        if args.duration is None:
            args.duration = 15.0
    try:
        import serial
    except ImportError:
        print('[uart][ERROR] pyserial missing; use dt.bat/dt.ps1 with the complete bundled Python directory', file=sys.stderr)
        return 2
    if args.list:
        from serial.tools import list_ports
        for port in list_ports.comports():
            print(f'{port.device}  {port.description}')
        return 0
    try:
        with serial.Serial(args.port, args.baud, timeout=0.2) as ser:
            with open(args.out, 'a', encoding='utf-8') as log:
                print(f'[uart] capturing {args.port}@{args.baud} -> {args.out}', flush=True)
                capture(ser, args, log)
        return 0
    except (serial.SerialException, OSError) as exc:
        print(f'[uart][ERROR] {exc}', file=sys.stderr)
        return 1


if __name__ == '__main__':
    sys.exit(main())
