#!/usr/bin/env python3
"""在 APK 的原生库里追踪 996 的 Lua / 配置加密实现线索。

关注点：
  1. 资源魔数（lua 头部 "XdvFTgd5YA"、serverlist 头部 "4meJnPyl"）在哪个 .so 出现
  2. 解密相关符号与相邻字符串
  3. 疑似 16 字节 key 常量

用法:
    python so-hunt.py <apk> [--lib lib/arm64-v8a/libMyGame.so] [--magic XdvFTgd5YA]
"""
import sys
import zipfile
import re
import collections
import struct

sys.stdout.reconfigure(encoding="utf-8")


def extract_strings(data: bytes, min_len: int = 6):
    """提取连续可打印 ASCII 串及其偏移。"""
    out = []
    cur = bytearray()
    start = 0
    for i, b in enumerate(data):
        if 32 <= b < 127:
            if not cur:
                start = i
            cur.append(b)
        else:
            if len(cur) >= min_len:
                out.append((start, cur.decode("latin-1")))
            cur = bytearray()
    if len(cur) >= min_len:
        out.append((start, cur.decode("latin-1")))
    return out


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    apk = sys.argv[1]
    libs = ["lib/arm64-v8a/libMyGame.so"]
    if "--lib" in sys.argv:
        libs = sys.argv[sys.argv.index("--lib") + 1].split(",")

    magics = [b"XdvFTgd5YA", b"4meJnPyl"]
    if "--magic" in sys.argv:
        magics = [sys.argv[sys.argv.index("--magic") + 1].encode()]

    zf = zipfile.ZipFile(apk)

    for lib in libs:
        try:
            data = zf.read(lib)
        except KeyError:
            print(f"缺少 {lib}")
            continue
        print(f"\n===== {lib}  ({len(data):,} bytes) =====")

        # 1) 魔数出现
        print("-- 资源魔数命中 --")
        for m in magics:
            positions = []
            idx = 0
            while True:
                idx = data.find(m, idx)
                if idx < 0:
                    break
                positions.append(idx)
                idx += 1
                if len(positions) > 8:
                    break
            if positions:
                print(f"   {m.decode()} 出现在 {len(positions)} 处: {[hex(p) for p in positions[:8]]}")
            else:
                print(f"   {m.decode()} 未出现")

        # 2) 解密相关字符串及其上下文
        strings = extract_strings(data, 5)
        print(f"-- 字符串总数 {len(strings)} --")
        interest = re.compile(
            r"(?i)(xxtea|tea|aes|decrypt|encrypt|luaL_loadbuffer|lua_load|"
            r"signkey|envkey|game_signkey|keylen|modlist|serverlist|xk)"
        )
        hits = [(o, s) for o, s in strings if interest.search(s)]
        print(f"-- 加解密相关 {len(hits)} 条（前 40） --")
        for off, s in hits[:40]:
            print(f"   0x{off:08x}  {s[:120]}")

        # 3) 16 字节高熵常量扫描（疑似 key）
        print("-- 疑似 16 字节 key 常量（.rodata 中，前 12 个） --")
        # 粗略：找连续 16 字节、其中至少 12 个是可打印或全部非零且分布广
        cand = []
        for off in range(0, len(data) - 16, 16):
            chunk = data[off:off + 16]
            if chunk.count(0) > 1:
                continue
            if len(set(chunk)) < 10:
                continue
            printable = sum(1 for b in chunk if 32 <= b < 127)
            if printable == 16 and not chunk.isalnum():
                cand.append((off, chunk))
            if len(cand) >= 12:
                break
        for off, chunk in cand:
            txt = "".join(chr(b) for b in chunk)
            print(f"   0x{off:08x}  {chunk.hex(' ')}  |{txt}|")

    return 0


if __name__ == "__main__":
    sys.exit(main())
