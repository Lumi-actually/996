#!/usr/bin/env python3
"""Decrypt every XXTEA-protected Lua file shipped in the 996 client APK.

File layout (confirmed by reversing FileUtils::getDataFromFile):
    [10-byte sign "XdvFTgd5YA"][xxtea ciphertext]

Usage:
    python xxtea-decrypt-all.py --key-hex 00112233445566778899aabbccddeeff
    python xxtea-decrypt-all.py --key-ascii wVTx3dT01j
    python xxtea-decrypt-all.py --key-hex ... --out D:\\asdk\\lua-decrypted

Reports how many files decrypted to real Lua (bytecode magic 1b 4c 75 61 or
printable Lua source) so a wrong key is obvious.
"""
import argparse
import importlib.util
import os
import sys
import zipfile

_HERE = os.path.dirname(os.path.abspath(__file__))


def _load_helper():
    """Load xxtea-key-recover.py (hyphenated filename) by path."""
    mod_path = os.path.join(_HERE, "xxtea-key-recover.py")
    spec = importlib.util.spec_from_file_location("xxtea_key_recover", mod_path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


xxtea_decrypt = _load_helper().xxtea_decrypt

APK = r"D:\project\新建文件夹\mingyang-mobile\downloads\996-engine\client-android.apk"
SIGN = b"XdvFTgd5YA"
LUA_MAGIC = b"\x1bLua"


def looks_like_lua_source(b: bytes) -> bool:
    if not b:
        return False
    head = b[:300]
    printable = sum(1 for c in head if 9 <= c <= 13 or 32 <= c < 127)
    if printable / max(1, len(head)) < 0.95:
        return False
    txt = head.decode("latin1", "replace").lstrip("\ufeff \t\r\n")
    keys = ("--", "local ", "function", "return", "module", "require", "print", "if ", "self")
    return any(txt.startswith(k) or k in txt[:150] for k in keys)


def main() -> int:
    ap = argparse.ArgumentParser()
    g = ap.add_mutually_exclusive_group(required=True)
    g.add_argument("--key-hex")
    g.add_argument("--key-ascii")
    ap.add_argument("--out", default=r"D:\asdk\lua-decrypted")
    ap.add_argument("--apk", default=APK)
    ap.add_argument("--limit", type=int, default=0, help="only process N files (debug)")
    args = ap.parse_args()

    if args.key_hex:
        key = bytes.fromhex(args.key_hex)
    else:
        key = args.key_ascii.encode("latin1")
    if len(key) < 16:
        key = key + b"\x00" * (16 - len(key))
    key = key[:16]
    print("key = %s (hex %s)" % (key, key.hex()))

    z = zipfile.ZipFile(args.apk)
    targets = [n for n in z.namelist() if n.endswith(".lua")]
    signed = []
    for n in targets:
        try:
            head = z.open(n).read(len(SIGN))
        except Exception:
            continue
        if head == SIGN:
            signed.append(n)
    print("lua in apk: %d, with XXTEA sign: %d" % (len(targets), len(signed)))
    if args.limit:
        signed = signed[: args.limit]

    ok = byte = text = 0
    os.makedirs(args.out, exist_ok=True)
    for n in signed:
        raw = z.read(n)
        body = raw[len(SIGN):]
        try:
            out = xxtea_decrypt(body, key)
        except Exception as exc:  # noqa: BLE001
            continue
        if out.startswith(LUA_MAGIC):
            byte += 1
        elif looks_like_lua_source(out):
            text += 1
        else:
            continue
        ok += 1
        rel = n.replace("assets/mod_fgcq/stab/", "").replace("/", os.sep)
        dst = os.path.join(args.out, rel)
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        with open(dst, "wb") as fh:
            fh.write(out)

    print("\ndecrypted ok=%d  (bytecode=%d, source=%d)  out=%s" % (ok, byte, text, args.out))
    if ok == 0:
        print("=> wrong key: nothing decrypted")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
