#!/usr/bin/env python3
"""本地 996 配置服务：接管 modlist 与 serverlist，把客户端指向局域网服务端。

关键设计（踩坑记录）：
  * 必须做**文本级**替换，不能用 json.loads/dumps 重新序列化。
    官方 modlist 用 \\uXXXX 转义，重排后 2281 → 2059 字节，客户端会认为内容不合法直接丢弃。
  * runtime 改成当前时间戳，避免客户端做时效校验。
  * isEncrypt 从 1 改成 0，让客户端按明文解析 serverlist，绕开 XXTEA。
  * 响应加 Connection: close，原生 HTTP 客户端不认 keep-alive 时会挂住。

用法:
    python local-996-srv.py --host 0.0.0.0 --port 8888 --game-host 10.0.2.2 --game-port 7000
"""
import argparse
import gzip
import os
import re
import sys
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

sys.stdout.reconfigure(encoding="utf-8")

HERE = os.path.dirname(os.path.abspath(__file__))
DATA = os.path.join(os.path.dirname(HERE), "data")          # working/996-local/data
ACCESS_LOG = os.path.join(os.path.dirname(HERE), "docs", "access.log")

ARGS = None


def build_modlist(base_url: str) -> str:
    path = os.path.join(DATA, "modlist_143097.official.json")
    with open(path, "r", encoding="utf-8") as fh:
        raw = fh.read()
    if os.environ.get("PASSTHROUGH") == "1":
        return raw          # 原样返回，验证客户端是否接受"未改动"的官方内容

    # 官方 JSON 里的斜杠是 \/ 转义形式，必须照样匹配，否则替换落空
    def esc(s: str) -> str:
        return s.replace("/", "\\/")

    for host in ("list-new.dhsf.xqhuyu.com", "list-standby.dhsf.vkcgd.cn"):
        raw = raw.replace(esc(f"http://{host}/modlist/modlist_143097.txt"),
                          esc(f"{base_url}/modlist/modlist_143097.txt"))
        raw = raw.replace(esc(f"http://{host}/serverlist/143097/serverlist.txt"),
                          esc(f"{base_url}/serverlist/143097/serverlist.txt"))
    raw = raw.replace('"isEncrypt":1', '"isEncrypt":0')
    raw = re.sub(r'"runtime":\d+', f'"runtime":{int(time.time())}', raw)
    return raw


def build_serverlist(game_host: str, game_port: int) -> str:
    path = os.path.join(DATA, "serverlist.official.json")
    with open(path, "r", encoding="utf-8") as fh:
        raw = fh.read()

    raw = re.sub(r'"i":"[^"]*"', f'"i":"{game_host}"', raw)
    raw = re.sub(r'"p":\d+', f'"p":{game_port}"', raw)
    raw = re.sub(r'"runtime":\d+', f'"runtime":{int(time.time())}', raw)
    return raw


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def log_message(self, fmt, *args):
        line = "[http] %s - %s" % (self.address_string(), fmt % args)
        try:
            with open(ACCESS_LOG, "a", encoding="utf-8") as fh:
                fh.write(line + "\n")
                fh.flush()
        except Exception:
            pass
        try:
            sys.stdout.write(line + "\n")
            sys.stdout.flush()
        except Exception:
            pass

    def _send(self, code, body: str, ctype="application/json; charset=utf-8"):
        raw = body.encode("utf-8")
        # 原生 HTTP 封装常常无条件 gunzip，所以统一压缩返回
        accept = (self.headers.get("Accept-Encoding") or "")
        use_gzip = ARGS.gzip_always or ("gzip" in accept.lower())
        if use_gzip and raw:
            raw = gzip.compress(raw)
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        if use_gzip and body:
            self.send_header("Content-Encoding", "gzip")
        self.send_header("Content-Length", str(len(raw)))
        self.send_header("Connection", "close")
        self.end_headers()
        if raw:
            self.wfile.write(raw)
        try:
            self.wfile.flush()
        except Exception:
            pass
        self.close_connection = True

    def do_HEAD(self):
        self._send(200, "")

    def do_GET(self):
        path = self.path.split("?")[0]
        base = f"http://{ARGS.public_host}" if ARGS.public_host else f"http://{self.headers.get('Host', 'localhost')}"

        if path.endswith("modlist_143097.txt"):
            body = build_modlist(base)
            self.log_message("→ modlist %d 字节, srvlist=%s/serverlist/143097/serverlist.txt", len(body), base)
            return self._send(200, body)

        if path.endswith("serverlist.txt"):
            body = build_serverlist(ARGS.game_host, ARGS.game_port)
            self.log_message("→ serverlist %d 字节, game=%s:%s", len(body), ARGS.game_host, ARGS.game_port)
            return self._send(200, body)

        if path == "/health":
            return self._send(200, '{"ok":true}')

        self.log_message("404 %s", path)
        return self._send(404, '{"code":404}')


def main():
    global ARGS
    ap = argparse.ArgumentParser()
    ap.add_argument("--host", default="0.0.0.0")
    ap.add_argument("--port", type=int, default=8888)
    ap.add_argument("--game-host", required=True)
    ap.add_argument("--game-port", type=int, default=7000)
    ap.add_argument("--public-host", default=None)
    ap.add_argument("--gzip-always", action="store_true")
    ARGS = ap.parse_args()

    srv = ThreadingHTTPServer((ARGS.host, ARGS.port), Handler)
    print(f"[http] 监听 {ARGS.host}:{ARGS.port}  game={ARGS.game_host}:{ARGS.game_port}", flush=True)
    print(f"[http] access log → {ACCESS_LOG}", flush=True)
    try:
        srv.serve_forever()
    except KeyboardInterrupt:
        print("\n[http] 退出", flush=True)


if __name__ == "__main__":
    sys.exit(main())
