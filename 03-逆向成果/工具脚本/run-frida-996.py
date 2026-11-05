#!/usr/bin/env python3
"""驱动 frida 对 996 安卓客户端做 spawn + hook，收集 key/sign 与 Lua 明文。

用法:
    python run-frida-996.py --package com.fgcq.a143097 --script frida-996-dump-key.js --seconds 90
    python run-frida-996.py --package com.fgcq.a143097 --attach      # 已在运行的进程
"""
import sys
import time
import json
import argparse
import codecs

sys.stdout.reconfigure(encoding="utf-8")
import frida  # noqa: E402


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--package", default="com.fgcq.a143097")
    ap.add_argument("--script", required=True)
    ap.add_argument("--seconds", type=int, default=90)
    ap.add_argument("--attach", action="store_true")
    ap.add_argument("--out", default="frida-996.log")
    args = ap.parse_args()

    with open(args.script, "r", encoding="utf-8") as fh:
        source = fh.read()

    device = frida.get_usb_device(timeout=10)
    print(f"[frida] device = {device}")

    if args.attach:
        pid = None
        for app in device.enumerate_applications():
            if app.identifier == args.package and app.pid:
                pid = app.pid
                break
        if not pid:
            raise SystemExit(f"[frida] 进程未运行或不可见: {args.package}（先 am start 再 attach）")
        print(f"[frida] attach pid={pid}")
        session = device.attach(pid)
    else:
        pid = device.spawn([args.package])
        print(f"[frida] spawn pid={pid}")
        session = device.attach(pid)

    lines = []
    def on_message(message, data):
        if message.get("type") == "send":
            text = message.get("payload")
        elif message.get("type") == "error":
            text = "ERROR: " + str(message.get("stack") or message.get("description"))
        else:
            text = json.dumps(message, ensure_ascii=False)
        lines.append(str(text))
        print(text)

    script = session.create_script(source)
    script.on("message", on_message)
    script.load()
    print("[frida] script loaded")

    if not args.attach:
        device.resume(pid)
        print("[frida] resumed")

    print(f"[frida] 采集 {args.seconds}s …")
    t0 = time.time()
    while time.time() - t0 < args.seconds:
        time.sleep(1)

    with open(args.out, "w", encoding="utf-8") as fh:
        fh.write("\n".join(lines))
    print(f"[frida] 日志已写 {args.out}（{len(lines)} 条）")
    return 0


if __name__ == "__main__":
    sys.exit(main())
