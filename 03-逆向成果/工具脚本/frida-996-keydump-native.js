/*
 * frida-996-keydump-native.js  — for the *native ARM64* device (gadget or server).
 *
 * Hooks the four XXTEA entry points by ELF offset (they are exported symbols in
 * libMyGame.so, but we address them by offset so this also works if the symbol
 * table is stripped) and dumps:
 *   - the 16-byte key passed to xxtea_decrypt*
 *   - the ciphertext length
 *   - the decrypted plaintext head, if it is readable after the call
 * It also hooks luaL_loadbuffer to dump every Lua chunk that gets loaded.
 *
 * Offsets come from the shipped lib/arm64-v8a/libMyGame.so (.dynsym):
 *   xxtea_decrypt      0xdc9cc4
 *   xxtea_decrypt_v2   0xdca044
 *   xxtea_decrypt_v3   0xdca3c4
 *   xxtea_decrypt_v4   0xdca74c
 *   luaL_loadbuffer    0xae0844
 *   luaL_loadbufferx   0xae0790
 */
'use strict';

var TAG = '[keydump]';
var LIB = 'libMyGame.so';
var XTEA = [
  ['xxtea_decrypt', 0xdc9cc4],
  ['xxtea_decrypt_v2', 0xdca044],
  ['xxtea_decrypt_v3', 0xdca3c4],
  ['xxtea_decrypt_v4', 0xdca74c]
];
var LUA_LOAD = [
  ['luaL_loadbuffer', 0xae0844, { data: 1, size: 2, name: 3 }],
  ['luaL_loadbufferx', 0xae0790, { data: 1, size: 2, name: 3 }]
];

var seenKeys = {};
var chunkCount = 0;

function log(s) { console.log(TAG + ' ' + s); }

function toHex(buf, max) {
  try {
    var bytes = new Uint8Array(buf);
    var out = [];
    for (var i = 0; i < Math.min(bytes.length, max || 16); i++) {
      out.push(('0' + bytes[i].toString(16)).slice(-2));
    }
    return out.join('');
  } catch (e) { return '<err ' + e + '>'; }
}

function printable(buf, n) {
  try {
    var bytes = new Uint8Array(buf);
    var s = '';
    for (var i = 0; i < Math.min(bytes.length, n); i++) {
      var c = bytes[i];
      s += (c >= 32 && c < 127) ? String.fromCharCode(c) : '.';
    }
    return s;
  } catch (e) { return '<err>'; }
}

function install() {
  var mod = Process.findModuleByName(LIB);
  if (!mod) { setTimeout(install, 250); return; }
  log('module ' + LIB + ' base=' + mod.base + ' size=' + mod.size);

  XTEA.forEach(function (entry) {
    var name = entry[0], off = entry[1];
    var addr = mod.base.add(off);
    try {
      Interceptor.attach(addr, {
        onEnter: function (args) {
          try {
            this.keyPtr = args[2];
            this.len = args[1].toInt32();
            var hex = toHex(args[2].readByteArray(16));
            this.keyHex = hex;
            if (!seenKeys[hex]) {
              seenKeys[hex] = 1;
              send({ tag: 'KEY', fn: name, key_hex: hex, data_len: this.len });
              log('KEY ' + name + ' = ' + hex + '  (ascii: ' + printable(args[2].readByteArray(16), 16) + ')');
            }
          } catch (e) { log('onEnter err ' + e); }
        }
      });
      log('hooked ' + name + ' @ ' + addr);
    } catch (e) {
      log('hook ' + name + ' failed: ' + e);
    }
  });

  LUA_LOAD.forEach(function (entry) {
    var name = entry[0], off = entry[1], idx = entry[2];
    var addr = mod.base.add(off);
    try {
      Interceptor.attach(addr, {
        onEnter: function (args) {
          try {
            var size = args[idx.size].toInt32();
            if (size <= 0 || size > 4 * 1024 * 1024) return;
            chunkCount++;
            var nm = '';
            try { nm = args[idx.name].readCString() || ''; } catch (e) { }
            var head = args[idx.data].readByteArray(Math.min(64, size));
            var looksLua = printable(head, 16);
            send({
              tag: 'CHUNK', n: chunkCount, name: nm, size: size,
              magic_hex: toHex(head, 4), head: looksLua
            });
            log('CHUNK #' + chunkCount + ' ' + name + ' size=' + size + ' name=' + nm +
                ' head=' + toHex(head, 4) + ' "' + looksLua + '"');
          } catch (e) { }
        }
      });
      log('hooked ' + name + ' @ ' + addr);
    } catch (e) {
      log('hook ' + name + ' failed: ' + e);
    }
  });

  log('ready');
}

install();
setInterval(function () {
  log('alive; keys=' + Object.keys(seenKeys).length + ' chunks=' + chunkCount);
}, 20000);
