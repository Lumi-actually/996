#!/usr/bin/env python3
"""列出 zip/rar/apk 包内的条目，用于确认 996 引擎包结构。

用法:
    python list-archive.py <archive> [--limit 40] [--roots]
"""
import sys
import zipfile
import os
import collections

sys.stdout.reconfigure(encoding="utf-8")


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    path = sys.argv[1]
    limit = 40
    if "--limit" in sys.argv:
        limit = int(sys.argv[sys.argv.index("--limit") + 1])

    if not os.path.exists(path):
        print(f"not found: {path}")
        return 1

    size_mb = os.path.getsize(path) / 1024 / 1024
    print(f"== {os.path.basename(path)}  ({size_mb:.1f} MB) ==")

    try:
        zf = zipfile.ZipFile(path)
    except zipfile.BadZipFile:
        print("不是 zip 容器（apk 是 zip，rar 不是）")
        return 1

    items = zf.infolist()
    total_unpacked = sum(i.file_size for i in items)
    print(f"条目 {len(items)}，解压后 {total_unpacked/1024/1024:.1f} MB")

    roots = collections.Counter(i.filename.split("/")[0] for i in items)
    print("  顶层分布：")
    for name, count in roots.most_common(15):
        print(f"    {name:<45} {count}")

    exts = collections.Counter(os.path.splitext(i.filename)[1].lower() for i in items if i.file_size > 0)
    print("  扩展名分布：")
    for ext, count in exts.most_common(15):
        print(f"    {ext or '(none)':<12} {count}")

    print(f"  前 {limit} 条：")
    for info in items[:limit]:
        print(f"    {info.file_size:>12,}  {info.filename}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
