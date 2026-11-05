#!/usr/bin/env python3
"""尝试用 XXTEA（标准 / Cocos2d-x 变体）解密 996 客户端拉取的加密配置。

背景：`serverlist_*.txt` 是 Base64 文本，解码后 7900 字节，非 16 的倍数，
      所以不是 AES-CBC；`libMyGame.so` 里同时带有 `XXTEA` / `xxtea` 字符串。

用法:
    python xxtea-try.py <base64文件> [--keys hex1,hex2]
    python xxtea-try.py --fetch http://list-new.dhsf.xqhuyu.com/serverlist/143097/serverlist.txt
"""
import sys
import struct
import base64
import binascii
import urllib.request

sys.stdout.reconfigure(encoding="utf-8")

DELTA = 0x9E3779B9
MASK = 0xFFFFFFFF


def xxtea_decrypt_raw(data: bytes, key: bytes) -> bytes:
    """标准 XXTEA（Corrected Block TEA），块按小端取 32 位。"""
    if len(data) < 8:
        return b""
    n = len(data) // 4
    v = list(struct.unpack("<%dI" % n, data[: n * 4]))
    k = list(struct.unpack("<4I", key[:16]))

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


def xxtea_decrypt_cocos(data: bytes, key: bytes) -> bytes:
    """Cocos2d-x 变体：前 4 字节是明文长度（大端），随后是密文。"""
    if len(data) < 4:
        return b""
    (length,) = struct.unpack(">I", data[:4])
    body = data[4:]
    # cocos 内部同样用 32 位块，但长度按字节补齐
    if len(body) % 4:
        body = body[: len(body) - (len(body) % 4)]
    if len(body) < 8:
        return b""
    n = len(body) // 4
    v = list(struct.unpack(">%dI" % n, body))
    k = list(struct.unpack(">4I", key[:16]))
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

    out = struct.pack(">%dI" % n, *v)
    return out[:length] if length <= len(out) else out


def score(data: bytes) -> float:
    if not data:
        return 0.0
    sample = data[:2048]
    printable = sum(1 for b in sample if 32 <= b < 127 or b in (9, 10, 13))
    braces = sample.count(b"{") + sample.count(b'"')
    return printable / len(sample) + (0.5 if braces > 3 else 0)


def main() -> int:
    args = sys.argv[1:]
    if not args:
        print(__doc__)
        return 2

    if "--fetch" in args:
        url = args[args.index("--fetch") + 1]
        req = urllib.request.Request(url, headers={"User-Agent": "Dalvik/2.1.0"})
        raw = urllib.request.urlopen(req, timeout=20).read()
    else:
        with open(args[0], "rb") as fh:
            raw = fh.read()

    text = raw.strip()
    try:
        data = base64.b64decode(text, validate=False)
    except binascii.Error:
        data = raw

    print(f"输入 {len(raw)} 字节文本 → Base64 解码 {len(data)} 字节")
    print(f"长度 %16 = {len(data) % 16}，%8 = {len(data) % 8}，%4 = {len(data) % 4}")
    print(f"前 32 字节: {data[:32].hex(' ')}")

    keys = []
    if "--keys" in args:
        for h in args[args.index("--keys") + 1].split(","):
            h = h.strip()
            if h:
                keys.append((h, binascii.unhexlify(h)))
    else:
        keys = [
            ("signkey", binascii.unhexlify("9d2fb256de15cb42149f4ffb1093ae0c")),
            ("envkey-env", binascii.unhexlify("ac2fb8c18309b2c5458e14b41dc9f280")),
            ("envkey-sdk", binascii.unhexlify("2b28a509e36111167c5f5bea6b02bc3f")),
        ]

    best = None
    for name, key in keys:
        for label, fn in (("xxtea-raw", xxtea_decrypt_raw), ("xxtea-cocos", xxtea_decrypt_cocos)):
            try:
                out = fn(data, key)
            except Exception as e:
                print(f"  {name:<12} {label:<12} 异常 {e}")
                continue
            s = score(out)
            head = out[:80]
            preview = "".join(chr(b) if 32 <= b < 127 else "." for b in head)
            flag = "  <<<" if s > 1.2 else ""
            print(f"  {name:<12} {label:<12} score={s:.2f}  {preview}{flag}")
            if best is None or s > best[0]:
                best = (s, name, label, out)

    if best and best[0] > 1.0:
        print(f"\n最佳候选：{best[1]} / {best[2]}  score={best[0]:.2f}")
        print("--- 前 1500 字节 ---")
        print(best[3][:1500].decode("utf-8", "replace"))
    else:
        print("\n没有命中可读明文，需要换 key 或换算法（可能是自定义流加密 / 先 AES 再 XXTEA）")
    return 0


if __name__ == "__main__":
    sys.exit(main())
