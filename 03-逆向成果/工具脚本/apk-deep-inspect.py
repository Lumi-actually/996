#!/usr/bin/env python3
"""996 安卓客户端深度检查：配置、原生库、Lua 加密特征、SDK 与授权线索。

用法:
    python apk-deep-inspect.py <apk> [--dumplua N] [--dir OUT]
"""
import sys
import zipfile
import os
import collections
import struct

sys.stdout.reconfigure(encoding="utf-8")

CONFIG_CANDIDATES = [
    "assets/env.json",
    "assets/sdk_info.txt",
    "assets/supplierconfig.json",
    "assets/libUnionCloud.json",
    "assets/xqhy_cloudPhone_sdk.json",
    "assets/xqhy_cloudPhone_sdk_config.json",
    "assets/game.dat",
    "assets/.record/ues",
]
TEXT_EXT = (".json", ".txt", ".ini", ".xml", ".cfg", ".dat", ".properties")

LUA_SIGNATURES = {
    "lua 5.3 bytecode": b"\x1bLua",
    "lua 5.1 bytecode": b"\x1bLuaQ",
    "luaJIT": b"\x1bLJ",
}


def show(name, data, limit=1200):
    print(f"\n===== {name} ({len(data):,} bytes) =====")
    for enc in ("utf-8-sig", "gbk", "latin-1"):
        try:
            t = data.decode(enc)
        except Exception:
            continue
        bad = t.count("\ufffd")
        if bad < len(t) * 0.02:
            print(f"[{enc}]")
            print(t[:limit])
            return
    print("[binary] first 96 bytes hex:")
    print(data[:96].hex(" "))


def classify_lua(head: bytes) -> str:
    for label, sig in LUA_SIGNATURES.items():
        if head.startswith(sig):
            return label
    # 常见加密特征
    if head[:4] == b"\x00\x00\x00\x00":
        return "可能加密（前 4 字节为 0）"
    return "非标准头（加密或私有封装）"


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    apk = sys.argv[1]
    dump_n = 0
    if "--dumplua" in sys.argv:
        dump_n = int(sys.argv[sys.argv.index("--dumplua") + 1])

    zf = zipfile.ZipFile(apk)
    names = zf.namelist()

    # 1) 原生库
    print("== 原生库 ==")
    libs = [n for n in names if n.startswith("lib/") and n.endswith(".so")]
    for n in sorted(libs):
        info = zf.getinfo(n)
        print(f"   {info.file_size:>10,}  {n}")

    # 2) 配置文件
    print("\n== 关键配置文件 ==")
    for c in CONFIG_CANDIDATES:
        if c in names:
            try:
                show(c, zf.read(c))
            except Exception as e:
                print(f"   {c} 读取失败 {e}")
        else:
            # 尝试模糊匹配
            base = os.path.basename(c)
            hits = [n for n in names if n.endswith("/" + base) or n == base]
            for h in hits[:3]:
                try:
                    show(h, zf.read(h))
                except Exception:
                    pass

    # 3) mod_launcher 结构
    print("\n== mod_launcher 结构 ==")
    ml = [n for n in names if n.startswith("assets/mod_launcher/")]
    depth = collections.Counter("/".join(n.split("/")[:4]) for n in ml)
    for k, v in depth.most_common(25):
        print(f"   {v:>5}  {k}")

    # 4) Lua 加密特征统计
    print("\n== Lua 头部特征 ==")
    lua = [n for n in names if n.lower().endswith(".lua")]
    sig_count = collections.Counter()
    samples = []
    for n in lua:
        try:
            head = zf.read(n)[:16]
        except Exception:
            continue
        kind = classify_lua(head)
        sig_count[kind] += 1
        if len(samples) < 6:
            samples.append((n, head))
    for k, v in sig_count.most_common():
        print(f"   {v:>5}  {k}")
    print("   样本头部：")
    for n, head in samples:
        print(f"     {head.hex(' ')}  {n}")

    # 5) 在 .so 里找解密/授权线索
    print("\n== 原生库字符串线索 ==")
    needles = [b"luaL_loadbuffer", b"xxtea", b"XXTEA", b"aes_decrypt", b"AES_decrypt",
               b"decrypt", b"Decrypt", b"licen", b"Licen", b"auth", b"Auth",
               b"996", b"box996", b"dhsf", b"xqhuyu", b"verify", b"Verify"]
    for n in sorted(libs):
        try:
            data = zf.read(n)
        except Exception:
            continue
        found = []
        for nd in needles:
            if nd in data:
                found.append(nd.decode("latin-1"))
        if found:
            print(f"   {n}: {', '.join(sorted(set(found)))}")

    # 6) 可选：dump 若干 lua 头部字节
    if dump_n:
        print(f"\n== dump 前 {dump_n} 个 lua 的前 64 字节 ==")
        for n in lua[:dump_n]:
            data = zf.read(n)
            print(f"--- {n} ({len(data)} bytes) ---")
            print(data[:64].hex(" "))

    return 0


if __name__ == "__main__":
    sys.exit(main())
