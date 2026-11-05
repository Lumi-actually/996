/*
 * frida-996-local-server.js
 *
 * 1) age/real-name bypass  (class names verified in an earlier session)
 * 2) rewrite the client's GAME GATE tcp connect to the local server
 *
 * The modlist/serverlist signature is left untouched: the client keeps using
 * the official list (fed through the local transparent proxy on :8888) and we
 * only swap the destination of the gate connection to 10.0.2.2:7000.
 */
'use strict';

var TAG = '[996-local]';
var LOCAL_IP = [10, 0, 2, 2];
var LOCAL_GATE_PORT = 7000;
var REDIRECT_PORTS = [8081, 8080, 7100, 7102, 7001, 9000, 8001];

function log(s) { console.log(TAG + ' ' + s); }

/* ---------------- native: connect() redirect ---------------- */
function findExport(name) {
  var a = null;
  try { a = Module.getGlobalExportByName(name); } catch (e) { }
  if (!a) { try { a = Module.getExportByName(null, name); } catch (e) { } }
  if (!a) { try { a = Module.getExportByName('libc.so', name); } catch (e) { } }
  return a;
}

function hookConnect() {
  var target = findExport('connect');
  if (!target) { log('connect not found'); return; }
  Interceptor.attach(target, {
    onEnter: function (args) {
      try {
        var sa = args[1];
        if (sa.isNull()) return;
        if (sa.readU16() !== 2) return;                 // AF_INET
        var port = (sa.add(2).readU8() << 8) | sa.add(3).readU8();
        var ip = [sa.add(4).readU8(), sa.add(5).readU8(),
                  sa.add(6).readU8(), sa.add(7).readU8()];
        var want = REDIRECT_PORTS.indexOf(port) >= 0;
        log('connect ' + ip.join('.') + ':' + port + (want ? '  [REDIRECT]' : ''));
        if (want) {
          sa.add(4).writeU8(LOCAL_IP[0]); sa.add(5).writeU8(LOCAL_IP[1]);
          sa.add(6).writeU8(LOCAL_IP[2]); sa.add(7).writeU8(LOCAL_IP[3]);
          sa.add(2).writeU8((LOCAL_GATE_PORT >> 8) & 0xff);
          sa.add(3).writeU8(LOCAL_GATE_PORT & 0xff);
          log('   -> ' + LOCAL_IP.join('.') + ':' + LOCAL_GATE_PORT);
        }
      } catch (e) { }
    }
  });
  log('connect hooked @ ' + target);
}

/* ---------------- java: age bypass ---------------- */
function hookGetter(cls, meth) {
  try {
    var C = Java.use(cls);
    if (!C[meth]) { log('[miss] ' + cls + '.' + meth); return 0; }
    C[meth].implementation = function () {
      var orig = null;
      try { orig = C[meth].call(this); } catch (e) { }
      log(cls + '.' + meth + '() ' + orig + ' -> 1');
      return Java.use('java.lang.Integer').valueOf(1);
    };
    log('[hook] ' + cls + '.' + meth + ' -> 1');
    return 1;
  } catch (e) { log('[fail] ' + cls + '.' + meth + ': ' + e); return 0; }
}

function hookSetter(cls, meth) {
  try {
    var C = Java.use(cls);
    if (!C[meth]) { log('[miss] ' + cls + '.' + meth); return 0; }
    C[meth].implementation = function (v) {
      log(cls + '.' + meth + '(' + v + ') -> 1');
      return C[meth].call(this, Java.use('java.lang.Integer').valueOf(1));
    };
    log('[hook] ' + cls + '.' + meth + '(..) -> 1');
    return 1;
  } catch (e) { log('[fail] ' + cls + '.' + meth + ': ' + e); return 0; }
}

function watchRealName() {
  try {
    var RA = Java.use('com.xqhy.login.view.RealNameActivity');
    RA.onCreate.implementation = function (b) {
      log('RealNameActivity.onCreate -> finish + relaunch AppActivity');
      try {
        var Intent = Java.use('android.content.Intent');
        var AppAct = Java.use('org.cocos2dx.cpp.AppActivity');
        var it = Intent.$new(this, AppAct.class);
        it.addFlags(0x10000000);
        this.startActivity(it);
      } catch (e) { log('relaunch failed: ' + e); }
      this.finish();
    };
    log('[hook] RealNameActivity.onCreate -> skip');
    return 1;
  } catch (e) { log('[fail] RealNameActivity: ' + e); return 0; }
}

function installJavaHooks() {
  if (typeof Java === 'undefined' || !Java.available) {
    log('Java not available yet, retry in 1.5s');
    setTimeout(installJavaHooks, 1500);
    return;
  }
  Java.perform(function () {
    log('===== installing java hooks =====');
    var n = 0;
    n += hookGetter('com.xqhy.login.bean.LoginBean', 'getAgeStatus');
    n += hookSetter('com.xqhy.login.bean.LoginBean', 'setAgeStatus');
    n += hookGetter('com.xqhy.cloudphone.bean.SDKLoginResultBean', 'getAgeStatus');
    n += watchRealName();
    log('===== java hooks done (' + n + ') =====');
  });
}

setImmediate(function () {
  log('===== start =====');
  try { hookConnect(); } catch (e) { log('connect hook failed: ' + e); }
  try { installJavaHooks(); } catch (e) { log('java install failed: ' + e); }
  log('===== start done =====');
});
