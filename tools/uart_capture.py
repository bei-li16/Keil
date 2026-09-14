#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
uart_capture.py - 调试串口抓取:目标固件的 UART 输出带时间戳落盘并回显。

用法(dt.bat 的 uart 子命令封装了本脚本,也可直接运行):
    python uart_capture.py                          # 用 config/paths.bat 里的默认口
    python uart_capture.py --port COM7 --baud 115200 --out uart.log
    python uart_capture.py --list                   # 列出可用串口后退出
    python uart_capture.py --count "Task100ms" --duration 15   # 定时窗统计(固件心跳验收)

依赖: pip install pyserial
AI 用法:以后台任务启动,之后读 --out 指定的日志文件即可。
"""
import argparse            # 命令行参数解析
import sys                 # stderr 与退出码
import time                # 相对时间戳


def default_port():
    """从 tools/config/paths.bat 解析 UART_PORT 默认值;读不到回退 COM5。"""
    import re, os
    # 本文件在 tools 根目录,config/paths.bat 在其下
    p = os.path.join(os.path.dirname(__file__), "config", "paths.bat")
    try:
        # paths.bat 是 GBK 编码,errors="replace" 保证读取不炸
        with open(p, encoding="utf-8", errors="replace") as f:
            m = re.search(r'set "UART_PORT=(COM\d+)"', f.read())
        if m:
            return m.group(1)              # 捕获组,如 COM5
    except OSError:
        pass                               # 文件不存在就用默认值
    return "COM5"


def sanitize(data: bytes) -> str:
    """字节流转可读文本:可打印字符原样,控制/二进制字节显示 <hex>,不污染日志。"""
    return "".join(chr(b) if 32 <= b < 127 or b in (9, 10, 13) else f"<{b:02x}>" for b in data)


def run_counted(ser, args):
    """定时窗采集 + 正则统计:固件心跳/任务日志验收用,窗口结束打印汇总。"""
    import re
    if args.duration <= 0:
        print("[uart][ERROR] --count 模式需要有限的 --duration(秒)", file=sys.stderr)
        sys.exit(2)
    pats = [re.compile(p) for p in args.count]
    print(f"[uart] counting {args.duration:g}s on {args.port}, {len(pats)} pattern(s) ...")
    deadline = time.time() + args.duration
    total = 0
    hits = [0] * len(pats)
    others = []                      # 不匹配任何模式的行样本(最多 5 条)
    samples = [[] for _ in pats]     # 每个模式最多留 3 条匹配行样本(看实际数值)
    buf = ""                         # 行缓冲,半行留到下一轮
    while time.time() < deadline:
        data = ser.read(256)         # 0.2s 内到达的数据(空转返回 b"")
        if not data:
            continue
        total += len(data)
        buf += sanitize(data)
        while "\n" in buf:
            line, buf = buf.split("\n", 1)
            line = line.rstrip("\r")
            if not line:
                continue
            for i, p in enumerate(pats):
                if p.search(line):
                    hits[i] += 1
                    if len(samples[i]) < 3:
                        samples[i].append(line)
                    break
            else:
                if len(others) < 5:
                    others.append(line)
    if buf.strip():                  # 收尾半行也计入统计
        for i, p in enumerate(pats):
            if p.search(buf):
                hits[i] += 1
                break
        else:
            others.append(buf.strip())
    print(f"[uart] window={args.duration:g}s bytes={total}")
    for p, n in zip(args.count, hits):
        print(f"[uart] count[{p}] = {n}")
    for p, ss in zip(args.count, samples):
        for s in ss:
            print(f"[uart] sample[{p}]: {s}")
    if others:
        print("[uart] --- other lines (up to 5) ---")
        for line in others:
            print("[uart]   " + line)


def main():
    # ---------- 参数 ----------
    ap = argparse.ArgumentParser(description="STM32 调试串口抓取")
    ap.add_argument("--port", default=default_port())       # 串口名
    ap.add_argument("--baud", type=int, default=115200)     # 波特率
    ap.add_argument("--out", default="uart.log", help="输出文件(默认 uart.log)")
    ap.add_argument("--list", action="store_true", help="列出串口后退出")
    ap.add_argument("--count", action="append", metavar="REGEX",
                    help="统计匹配 REGEX 的行数,窗口结束打印汇总(可重复传多个模式)")
    ap.add_argument("--duration", type=float, default=15.0,
                    help="监听秒数(--count 模式的采集窗,默认 15;流式模式忽略此参)")
    args = ap.parse_args()

    # pyserial 是可选依赖:缺库给明确指引而不是抛 traceback
    # 放在 parse_args 之后,保证 --help / 参数错误提示不依赖第三方库
    try:
        import serial
    except ImportError:
        print("[uart][ERROR] 未安装 pyserial,请先: pip install pyserial", file=sys.stderr)
        sys.exit(2)            # 2 = 依赖缺失,与"串口打不开"(1)区分

    # ---------- --list:枚举系统串口 ----------
    if args.list:
        from serial.tools import list_ports
        for p in list_ports.comports():
            print(f"{p.device}  {p.description}")
        return

    # ---------- 打开串口 ----------
    try:
        # timeout=0.2:read() 最多等 0.2s 返回,配合循环准实时抓取
        ser = serial.Serial(args.port, args.baud, timeout=0.2)
    except serial.SerialException as e:
        # 常见:口号不对 / 被占用 / USB-TTL 未插
        print(f"[uart][ERROR] 打开 {args.port} 失败: {e}", file=sys.stderr)
        print("[uart] 提示:--list 查看可用串口;检查是否被其他程序占用", file=sys.stderr)
        sys.exit(1)

    print(f"[uart] capturing {args.port}@{args.baud} -> {args.out} (Ctrl+C 停止)")

    if args.count:
        run_counted(ser, args)
        return

    # ---------- 主循环:读 -> 打时间戳 -> 回显 + 落盘 ----------
    with open(args.out, "a", encoding="utf-8", errors="replace") as log:
        t0 = time.time()                   # 相对时间基准
        try:
            while True:
                data = ser.read(256)       # 0.2s 内到达的数据(空转返回 b"")
                if data:
                    # 可打印字符原样,控制/二进制字节显示 <hex>,不污染日志
                    line = sanitize(data)
                    stamp = f"[{time.time()-t0:10.3f}s] "
                    print(stamp + line, end="", flush=True)   # 终端实时回显
                    log.write(stamp + line)                   # 写文件
                    log.flush()                               # 即时刷盘
        except KeyboardInterrupt:
            print("\n[uart] stopped")          # Ctrl+C 正常退出


if __name__ == "__main__":
    main()
