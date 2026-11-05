#!/usr/bin/env python3
"""对 996 客户端的 XXTEA 加密做 key 暴力搜索。

思路：
  Cocos2d-x 的 FileUtils::addXXTEAKeyAndSign(key, sign) 把 key 编译进 libMyGame.so 的 .rodata，
  sign 会写进文件头。所以：
    1. 从 .so 抽出全部可打印字符串当候选 key（几百到几万条）
    2. 用每个候选解一个小样本文件（去掉 sign 头后的 XXTEA 密文）
    3. 用"解出来像不像 Lua 源码"打分，命中即停

用法:
    python xxtea-bruteforce.py --apk <apk> --target assets/mod_launcher/stab/scripts/logic/LoadingBarManager_launcher.lua
    python xxtea-bruteforce.py --apk <apk> --target <path> --lib lib/arm64-v8a/libMyGame.so --lib lib/armeabi-v7a/libMyGame.so
"""
import sys
import zipfile
import struct
import argparse
import re

sys.stdout.reconfigure(encoding="utf-8")
DELTA = 0x9E3779B9
MASK = 0xFFFFFFFF

LUA_HINTS = (b"local ", b"function", b"return", b"end", b"--", b"self.", b"true", b"false", b"nil")


def xxtea_decrypt(data: bytes, key: bytes) -> bytes:
    n = len(data) // 4
    if n < 2:
        return b""
    v = list(struct.unpack("<%dI" % n, data[: n * 4]))
    kk = (key + b"\x00" * 16)[:16]
    k = list(struct.unpack("<4I", kk))
    rounds = 6 + 52 // n
    total = (rounds * DELTA) & MASK

    def mx(y, z, p, e, s):
        return ((((z >> 5) ^ (y << 2)) + ((y >> 3) ^ (z << 4))) ^ ((s ^ y) + (k[(p & 3) ^ e] ^ z))) & MASK

    y = v[0]
    while total:
        e = (total >> 2) & 3
        for p in range(n - 1, 0, -1):
            z = v[p - 1]
            v[p] = (v[p] - mx(y, z, p, e, total)) & MASK
            y = v[p]
        z = v[n - 1]
        v[0] = (v[0] - mx(y, z, 0, e, total)) & MASK
        y = v[0]
        total = (total - DELTA) & MASK

    return struct.pack("<%dI" % n, *v)


def score(data: bytes) -> float:
    if not data:
        return 0.0
    head = data[:256]
    printable = sum(1 for b in head if 32 <= b < 127 or b in (9, 10, 13))
    s = printable / len(head)
    hits = sum(1 for h in LUA_HINTS if h in data[:2048])
    return s + hits * 0.35


def extract_strings(data: bytes, min_len=4, max_len=64):
    out = set()
    cur = bytearray()
    for b in data:
        if 32 <= b < 127:
            cur.append(b)
        else:
            if min_len <= len(cur) <= max_len:
                out.add(bytes(cur))
            cur = bytearray()
    if min_len <= len(cur) <= max_len:
        out.add(bytes(cur))
    return out


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--apk", required=True)
    ap.add_argument("--target", required=True)
    ap.add_argument("--lib", action="append", default=None)
    ap.add_argument("--max-key", type=int, default=64)
    args = ap.parse_args()

    zf = zipfile.ZipFile(args.apk)
    try:
        blob = zf.read(args.target)
    except KeyError:
        print(f"目标不存在：{args.target}")
        return 1
    print(f"目标 {args.target}  {len(blob)} 字节")
    print(f"头部: {blob[:16].hex(' ')}  ascii={''.join(chr(b) if 32 <= b < 127 else '.' for b in blob[:16])}")

    # sign 检测：取开头的可打印前缀
    sign = bytearray()
    for b in blob[:16]:
        if 32 <= b < 127:
            sign.append(b)
        else:
            break
    sign = bytes(sign)
    print(f"sign 推断: {sign!r} ({len(sign)} 字节)")

    body = blob[len(sign):]
    print(f"密文 {len(body)} 字节，%4={len(body) % 4}")

    libs = args.lib or ["lib/arm64-v8a/libMyGame.so", "lib/armeabi-v7a/libMyGame.so"]
    cands = set()
    for lib in libs:
        try:
            so = zf.read(lib)
        except KeyError:
            continue
        print(f"从 {lib} 提取字符串…")
        cands |= extract_strings(so, 4, args.max_key)
    print(f"候选 key {len(cands)} 条")

    # 常见派生候选
    for extra in (b"dhsf", b"996", b"996m2", b"xqhuyu", b"cq2"):
        cands.add(extra)

    best = []
    total = len(cands)
    for i, key in enumerate(cands, 1):
        try:
            out = xxtea_decrypt(body, key)
        except Exception:
            continue
        s = score(out)
        if s > 1.6:
            preview = "".join(chr(b) if 32 <= b < 127 else "." for b in out[:60])
            print(f"  ★ score={s:.2f} key={key!r}  {preview}")
            best.append((s, key, out))
        if i % 5000 == 0:
            print(f"  …已试 {i}/{total}")

    if not best:
        print("\n没有命中。可能 key 不在字符串表里（运行时拼装/异或混淆），需要动态 hook。")
        return 1

    best.sort(key=lambda x: -x[0])
    s, key, out = best[0]
    print(f"\n最佳 key: {key!r}  score={s:.2f}")
    print("--- 解密结果前 1500 字节 ---")
    print(out[:1500].decode("utf-8", "replace"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
