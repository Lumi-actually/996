#!/usr/bin/env python3
"""Run a Frida script against a *gadget* listener (no root, no frida-server).

The repackaged client (libgadget.so) listens on 0.0.0.0:27042 inside the device.
Connect either over USB with `adb forward tcp:27042 tcp:27042`, or over Wi-Fi with
the phone's LAN IP.

Usage:
  python frida-gadget-run.py --script hook.js --seconds 300 [--host 127.0.0.1:27042]
  python frida-gadget-run.py --script hook.js --seconds 300 --host 192.168.10.55:27042
"""
import argparse
import codecs
import os
import sys
import time

import frida


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--host", default="127.0.0.1:27042", help="gadget endpoint host:port")
    ap.add_argument("--script", required=True, help="path to the Frida JS payload")
    ap.add_argument("--seconds", type=int, default=300)
    ap.add_argument("--out", default=None, help="log file (UTF-8)")
    ap.add_argument("--script2", default=None, help="second script loaded after resume")
    ap.add_argument("--script2-after", type=int, default=15, help="seconds to wait before loading script2")
    ap.add_argument("--runtime", default="v8", choices=["v8", "qjs"], help="script runtime requested from gadget")
    args = ap.parse_args()

    out_path = args.out or (os.path.splitext(os.path.basename(args.script))[0] + ".gadget.log")
    logf = open(out_path, "w", encoding="utf-8", errors="replace")

    def emit(line: str) -> None:
        print(line, flush=True)
        logf.write(line + "\n")
        logf.flush()

    emit("[gadget] connecting to %s" % args.host)
    try:
        device = frida.get_device_manager().add_remote_device(args.host)
        session = device.attach("Gadget")
    except Exception as exc:  # noqa: BLE001
        emit("[gadget] attach failed: %s" % exc)
        logf.close()
        return 1

    with open(args.script, "r", encoding="utf-8") as fh:
        source = fh.read()

    script = session.create_script(source, runtime=args.runtime)

    def on_message(message, data):
        if message.get("type") == "send":
            emit(str(message.get("payload")))
        elif message.get("type") == "error":
            emit("[gadget] ERROR: " + str(message.get("stack") or message.get("description")))

    script.on("message", on_message)
    script.load()
    emit("[gadget] script loaded")

    # Gadget with on_load:"wait" parks the process at Application.onCreate until
    # the client resumes it. Frida exposes that in different places depending on
    # version, so try each known entry point and report which one worked.
    resumed = "auto"
    for attempt in ("device.resume(pid)", "session.resume()", "device.resume(0)"):
        try:
            if attempt == "device.resume(pid)":
                device.resume(0)
            elif attempt == "session.resume()":
                session.resume()
            else:
                device.resume(0)
            resumed = attempt
            break
        except Exception as exc:  # noqa: BLE001
            emit("[gadget] resume via %s not available: %s" % (attempt, exc))
    emit("[gadget] resume path: %s" % resumed)

    if args.script2:
        emit("[gadget] waiting %ds before loading %s" % (args.script2_after, args.script2))
        time.sleep(args.script2_after)
        try:
            with open(args.script2, "r", encoding="utf-8") as fh2:
                src2 = fh2.read()
            s2 = session.create_script(src2, runtime=args.runtime)
            s2.on("message", on_message)
            s2.load()
            emit("[gadget] second script loaded")
        except Exception as exc:  # noqa: BLE001
            emit("[gadget] second script failed: %s" % exc)

    emit("[gadget] collecting %ds ..." % args.seconds)

    deadline = time.time() + args.seconds
    try:
        while time.time() < deadline:
            time.sleep(5)
    except KeyboardInterrupt:
        emit("[gadget] interrupted")
    finally:
        try:
            session.detach()
        except Exception:  # noqa: BLE001
            pass
        logf.close()
        emit("[gadget] wrote %s" % out_path)
    return 0


if __name__ == "__main__":
    sys.exit(main())
