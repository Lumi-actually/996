#!/usr/bin/env python3
"""按 Cocos2d-x 的 addXXTEAKeyAndSign 规则解密 996 资源。

实测依据（libMyGame.so 符号表）：
    _ZN7cocos2d9FileUtils18addXXTEAKeyAndSignENSt6__ndk112basic_stringIc..EE S7_   (key, sign)
    _ZN7cocos2d9FileUtils20addXXTEAKeyAndSignV2E..V3E..V4E
    _ZN12LuaBridgeCtl19initXXTeaAndLookupsEv
    _ZN12LuaBridgeCtl13SetXXTEAKeyGME...

即文件格式 = [sign 字符串][XXTEA 密文]，key 是注册的字符串（按 4 字节取），
不是 hex 解码后的 16 字节。

用法:
    python xxtea-cocos-try.py --url http://list-new.dhsf.xqhuyu.com/serverlist/143097/serverlist.txt
    python xxtea-cocos-try.py --file a.bin --sign 4meJnPyl --keys k1,k2
"""
import sys
import struct
import base64
import binascii
import urllib.request

sys.stdout.reconfigure(encoding="utf-8")
DELTA = 0x9E3779B9
MASK = 0xFFFFFFFF


def xxtea_decrypt(data: bytes, key: bytes) -> bytes:
    """标准 XXTEA，按小端 32 位；key 取前 16 字节。"""
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
    s = data[:4096]
    printable = sum(1 for b in s if 32 <= b < 127 or b in (9, 10, 13))
    return printable / len(s) + (0.6 if b"{" in s and b'"' in s else 0.0)


def main() -> int:
    args = sys.argv[1:]
    if not args:
        print(__doc__)
        return 2

    if "--url" in args:
        url = args[args.index("--url") + 1]
        req = urllib.request.Request(url, headers={"User-Agent": "Dalvik/2.1.0"})
        raw = urllib.request.urlopen(req, timeout=20).read()
    elif "--file" in args:
        with open(args[args.index("--file") + 1], "rb") as fh:
            raw = fh.read()
    else:
        print(__doc__)
        return 2

    try:
        data = base64.b64decode(raw.strip(), validate=False)
        print(f"Base64 解码：{len(raw)} → {len(data)} 字节")
    except binascii.Error:
        data = raw
        print(f"非 Base64，按原始字节 {len(data)}")

    # sign 候选：从数据开头取可打印前缀
    prefix = bytearray()
    for b in data[:32]:
        if 32 <= b < 127:
            prefix.append(b)
        else:
            break
    detected_sign = bytes(prefix).decode("latin-1")
    print(f"检测到文件头 sign：{detected_sign!r} ({len(prefix)} 字节)")

    signs = []
    if "--sign" in args:
        signs = [args[args.index("--sign") + 1].encode()]
    else:
        if detected_sign:
            signs.append(prefix)
        for extra in (b"XdvFTgd5YA", b"4meJnPyl", b""):
            if extra not in signs:
                signs.append(extra)

    key_strings = [
        "9d2fb256de15cb42149f4ffb1093ae0c",
        "ac2fb8c18309b2c5458e14b41dc9f280",
        "2b28a509e36111167c5f5bea6b02bc3f",
        "dhsf",
        "996",
    ]
    keys = [(f"str:{k}", k.encode()) for k in key_strings]
    keys.append(("hex:signkey", binascii.unhexlify("9d2fb256de15cb42149f4ffb1093ae0c")))

    best = None
    for sign in signs:
        body = data[len(sign):] if (sign and data.startswith(sign)) else data
        print(f"\n-- sign={sign!r} 去头后 {len(body)} 字节 (%4={len(body) % 4}) --")
        for name, key in keys:
            out = xxtea_decrypt(body, key)
            s = score(out)
            preview = "".join(chr(b) if 32 <= b < 127 else "." for b in out[:72])
            flag = "   <<< 可读" if s > 1.2 else ""
            print(f"   {name:<22} score={s:.2f}  {preview}{flag}")
            if best is None or s > best[0]:
                best = (s, sign, name, out)

    if best and best[0] > 1.0:
        print(f"\n最佳：sign={best[1]!r} key={best[2]} score={best[0]:.2f}")
        print("--- 前 2000 字节 ---")
        print(best[3][:2000].decode("utf-8", "replace"))
    else:
        print("\n仍未命中。下一步：hook FileUtils::addXXTEAKeyAndSign 直接读运行时 key/sign。")
    return 0


if __name__ == "__main__":
    sys.exit(main())
