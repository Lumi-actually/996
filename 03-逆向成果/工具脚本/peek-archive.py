#!/usr/bin/env python3
"""直接从 zip 里读取指定文件内容，不解压到磁盘。

用法:
    python peek-archive.py <zip> --list            # 只列路径
    python peek-archive.py <zip> --grep 授权        # 在文本成员里搜关键词
    python peek-archive.py <zip> --show "path.pem"  # 打印某个成员
    python peek-archive.py <zip> --show "*.ini"     # 按后缀通配打印
"""
import sys
import zipfile
import fnmatch

sys.stdout.reconfigure(encoding="utf-8")


def decode(data: bytes) -> str:
    for enc in ("utf-8-sig", "gbk", "utf-16"):
        try:
            text = data.decode(enc)
            if text.count("\ufffd") < len(text) * 0.02:
                return f"[{enc}] " + text
        except Exception:
            continue
    return "[binary] " + data[:400].hex(" ")


def main() -> int:
    if len(sys.argv) < 3:
        print(__doc__)
        return 2
    path = sys.argv[1]
    zf = zipfile.ZipFile(path)
    names = zf.namelist()

    if "--list" in sys.argv:
        for n in names:
            info = zf.getinfo(n)
            print(f"{info.file_size:>12,}  {n}")
        return 0

    if "--grep" in sys.argv:
        kw = sys.argv[sys.argv.index("--grep") + 1]
        limit = 8
        shown = 0
        for n in names:
            if shown >= limit:
                break
            low = n.lower()
            if not any(low.endswith(e) for e in (".txt", ".ini", ".json", ".lua", ".pem", ".cfg", ".xml", ".manifest")):
                continue
            try:
                raw = zf.read(n)
            except Exception:
                continue
            for enc in ("utf-8", "gbk"):
                try:
                    text = raw.decode(enc)
                except Exception:
                    continue
                if kw in text:
                    idx = text.find(kw)
                    line = text.count("\n", 0, idx) + 1
                    snippet = text[max(0, idx - 120): idx + 160].replace("\r", "").replace("\n", " ⏎ ")
                    print(f"--- {n}:{line} ({enc}) ---")
                    print(f"    …{snippet}…")
                    shown += 1
                    break
        if shown == 0:
            print(f"未命中：{kw}")
        return 0

    if "--show" in sys.argv:
        pat = sys.argv[sys.argv.index("--show") + 1]
        matched = [n for n in names if fnmatch.fnmatch(n, pat) or n.endswith(pat.lstrip("*"))]
        if not matched:
            print(f"没有匹配 {pat} 的成员")
            return 1
        for n in matched[:12]:
            info = zf.getinfo(n)
            print(f"\n===== {n}  ({info.file_size:,} bytes) =====")
            print(decode(zf.read(n))[:3000])
        return 0

    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main())
