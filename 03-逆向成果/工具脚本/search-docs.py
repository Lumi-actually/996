#!/usr/bin/env python3
"""在反编译出来的 CHM 文档（GBK/UTF-8 混合 HTML）里按关键词检索。

用法:
    python search-docs.py <dir> --kw 授权,手机端,serverlist --limit 30
"""
import sys
import os
import re
import argparse

sys.stdout.reconfigure(encoding="utf-8")


def read_text(path: str) -> str:
    with open(path, "rb") as fh:
        raw = fh.read()
    for enc in ("utf-8-sig", "gbk", "utf-16", "latin-1"):
        try:
            t = raw.decode(enc)
        except Exception:
            continue
        if t.count("\ufffd") < len(t) * 0.02:
            return t
    return raw.decode("latin-1", "ignore")


def strip_tags(html: str) -> str:
    html = re.sub(r"(?is)<(script|style).*?</\1>", " ", html)
    html = re.sub(r"(?s)<[^>]+>", " ", html)
    html = html.replace("&nbsp;", " ").replace("&lt;", "<").replace("&gt;", ">").replace("&amp;", "&")
    return re.sub(r"[ \t\r\f\v]+", " ", html)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("dir")
    ap.add_argument("--kw", required=True)
    ap.add_argument("--limit", type=int, default=30)
    ap.add_argument("--ctx", type=int, default=160)
    args = ap.parse_args()

    kws = [k.strip() for k in args.kw.split(",") if k.strip()]
    hits = 0
    scanned = 0
    for root, _dirs, files in os.walk(args.dir):
        for fn in files:
            if not fn.lower().endswith((".htm", ".html", ".txt", ".hhc")):
                continue
            path = os.path.join(root, fn)
            rel = os.path.relpath(path, args.dir)
            try:
                text = strip_tags(read_text(path))
            except Exception:
                continue
            scanned += 1
            for kw in kws:
                if kw not in text:
                    continue
                idx = text.find(kw)
                snippet = text[max(0, idx - args.ctx): idx + args.ctx].strip()
                snippet = re.sub(r"\s+", " ", snippet)
                print(f"--- {rel}  [{kw}]")
                print(f"    …{snippet}…")
                hits += 1
                break
            if hits >= args.limit:
                print(f"\n达到上限 {args.limit}，已扫 {scanned} 个文件")
                return 0
    print(f"\n扫描 {scanned} 个文件，命中 {hits} 处")
    return 0


if __name__ == "__main__":
    sys.exit(main())
