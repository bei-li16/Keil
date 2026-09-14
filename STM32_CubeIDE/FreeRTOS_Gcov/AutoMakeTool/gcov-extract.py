#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
gcov-extract.py - 解析固件导出的 gcov 记录流,还原成 gcov 工具可用的 .gcda 文件

三种导出方式(RAM dump / RTT / semihosting)产生的都是同一种记录流格式:
    记录 = [u32le 文件名长度][文件名(含NUL)] ([u32le 块长度][块数据])* 直到块长度为0
    流尾 = u32le 0 结束标记
同名源文件出现多次时取最后一次(最新计数),最终写出 build/<源文件名>.gcda。

用法:
    python gcov-extract.py [输入文件] [-o 输出目录]
    python gcov-extract.py --list gcov_blob.bin     # 只列出包含的源文件
默认输入 ./gcov_blob.bin,输出目录 ./build
"""
import argparse
import os
import struct
import sys


def parse_stream(data):
    """解析记录流,返回 {源文件路径: gcda字节串},遇到结束标记或数据耗尽为止"""
    files = {}
    pos, n = 0, len(data)
    while pos + 4 <= n:
        (name_len,) = struct.unpack_from("<I", data, pos)
        pos += 4
        if name_len == 0:                       # 整条流结束
            break
        if pos + name_len > n:
            break
        name = data[pos:pos + name_len].split(b"\0")[0].decode("utf-8", "replace")
        pos += name_len
        chunks = bytearray()
        while pos + 4 <= n:
            (chunk_len,) = struct.unpack_from("<I", data, pos)
            pos += 4
            if chunk_len == 0:                  # 当前文件的块流结束
                break
            if pos + chunk_len > n:
                print("警告: 数据截断于 %r" % name, file=sys.stderr)
                return files
            chunks += data[pos:pos + chunk_len]
            pos += chunk_len
        files[name] = bytes(chunks)             # 同名取最后一次(最新)
    return files


def gcda_name(src):
    """bsp_led.c -> bsp_led.gcda (与 gcov 查找规则一致)"""
    base = os.path.basename(src.replace("\\", "/"))
    stem, _ = os.path.splitext(base)
    return stem + ".gcda"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("input", nargs="?", default="gcov_blob.bin")
    ap.add_argument("-o", "--outdir", default="build")
    ap.add_argument("--list", action="store_true", help="仅列出包含的源文件")
    args = ap.parse_args()

    with open(args.input, "rb") as f:
        data = f.read()
    files = parse_stream(data)

    if not files:
        print("未解析到任何记录:%s 为空或格式不符" % args.input, file=sys.stderr)
        return 1

    if args.list:
        for name in files:
            print("%s (%d bytes)" % (name, len(files[name])))
        return 0

    os.makedirs(args.outdir, exist_ok=True)
    for src, blob in files.items():
        out = os.path.join(args.outdir, gcda_name(src))
        with open(out, "wb") as f:
            f.write(blob)
        print("%s <- %s (%d bytes)" % (out, src, len(blob)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
