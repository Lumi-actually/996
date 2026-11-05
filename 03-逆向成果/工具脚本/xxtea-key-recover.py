#!/usr/bin/env python3
"""Recover the Cocos XXTEA key used by the 996 client.

Encrypted asset layout (verified):  b"XdvFTgd5YA" + xxtea_ciphertext

Strategy: collect every 16-byte printable-ASCII candidate from libMyGame.so's
rodata, run standard XXTEA decryption on the smallest encrypted Lua file, and
keep candidates whose plaintext looks like Lua source.
"""
import struct
import sys
import zipfile

APK = r"D:\project\新建文件夹\mingyang-mobile\downloads\996-engine\client-android.apk"
SO_PATH = r"D:\asdk\tmp\libMyGame.so"
SIGN = b"XdvFTgd5YA"

DELTA = 0x9E3779B9
MASK = 0xFFFFFFFF


def xxtea_decrypt(data: bytes, key: bytes) -> bytes:
    if len(data) < 8:
        return b""
    pad = (-len(data)) % 4
    if pad:
        data = data + b"\x00" * pad
    n = len(data) // 4
    v = list(struct.unpack("<%dI" % n, data))
    k = list(struct.unpack("<4I", key))

    rounds = 6 + 52 // n
    total = (rounds * DELTA) & MASK
    y = v[0]
    while total != 0:
        e = (total >> 2) & 3
        for p in range(n - 1, 0, -1):
            z = v[p - 1]
            v[p] = (v[p] - ((((z >> 5) ^ (y << 2)) + ((y >> 3) ^ (z << 4))) ^ ((total ^ y) + (k[(p & 3) ^ e] ^ z)))) & MASK
            y = v[p]
        p = 0
        z = v[n - 1]
        v[0] = (v[0] - ((((z >> 5) ^ (y << 2)) + ((y >> 3) ^ (z << 4))) ^ ((total ^ y) + (k[(p & 3) ^ e] ^ z)))) & MASK
        y = v[0]
        total = (total - DELTA) & MASK
    return struct.pack("<%dI" % n, *v)


def looks_like_lua(b: bytes) -> bool:
    if not b:
        return False
    head = b[:400]
    printable = sum(1 for c in head if 9 <= c <= 13 or 32 <= c < 127)
    if printable / max(1, len(head)) < 0.92:
        return False
    txt = head.decode("latin1", "replace").lstrip("\ufeff \t\r\n")
    kw = ("--", "local ", "function", "module", "return", "require", "print", "if ", "self")
    return any(txt.startswith(k) or k in txt[:200] for k in kw)


def main() -> int:
    z = zipfile.ZipFile(APK)
    lua = [n for n in z.namelist() if n.startswith("assets/mod_fgcq/") and n.endswith(".lua")]
    lua.sort(key=lambda n: z.getinfo(n).file_size)
    sample_name = lua[0]
    sample = z.read(sample_name)
    print("sample: %s  %d bytes" % (sample_name, len(sample)))
    assert sample.startswith(SIGN), "unexpected header: %r" % sample[:16]
    cipher = sample[len(SIGN):]

    so = open(SO_PATH, "rb").read()
    print("libMyGame.so: %d bytes" % len(so))

    # candidate keys: printable ASCII runs, truncated/taken as 16 bytes
    cands = set()
    run = bytearray()
    for i, byte in enumerate(so):
        if 32 <= byte < 127:
            run.append(byte)
            continue
        if len(run) >= 16:
            b = bytes(run)
            cands.add(b[:16])
            cands.add(b[-16:])
        run = bytearray()
    # also all 16-byte windows inside long runs
    run = bytearray()
    for byte in so:
        if 32 <= byte < 127:
            run.append(byte)
        else:
            if len(run) > 16:
                b = bytes(run)
                for off in range(0, len(b) - 16 + 1):
                    cands.add(b[off:off + 16])
            run = bytearray()
    print("candidate keys: %d" % len(cands))

    hits = []
    for key in cands:
        out = xxtea_decrypt(cipher, key)
        if looks_like_lua(out):
            hits.append((key, out[:120]))
            print("\n*** HIT key=%r" % key)
            print("    %r" % out[:200])
            if len(hits) >= 5:
                break

    if not hits:
        print("\nno hit among plaintext candidates")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
