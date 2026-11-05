/*
 * frida-996-redirect-list.js
 *
 * 目的：把客户端对 996 配置域名的解析改到本机，从而接管 modlist / serverlist。
 *
 * 原理：hook libc 的 getaddrinfo，把 list-new.dhsf.xqhuyu.com 等域名替换成 127.0.0.1。
 *       配合主机侧 `adb reverse tcp:80 tcp:8888` + local-996-server.py，
 *       客户端就会从本地拿到改过的 modlist 和明文 serverlist。
 *
 * 用法：
 *   python run-frida-996.py --attach --script frida-996-redirect-list.js --seconds 180
 */

'use strict';

const TAG = '[996-dns]';

const TARGETS = [
    'list-new.dhsf.xqhuyu.com',
    'list-standby.dhsf.vkcgd.cn',
    'list-new.dhsf.huiyuehz.com',
];

const REPLACE_WITH = '127.0.0.1';

function hookGetaddrinfo() {
    const addr = Module.findGlobalExportByName
        ? (function () { try { return Module.getGlobalExportByName('getaddrinfo'); } catch (e) { return null; } })()
        : null;
    const target = addr || (function () {
        try { return Module.getExportByName('libc.so', 'getaddrinfo'); } catch (e) { return null; }
    })();
    if (!target) { console.log(`${TAG} 找不到 getaddrinfo`); return false; }

    Interceptor.attach(target, {
        onEnter(args) {
            try {
                if (args[0].isNull()) return;
                const name = args[0].readCString();
                if (!name) return;
                for (const t of TARGETS) {
                    if (name === t) {
                        const repl = Memory.allocUtf8String(REPLACE_WITH);
                        args[0] = repl;
                        console.log(`${TAG} ★ 劫持 ${name} → ${REPLACE_WITH}`);
                        return;
                    }
                }
            } catch (e) { }
        },
        onLeave(retval) {
            // 只记录一眼，不改变返回值
        }
    });
    console.log(`${TAG} [hook] getaddrinfo @ ${target}`);
    return true;
}

function hookConnect() {
    let target = null;
    try { target = Module.getGlobalExportByName('connect'); } catch (e) { }
    if (!target) {
        try { target = Module.getExportByName('libc.so', 'connect'); } catch (e) { }
    }
    if (!target) { console.log(`${TAG} 找不到 connect`); return false; }
    Interceptor.attach(target, {
        onEnter(args) {
            try {
                const sa = args[1];
                const family = sa.readU16();
                if (family === 2) {
                    const port = (sa.add(2).readU8() << 8) | sa.add(3).readU8();
                    const ip = [0, 1, 2, 3].map(i => sa.add(4 + i).readU8()).join('.');
                    console.log(`${TAG} connect → ${ip}:${port}`);
                }
            } catch (e) { }
        }
    });
    console.log(`${TAG} [hook] connect @ ${target}`);
    return true;
}

setImmediate(() => {
    console.log(`${TAG} ===== 安装 DNS 重定向 =====`);
    hookGetaddrinfo();
    hookConnect();
    console.log(`${TAG} 完成。现在重启 996 客户端，它拉 modlist 时会打到本机。`);
});
