#!/usr/bin/env python3
"""检查 996 安卓客户端的 assets 结构、Lua 是否明文、计费/授权相关代码位置。

用法:
    python inspect-apk-assets.py <apk> [--grep 授权,vip,pay] [--samples 5]
"""
import sys
import zipfile
import os
import collections
import re

sys.stdout.reconfigure(encoding="utf-8")

DEFAULT_KEYWORDS = [
    "授权", "过期", "未开通", "购买", "充值", "支付", "订单", "实名", "试玩",
    "vip", "VIP", "pay", "Pay", "order", "Order", "recharge", "Recharge",
    "channel", "sdk", "SDK", "login", "Login", "token", "license", "License",
]


def is_printable_ratio(data: bytes) -> float:
    if not data:
        return 0.0
    printable = sum(1 for b in data[:4096] if 32 <= b < 127 or b in (9, 10, 13, 0x20))
    return printable / min(len(data), 4096)


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    apk = sys.argv[1]
    keywords = DEFAULT_KEYWORDS
    if "--grep" in sys.argv:
        keywords = sys.argv[sys.argv.index("--grep") + 1].split(",")
    samples = 5
    if "--samples" in sys.argv:
        samples = int(sys.argv[sys.argv.index("--samples") + 1])

    zf = zipfile.ZipFile(apk)
    names = zf.namelist()

    # 1. assets 顶层分布
    asset_names = [n for n in names if n.startswith("assets/")]
    print(f"== assets 条目 {len(asset_names)} ==")
    top = collections.Counter()
    for n in asset_names:
        parts = n.split("/")
        key = parts[1] if len(parts) > 1 else "(root)"
        top[key] += 1
    for k, v in top.most_common(20):
        print(f"   {k:<40} {v}")

    # 2. Lua 概览：是否明文/编译
    lua_names = [n for n in names if n.lower().endswith(".lua")]
    print(f"\n== .lua 文件 {len(lua_names)} 个 ==")
    plain = 0
    compiled = 0
    big = []
    for n in lua_names:
        try:
            head = zf.read(n)[:32]
        except Exception:
            continue
        if head.startswith(b"\x1bLua") or head.startswith(b"\x1bLJ"):
            compiled += 1
        elif is_printable_ratio(head) > 0.9:
            plain += 1
        info = zf.getinfo(n)
        big.append((info.file_size, n))
    print(f"   明文文本: {plain}   编译字节码: {compiled}")
    big.sort(reverse=True)
    print("   最大的 10 个：")
    for size, n in big[:10]:
        print(f"     {size:>10,}  {n}")

    # 3. 关键词扫描（只扫明文 lua + json + txt）
    print(f"\n== 关键词命中（{len(keywords)} 个词） ==")
    hits = collections.Counter()
    examples = {}
    scanned = 0
    for n in names:
        low = n.lower()
        if not (low.endswith(".lua") or low.endswith(".json") or low.endswith(".txt") or low.endswith(".proto")):
            continue
        try:
            raw = zf.read(n)
        except Exception:
            continue
        scanned += 1
        if is_printable_ratio(raw) < 0.85:
            continue
        try:
            text = raw.decode("utf-8", errors="ignore")
        except Exception:
            continue
        for kw in keywords:
            if kw in text:
                hits[kw] += 1
                examples.setdefault(kw, (n, text))
    print(f"   扫描文件 {scanned} 个")
    for kw, count in hits.most_common(30):
        n, text = examples[kw]
        idx = text.find(kw)
        line_no = text.count("\n", 0, idx) + 1
        snippet = text[max(0, idx - 60):idx + 80].replace("\n", " ").replace("\r", " ")
        print(f"   {kw:<12} {count:>4} 次  例: {n}:{line_no}  …{snippet}…")

    # 4. 明文 lua 抽样
    if samples > 0 and plain > 0:
        print(f"\n== 明文 lua 抽样（前 {samples} 个） ==")
        shown = 0
        for n in lua_names:
            if shown >= samples:
                break
            try:
                raw = zf.read(n)
            except Exception:
                continue
            if raw.startswith(b"\x1bLua") or is_printable_ratio(raw) < 0.9:
                continue
            print(f"\n--- {n} ({len(raw)} bytes) ---")
            print(raw[:700].decode("utf-8", errors="replace"))
            shown += 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
