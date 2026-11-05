/*
 * frida-996-lua-dump.js  (spawn phase - native only)
 *
 * Hooks the Lua chunk loaders inside libMyGame.so and dumps every chunk that
 * gets loaded (source or precompiled bytecode) to /data/local/tmp/luadump/.
 * Goal: recover the game Lua that contains the "request roleinfo" / "sdata"
 * logic, which is not present on disk in plaintext.
 */
'use strict';

var TAG = '[lua-dump]';
var OUT_DIR = '/data/local/tmp/luadump';
var MAX_CHUNKS = 4000;
var count = 0;

function log(s) { console.log(TAG + ' ' + s); }

function ensureDir() {
  try {
    var d = new File(OUT_DIR, 'x');
    if (!d.parent.exists) d.parent.mkdirs();
  } catch (e) {
    try { new File(OUT_DIR, 'x').parent.mkdirs(); } catch (e2) { }
  }
  log('dir ready: ' + new File(OUT_DIR, 'x').parent.exists);
}

function safeName(s) {
  if (!s) return 'noname';
  return String(s).replace(/[^A-Za-z0-9_.\-]/g, '_').slice(0, 60);
}

function dump(data, size, name, via) {
  if (!data || data.isNull() || size <= 0 || size > 16 * 1024 * 1024) return;
  if (count >= MAX_CHUNKS) return;
  count++;
  var idx = ('00000' + count).slice(-5);
  var fn = OUT_DIR + '/' + idx + '_' + safeName(name) + '.txt';
  try {
    var buf = data.readByteArray(size);
    var f = new File(fn, 'wb');
    f.write(buf);
    f.flush();
    f.close();
    var head = '';
    try { head = data.readCString(48) || ''; } catch (e) { }
    log('#' + idx + ' ' + via + ' size=' + size + ' name=' + safeName(name) +
        ' head=' + head.replace(/\s+/g, ' '));
  } catch (e) {
    log('write failed ' + fn + ': ' + e);
  }
}

function hookExport(mod, name, argIndexes) {
  var addr = null;
  try { addr = mod.findExportByName(name); } catch (e) { }
  if (!addr) {
    try { addr = Module.findExportByName('libMyGame.so', name); } catch (e) { }
  }
  if (!addr) { return false; }

  Interceptor.attach(addr, {
    onEnter: function (args) {
      try {
        var data = args[argIndexes.data];
        var size = argIndexes.size >= 0 ? args[argIndexes.size].toInt32() : -1;
        var namePtr = args[argIndexes.name];
        var nm = null;
        if (namePtr && !namePtr.isNull()) { try { nm = namePtr.readCString(); } catch (e) { } }
        if (size < 0 && data && !data.isNull()) {
          // luaL_loadstring: NUL-terminated
          try { size = data.readUtf8String().length; } catch (e) { size = 0; }
        }
        dump(data, size, nm, name);
      } catch (e) { }
    }
  });
  log('hooked ' + name + ' @ ' + addr);
  return true;
}

function install() {
  var mod = Process.findModuleByName('libMyGame.so');
  if (!mod) { setTimeout(install, 400); return; }
  log('libMyGame.so base=' + mod.base + ' size=' + mod.size);
  ensureDir();

  // luaL_loadbuffer(L, buff, sz, name)
  hookExport(mod, 'luaL_loadbuffer', { data: 1, size: 2, name: 3 });
  // luaL_loadbufferx(L, buff, sz, name, mode)
  hookExport(mod, 'luaL_loadbufferx', { data: 1, size: 2, name: 3 });
  // luaL_loadstring(L, s)
  hookExport(mod, 'luaL_loadstring', { data: 1, size: -1, name: -1 });
  log('install done, waiting for chunks');
}

install();

// periodic progress
setInterval(function () { log('chunks so far: ' + count); }, 15000);
