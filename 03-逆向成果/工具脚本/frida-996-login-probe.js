/*
 * frida-996-login-probe.js  (attach phase, Java)
 *
 * The Java->C++ bridge method SendMessageWithParameters cannot be replaced on
 * this emulator (trampoline allocation fails), but SDKLoginManager.callbackLoginSuccess
 * can. This probe records what that callback receives so we can rebuild its
 * payload with an extra `sdata` field and push it through the bridge ourselves.
 */
'use strict';

function log(s) { console.log('[login] ' + s); }

function describe(a) {
  if (a === null) return 'null';
  if (a === undefined) return 'undefined';
  try {
    var cn = a.$className || typeof a;
    if (cn === 'java.lang.String' || typeof a === 'string') return 'String("' + String(a).slice(0, 120) + '")';
    if (String(cn).indexOf('JSONObject') >= 0) {
      try { return 'JSONObject(' + a.toString().slice(0, 300) + ')'; } catch (e) { return 'JSONObject(?)'; }
    }
    if (String(cn).indexOf('int') === 0 || typeof a === 'number') return 'num(' + a + ')';
    try { return cn + '(' + String(a) + ')'; } catch (e) { return cn; }
  } catch (e) { return '<describe error>'; }
}

Java.perform(function () {
  // ---- real-name bypass (same four hooks that are known to work) ----
  try {
    var LoginBean = Java.use('com.xqhy.login.bean.LoginBean');
    LoginBean.getAgeStatus.implementation = function () { return 1; };
    LoginBean.setAgeStatus.overloads.forEach(function (o) {
      o.implementation = function (v) { return o.call(this, 1); };
    });
    log('age hooks on LoginBean ok');
  } catch (e) { log('LoginBean hook err ' + e); }

  try {
    var R = Java.use('com.xqhy.cloudphone.bean.SDKLoginResultBean');
    R.getAgeStatus.implementation = function () { return 1; };
    log('age hook on SDKLoginResultBean ok');
  } catch (e) { log('SDKLoginResultBean hook err ' + e); }

  // ---- probe the login callback ----
  try {
    var SLM = Java.use('com.xqhy.login.SDKLoginManager');
    var ovs = SLM.callbackLoginSuccess.overloads;
    log('callbackLoginSuccess overloads: ' + ovs.length);
    ovs.forEach(function (o, i) {
      log('  [' + i + '] (' + o.argumentTypes.map(function (t) { return t.className; }).join(',') + ')');
      var orig = o;
      o.implementation = function () {
        try {
          var parts = [];
          for (var k = 0; k < arguments.length; k++) parts.push(describe(arguments[k]));
          log('callbackLoginSuccess called with ' + parts.length + ' args:');
          parts.forEach(function (p, idx) { log('   arg[' + idx + '] = ' + p); });
        } catch (e) { log('callbackLoginSuccess log error: ' + e); }
        return orig.apply(this, arguments);
      };
      log('  hooked overload ' + i);
    });
  } catch (e) { log('SDKLoginManager hook err ' + e); }

  log('ready');
});
