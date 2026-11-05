/*
 * frida-996-live.js  — loaded from the PC into Gadget's listen session (V8).
 *
 * The APK's gadget config uses  on_load: "wait", so the process is parked in
 * Application.onCreate until this script has been loaded. That means every hook
 * below is guaranteed to be in place before the engine runs anything.
 */
'use strict';

var TAG = 'FRIDA996';
var LIB = 'libMyGame.so';
var OFF = {
  xxtea_decrypt: 0xdc9cc4,
  xxtea_decrypt_v2: 0xdca044,
  xxtea_decrypt_v3: 0xdca3c4,
  xxtea_decrypt_v4: 0xdca74c,
  luaL_loadbuffer: 0xae0844,
  luaL_loadbufferx: 0xae0790
};
var KEYFILE = '/sdcard/Android/data/com.fgcq.a143097/files/996key.txt';

var seenKeys = {};
var chunkNo = 0;

function emit(s) { console.log(TAG + ' ' + s); }

function appendFile(line) {
  try {
    var f = new File(KEYFILE, 'a');
    f.write(line + '\n');
    f.flush();
    f.close();
  } catch (e) { emit('file write failed: ' + e); }
}

function hex16(p) {
  var b = new Uint8Array(p.readByteArray(16)), s = '';
  for (var i = 0; i < 16; i++) s += ('0' + b[i].toString(16)).slice(-2);
  return s;
}

/* --------------------------------- native -------------------------------- */
function hookNative() {
  var mod = Process.findModuleByName(LIB);
  if (!mod) { setTimeout(hookNative, 150); return; }
  emit('module ' + LIB + ' base=' + mod.base);

  ['xxtea_decrypt', 'xxtea_decrypt_v2', 'xxtea_decrypt_v3', 'xxtea_decrypt_v4'].forEach(function (nm) {
    try {
      Interceptor.attach(mod.base.add(OFF[nm]), {
        onEnter: function (args) {
          try {
            var k = hex16(args[2]);
            if (!seenKeys[k]) {
              seenKeys[k] = nm;
              var line = nm + ' ' + k;
              emit('KEY ' + line + ' len=' + args[1].toInt32());
              appendFile(line);
            }
          } catch (e) { }
        }
      });
      emit('hooked ' + nm);
    } catch (e) { emit('hook fail ' + nm + ': ' + e); }
  });

  ['luaL_loadbuffer', 'luaL_loadbufferx'].forEach(function (nm) {
    try {
      Interceptor.attach(mod.base.add(OFF[nm]), {
        onEnter: function (args) {
          try {
            var size = args[2].toInt32();
            if (size <= 0 || size > 4194304) return;
            chunkNo++;
            var name = '';
            try { name = args[3].readCString() || ''; } catch (e) { }
            var h = new Uint8Array(args[1].readByteArray(8)), hx = '';
            for (var i = 0; i < 8; i++) hx += ('0' + h[i].toString(16)).slice(-2);
            if (chunkNo <= 400) emit('CHUNK #' + chunkNo + ' size=' + size + ' head=' + hx + ' name=' + name);
          } catch (e) { }
        }
      });
      emit('hooked ' + nm);
    } catch (e) { emit('hook fail ' + nm + ': ' + e); }
  });
}

/* ---------------------------------- Java --------------------------------- */
function hookJava() {
  var done = [];

  function tryHook(label, fn) {
    try { fn(); done.push(label); }
    catch (e) { emit('java hook ' + label + ' failed: ' + e); }
  }

  tryHook('LoginBean.getAgeStatus', function () {
    var C = Java.use('com.xqhy.login.bean.LoginBean');
    C.getAgeStatus.implementation = function () { return 1; };
  });

  tryHook('LoginBean.setAgeStatus', function () {
    var C = Java.use('com.xqhy.login.bean.LoginBean');
    C.setAgeStatus.overloads.forEach(function (o) {
      o.implementation = function () { return o.call(this, 1); };
    });
  });

  tryHook('SDKLoginResultBean.getAgeStatus', function () {
    var C = Java.use('com.xqhy.cloudphone.bean.SDKLoginResultBean');
    C.getAgeStatus.implementation = function () { return 1; };
  });

  // The real-name dialog actually lives here (the security.* package was wrong).
  tryHook('login.view.RealNameActivity', function () {
    var C = Java.use('com.xqhy.login.view.RealNameActivity');
    C.onCreate.overload('android.os.Bundle').implementation = function (b) {
      emit('RealNameActivity.onCreate intercepted -> finish()');
      try { this.finish(); } catch (e) { emit('finish err ' + e); }
    };
  });

  emit('java hooks: ' + (done.length ? done.join(', ') : 'none'));
}

hookNative();
Java.perform(hookJava);

setInterval(function () {
  emit('alive keys=' + Object.keys(seenKeys).length + ' chunks=' + chunkNo);
}, 20000);
