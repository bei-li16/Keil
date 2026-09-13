#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
uart_capture.py - 调试串口抓取:目标固件的 UART 输出带时间戳落盘并回显。

用法:
    python uart_capture.py                          # 用 config/paths.bat 里的默认口
    python uart_capture.py --port COM7 --baud 115200 --out uart.log
    python uart_capture.py --list                   # 列出可用串口后退出

依赖: pip install pyserial
AI 用法:以后台任务启动,之后读 --out 指定的日志文件即可。
"""
import argparse            # 命令行参数解析
import sys                 # stderr 与退出码
import time                # 相对时间戳

# pyserial 是可选依赖:缺库给明确指引而不是抛 traceback
try:
    import serial
except ImportError:
    print("[uart][ERROR] 未安装 pyserial,请先: pip install pyserial", file=sys.stderr)
    sys.exit(2)            # 2 = 依赖缺失,与"串口打不开"(1)区分


def default_port():
    """从 tools/config/paths.bat 解析 UART_PORT 默认值;读不到回退 COM5。"""
    import re, os
    # 本文件在 tools\serial\ 下,.. 即 tools 根,再进 config
    p = os.path.join(os.path.dirname(__file__), "..", "config", "paths.bat")
    try:
        # paths.bat 是 GBK 编码,errors="replace" 保证读取不炸
        with open(p, encoding="utf-8", errors="replace") as f:
            m = re.search(r'set "UART_PORT=(COM\d+)"', f.read())
        if m:
            return m.group(1)              # 捕获组,如 COM5
    except OSError:
        pass                               # 文件不存在就用默认值
    return "COM5"


def main():
    # ---------- 参数 ----------
    ap = argparse.ArgumentParser(description="STM32 调试串口抓取")
    ap.add_argument("--port", default=default_port())       # 串口名
    ap.add_argument("--baud", type=int, default=115200)     # 波特率
    ap.add_argument("--out", default="uart.log", help="输出文件(默认 uart.log)")
    ap.add_argument("--list", action="store_true", help="列出串口后退出")
    args = ap.parse_args()

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

    # ---------- 主循环:读 -> 打时间戳 -> 回显 + 落盘 ----------
    with open(args.out, "a", encoding="utf-8", errors="replace") as log:
        t0 = time.time()                   # 相对时间基准
        try:
            while True:
                data = ser.read(256)       # 0.2s 内到达的数据(空转返回 b"")
                if data:
                    # 可打印字符原样,控制/二进制字节显示 <hex>,不污染日志
                    line = "".join(chr(b) if 32 <= b < 127 or b in (9, 10, 13) else f"<{b:02x}>"
                                   for b in data)
                    stamp = f"[{time.time()-t0:10.3f}s] "
                    print(stamp + line, end="", flush=True)   # 终端实时回显
                    log.write(stamp + line)                   # 写文件
                    log.flush()                               # 即时刷盘
        except KeyboardInterrupt:
            print("\n[uart] stopped")          # Ctrl+C 正常退出


if __name__ == "__main__":
    main()
