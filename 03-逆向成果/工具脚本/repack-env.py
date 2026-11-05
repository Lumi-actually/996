#!/usr/bin/env python3
"""把 996 客户端的 modlist 地址改成局域网本地服务，产出可重签名的 APK。

只改 assets 里的两个明文 JSON（env.json / sdk_info.txt），不动 dex 和 so。

用法:
    python repack-env.py --apk <原apk> --out <新apk> --modlist-base http://10.0.2.2:8888
"""
import argparse
import json
import os
import sys
import zipfile

sys.stdout.reconfigure(encoding="utf-8")

ENV = "assets/env.json"
SDKINFO = "assets/sdk_info.txt"

# 这些 key 指向配置清单服务
MODLIST_KEYS = ("modlist", "modlistPlanB")


def rewrite_json(raw: bytes, base: str) -> bytes:
    text = raw.decode("utf-8-sig")
    data = json.loads(text)
    changed = []
    for k in MODLIST_KEYS:
        if k in data:
            data[k] = f"{base}/modlist/modlist_143097.txt"
            changed.append(k)
    print(f"    {k} 改写字段: {changed}" if changed else "    未找到 modlist 字段")
    out = json.dumps(data, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
    return out


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--apk", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--modlist-base", required=True, help="如 http://10.0.2.2:8888")
    args = ap.parse_args()

    if os.path.exists(args.out):
        os.remove(args.out)

    zin = zipfile.ZipFile(args.apk, "r")
    total = len(zin.infolist())
    print(f"源 APK: {total} 条目")

    with zipfile.ZipFile(args.out, "w", zipfile.ZIP_DEFLATED) as zout:
        for i, item in enumerate(zin.infolist()):
            data = zin.read(item.filename)
            if item.filename == ENV:
                print(f"  [{i}] 改写 {ENV} ({len(data)} → ", end="")
                data = rewrite_json(data, args.modlist_base)
                print(f"{len(data)})")
            elif item.filename == SDKINFO:
                print(f"  [{i}] 改写 {SDKINFO} ({len(data)} → ", end="")
                data = rewrite_json(data, args.modlist_base)
                print(f"{len(data)})")
            # 保留原始压缩方式与时间戳；.so/.arsc 必须 STORED 或对齐
            zi = zipfile.ZipInfo(item.filename, date_time=item.date_time)
            zi.compress_type = item.compress_type
            zi.external_attr = item.external_attr
            zi.internal_attr = item.internal_attr
            zi.create_system = item.create_system
            zout.writestr(zi, data)
            if i % 2000 == 0:
                print(f"    …{i}/{total}")
    zin.close()

    size = os.path.getsize(args.out)
    print(f"输出: {args.out}  {size:,} 字节 ({size/1024/1024:.1f} MB)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
