#!/usr/bin/env python3
"""Spawn or attach the 996 Android client with a Frida script and log messages."""
import argparse
import json
import sys
import time

import frida

sys.stdout.reconfigure(encoding="utf-8", errors="replace")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--package", default="com.fgcq.a143097")
    ap.add_argument("--script", required=True)
    ap.add_argument("--seconds", type=int, default=180)
    ap.add_argument("--attach", action="store_true")
    ap.add_argument("--pid", type=int, default=0, help="attach to this pid directly")
    ap.add_argument("--out", default="frida-996.log")
    args = ap.parse_args()

    with open(args.script, "r", encoding="utf-8") as fh:
        source = fh.read()

    device = frida.get_usb_device(timeout=15)
    print("[frida] device = %s" % device, flush=True)

    if args.pid:
        args.attach = True          # explicit pid means attach, never spawn/resume
        pid = args.pid
        print("[frida] attach pid=%s (explicit)" % pid, flush=True)
        session = device.attach(pid)
    elif args.attach:
        pid = None
        for app in device.enumerate_applications():
            if app.identifier == args.package and app.pid:
                pid = app.pid
                break
        if not pid:
            raise SystemExit("[frida] process not running: %s" % args.package)
        print("[frida] attach pid=%s" % pid, flush=True)
        session = device.attach(pid)
    else:
        pid = device.spawn([args.package])
        print("[frida] spawn pid=%s" % pid, flush=True)
        session = device.attach(pid)

    lines = []

    def on_message(message, data):
        if message.get("type") == "send":
            text = message.get("payload")
        elif message.get("type") == "error":
            text = "ERROR: " + str(message.get("stack") or message.get("description"))
        else:
            text = json.dumps(message, ensure_ascii=False)
        text = str(text)
        lines.append(text)
        print(text, flush=True)

    script = session.create_script(source)
    script.on("message", on_message)
    script.load()
    print("[frida] script loaded", flush=True)

    if not args.attach:
        device.resume(pid)
        print("[frida] resumed", flush=True)

    print("[frida] collecting %ss ..." % args.seconds, flush=True)
    t0 = time.time()
    while time.time() - t0 < args.seconds:
        time.sleep(1)

    with open(args.out, "w", encoding="utf-8") as fh:
        fh.write("\n".join(lines))
    print("[frida] wrote %s (%d lines)" % (args.out, len(lines)), flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
