/*
 * frida-996-dump-key.js  (Frida 17 兼容版)
 *
 * 抓 Cocos2d-x 的 XXTEA key / sign，dump 解密后的 Lua，记录 connect 目标。
 *
 * 依据（libMyGame.so 符号表实测）：
 *   cocos2d::FileUtils::addXXTEAKeyAndSign(std::string, std::string)
 *   cocos2d::FileUtils::addXXTEAKeyAndSignV2/V3/V4
 *   LuaBridgeCtl::initXXTeaAndLookups()
 *   LuaBridgeCtl::SetXXTEAKeyGM(std::string)
 *   cocos2dx_lua_loader / luaL_loadbuffer
 *
 * Frida 17 注意：Module.findBaseAddress / Module.findExportByName 静态方法已移除，
 *                改用 Process.findModuleByName(...).findExportByName(...)。
 */

'use strict';

const LIB = 'libMyGame.so';
const TAG = '[996]';
const SIGNS = ['XdvFTgd5YA', '4meJnPyl'];

/* ---------- Frida 17 兼容的模块/导出查找 ---------- */
function mod(name) {
    try { return Process.findModuleByName(name); } catch (e) { return null; }
}
function exportOf(lib, name) {
    const m = mod(lib);
    if (!m) return null;
    try { return m.findExportByName(name); } catch (e) { return null; }
}
function globalExport(name) {
    try { return Module.getGlobalExportByName(name); } catch (e) { }
    try { return Process.getModuleByName(null).findExportByName(name); } catch (e) { }
    return null;
}

/* ---------- libc++ std::string 读取 ---------- */
function readStdString(addr) {
    if (!addr || addr.isNull()) return '<null>';
    try {
        const p = ptr(addr);
        const flag = p.readU8();
        if ((flag & 0x01) === 0x01) {           // long: cap(8) size(8) ptr(8)
            const size = p.add(8).readU64().toNumber();
            const data = p.add(16).readPointer();
            if (!size || size > 65535) return '<long? size=' + size + '>';
            return data.readUtf8String(Math.min(size, 65535));
        }
        const size = p.add(1).readU8();          // short: size(1) buf(22)
        return p.add(1).readUtf8String(Math.min(size, 22));
    } catch (e) {
        return '<err ' + e.message + '>';
    }
}

/* ---------- 内存搜索 sign ---------- */
function scanSigns() {
    for (const s of SIGNS) {
        const pat = s + '\x00';
        try {
            Memory.scanSync(Process.enumerateRanges('r--')[0] ? Process.getRangeByAddress(ptr(0)) : ptr(0), 0, pat);
        } catch (e) { /* 忽略粗扫失败 */ }
    }
    let total = 0;
    for (const r of Process.enumerateRanges('r--')) {
        for (const s of SIGNS) {
            try {
                const hits = Memory.scanSync(r.base, r.size, s);
                for (const h of hits.slice(0, 4)) {
                    total++;
                    console.log(`${TAG} ★ 内存中找到 sign "${s}" @ ${h.address}  (range ${r.base}-${r.base.add(r.size)})`);
                    try {
                        const around = h.address.sub(64).readByteArray(256);
                        console.log(hexdump(around, { offset: 0, length: 256, ansi: false }));
                    } catch (e) { }
                }
            } catch (e) { }
        }
    }
    console.log(`${TAG} 内存扫描完成，命中 ${total} 处`);
}

/* ---------- 主逻辑 ---------- */
setImmediate(() => {
    const m = mod(LIB);
    console.log(`${TAG} ${LIB} = ${m ? m.base + ' size=' + m.size : '尚未加载'}`);

    const mangled = {
        addKeySign: '_ZN7cocos2d9FileUtils18addXXTEAKeyAndSignENSt6__ndk112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEES7_',
        addKeySignV2: '_ZN7cocos2d9FileUtils20addXXTEAKeyAndSignV2ENSt6__ndk112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEES7_',
        addKeySignV3: '_ZN7cocos2d9FileUtils20addXXTEAKeyAndSignV3ENSt6__ndk112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEES7_',
        addKeySignV4: '_ZN7cocos2d9FileUtils20addXXTEAKeyAndSignV4ENSt6__ndk112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEES7_',
        initXxtea: '_ZN12LuaBridgeCtl19initXXTeaAndLookupsEv',
        setKeyGM: '_ZN12LuaBridgeCtl13SetXXTEAKeyGMENSt6__ndk112basic_stringIcNS0_11char_traitsIcEENS0_9allocatorIcEEEE',
        luaLoad: 'luaL_loadbuffer',
        luaLoadX: 'luaL_loadbufferx',
        cocosLoader: 'cocos2dx_lua_loader',
    };

    let hooked = 0;
    for (const key of ['addKeySign', 'addKeySignV2', 'addKeySignV3', 'addKeySignV4']) {
        const addr = exportOf(LIB, mangled[key]);
        if (!addr) { console.log(`${TAG} [skip] ${key} 未找到`); continue; }
        console.log(`${TAG} [hook] ${key} @ ${addr}`);
        try {
            Interceptor.attach(addr, {
                onEnter(args) {
                    const k = readStdString(args[1]);
                    const s = readStdString(args[2]);
                    console.log(`${TAG} ★★★ ${key}  key="${k}"  sign="${s}"`);
                }
            });
            hooked++;
        } catch (e) { console.log(`${TAG} [fail] ${key}: ${e.message}`); }
    }

    for (const key of ['initXxtea', 'setKeyGM']) {
        const addr = exportOf(LIB, mangled[key]);
        if (!addr) { console.log(`${TAG} [skip] ${key} 未找到`); continue; }
        console.log(`${TAG} [hook] ${key} @ ${addr}`);
        try {
            Interceptor.attach(addr, {
                onEnter(args) {
                    const extra = key === 'setKeyGM' ? ` arg="${readStdString(args[1])}"` : '';
                    console.log(`${TAG} ★ ${key}() 被调用${extra}`);
                }
            });
            hooked++;
        } catch (e) { console.log(`${TAG} [fail] ${key}: ${e.message}`); }
    }

    let dumped = 0;
    for (const key of ['luaLoad', 'luaLoadX', 'cocosLoader']) {
        const addr = exportOf(LIB, mangled[key]);
        if (!addr) { console.log(`${TAG} [skip] ${key} 未找到`); continue; }
        console.log(`${TAG} [hook] ${key} @ ${addr}`);
        try {
            Interceptor.attach(addr, {
                onEnter(args) {
                    try {
                        const buf = args[1];
                        const size = args[2].toInt32();
                        if (dumped >= 6 || size <= 0 || size > 8 * 1024 * 1024) return;
                        dumped++;
                        console.log(`${TAG} lua buffer size=${size}`);
                        console.log(hexdump(buf.readByteArray(Math.min(size, 256)), { offset: 0, length: Math.min(size, 256), ansi: false }));
                    } catch (e) { }
                }
            });
            hooked++;
        } catch (e) { console.log(`${TAG} [fail] ${key}: ${e.message}`); }
    }

    const connectAddr = globalExport('connect');
    if (connectAddr) {
        try {
            Interceptor.attach(connectAddr, {
                onEnter(args) {
                    try {
                        const sa = args[1];
                        if (sa.readU16() === 2) {
                            const port = (sa.add(2).readU8() << 8) | sa.add(3).readU8();
                            const ip = [0, 1, 2, 3].map(i => sa.add(4 + i).readU8()).join('.');
                            console.log(`${TAG} connect → ${ip}:${port}`);
                        }
                    } catch (e) { }
                }
            });
            console.log(`${TAG} [hook] connect @ ${connectAddr}`);
            hooked++;
        } catch (e) { console.log(`${TAG} [fail] connect: ${e.message}`); }
    }

    console.log(`${TAG} 已安装 ${hooked} 个 hook`);

    // 延迟扫描内存中的 sign（等资源加载后）
    setTimeout(() => {
        console.log(`${TAG} 开始内存扫描 sign…`);
        try { scanSigns(); } catch (e) { console.log(`${TAG} scan 失败 ${e.message}`); }
    }, 20000);
});
