#!/usr/bin/env python3
"""Transparent HTTP proxy on 127.0.0.1:8888 -> official 996 modlist/srvlist hosts.

The repacked client asks http://10.0.2.2:8888/<path>?type=..&time=..&sign=..
We forward the path+query verbatim to the real upstream host, follow redirects,
and return the ORIGINAL bytes. The client then validates a genuine official
response instead of anything we forged.
"""
import http.server
import socketserver
import sys
import time
import urllib.error
import urllib.request

PORT = 8888
UPSTREAMS = [
    "http://list-new.dhsf.xqhuyu.com",
    "http://list-standby.dhsf.vkcgd.cn",
    "http://list-new.dhsf.huiyuehz.com",
]
LOG = r"D:\project\新建文件夹\mingyang-mobile\working\996-local\docs\proxy.log"

sys.stdout.reconfigure(encoding="utf-8", errors="replace")


def log(msg: str) -> None:
    line = "[%s] %s" % (time.strftime("%H:%M:%S"), msg)
    print(line, flush=True)
    try:
        with open(LOG, "a", encoding="utf-8") as fh:
            fh.write(line + "\n")
    except Exception:
        pass


class Handler(http.server.BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def log_message(self, fmt, *args):  # silence default stderr spam
        pass

    def _proxy(self, method: str) -> None:
        path = self.path
        body = None
        if "Content-Length" in self.headers:
            n = int(self.headers.get("Content-Length") or 0)
            if n:
                body = self.rfile.read(n)

        last_err = None
        for base in UPSTREAMS:
            url = base + path
            try:
                req = urllib.request.Request(url, data=body, method=method)
                # let urllib own the Host header, otherwise it will not follow
                # the upstream 302 -> mirror-JSON hop
                for h in ("User-Agent", "Accept", "Content-Type", "Accept-Encoding"):
                    if self.headers.get(h):
                        req.add_header(h, self.headers.get(h))

                with urllib.request.urlopen(req, timeout=25) as resp:
                    data = resp.read()
                    ctype = resp.headers.get("Content-Type", "application/octet-stream")
                    log("%s %s -> %s %d bytes via %s" % (method, path, resp.status, len(data), base))
                    self.send_response(resp.status)
                    self.send_header("Content-Type", ctype)
                    self.send_header("Content-Length", str(len(data)))
                    self.send_header("Connection", "close")
                    self.end_headers()
                    self.wfile.write(data)
                    return
            except urllib.error.HTTPError as e:
                data = e.read() or b""
                log("%s %s -> HTTP %d (%d bytes) via %s" % (method, path, e.code, len(data), base))
                if e.code in (301, 302, 303, 307, 308):
                    loc = e.headers.get("Location")
                    if loc:
                        try:
                            with urllib.request.urlopen(loc, timeout=20) as r2:
                                d2 = r2.read()
                            log("  followed -> %s %d bytes" % (loc, len(d2)))
                            self.send_response(200)
                            self.send_header("Content-Type", r2.headers.get("Content-Type", "application/octet-stream"))
                            self.send_header("Content-Length", str(len(d2)))
                            self.send_header("Connection", "close")
                            self.end_headers()
                            self.wfile.write(d2)
                            return
                        except Exception as e2:
                            last_err = "redirect follow failed: %s" % e2
                            continue
                self.send_response(e.code)
                self.send_header("Content-Length", str(len(data)))
                self.send_header("Connection", "close")
                self.end_headers()
                if data:
                    self.wfile.write(data)
                return
            except Exception as e:
                last_err = "%s: %s" % (base, e)
                continue

        log("ALL UPSTREAMS FAILED for %s (%s)" % (path, last_err))
        msg = b"upstream failed"
        self.send_response(502)
        self.send_header("Content-Length", str(len(msg)))
        self.send_header("Connection", "close")
        self.end_headers()
        self.wfile.write(msg)

    def do_GET(self):
        self._proxy("GET")

    def do_POST(self):
        self._proxy("POST")


class Server(socketserver.ThreadingTCPServer):
    allow_reuse_address = True
    daemon_threads = True


if __name__ == "__main__":
    log("proxy listening on 0.0.0.0:%d" % PORT)
    with Server(("0.0.0.0", PORT), Handler) as srv:
        srv.serve_forever()
