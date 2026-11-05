/*
 * frida-996-sdata-inject.js  (attach phase, Java only)
 *
 * The client stalls because the Lua side sees `paramJson.sdata: nil` and then
 * builds an invalid roleinfo URL. The payload reaching Lua is assembled on the
 * Java side and handed to C++ via AndroidNDKHelper.SendMessageWithParameters.
 * Hook it, log every message, and inject an `sdata` field into the login
 * callback so the Lua flow can proceed.
 */
'use strict';

var TAG = '[sdata]';
var injected = 0;

function log(s) { console.log(TAG + ' ' + s); }

function keysOf(obj) {
  try {
    var it = obj.keys();
    var out = [];
    while (it.hasNext()) out.push(String(it.next()));
    return out.join(',');
  } catch (e) { return '<' + e + '>'; }
}

function put(obj, key, value) {
  try {
    obj.put(key, value);
    return true;
  } catch (e) {
    try {
      obj.put.overload('java.lang.String', 'java.lang.Object').call(obj, key, value);
      return true;
    } catch (e2) {
      log('put failed: ' + e2);
      return false;
    }
  }
}

function hashCodeOf(obj, key) {
  try {
    var v = obj.get(key);
    return v === null || v === undefined ? 'null' : String(v).slice(0, 40);
  } catch (e) { return '<' + e + '>'; }
}

Java.perform(function () {
  var AH = null;
  try { AH = Java.use('com.easyndk.classes.AndroidNDKHelper'); }
  catch (e) { log('AndroidNDKHelper not found: ' + e); return; }
  if (!AH) return;

  var JSONObject = null;
  try { JSONObject = Java.use('org.json.JSONObject'); } catch (e) { }

  var hooked = 0;
  function hookOverloads(methodName) {
    if (!AH[methodName]) { log(methodName + ' absent'); return; }
    AH[methodName].overloads.forEach(function (ov) {
      ov.implementation = function () {
        try {
          var n = arguments.length;
          var method = null, obj = null;
          // find the JSONObject and the method-name string among the args
          for (var i = 0; i < n; i++) {
            var a = arguments[i];
            if (a === null || a === undefined) continue;
            var cn = a.$className || '';
            if (cn.indexOf('org.json.JSONObject') >= 0) obj = a;
            else if (typeof a === 'string' || cn.indexOf('java.lang.String') >= 0) {
              var s = String(a);
              if (/^[A-Za-z_][A-Za-z0-9_]*$/.test(s)) method = s;
            }
          }
          if (method) {
            log(methodName + ' -> "' + method + '"  keys=[' + (obj ? keysOf(obj) : '-') + ']');
          }
          if (obj && method && /SDKLoginCB/i.test(method)) {
            if (put(obj, 'sdata', '{}')) {
              injected++;
              log('  injected sdata={} into ' + method + ' (total ' + injected + ')');
            }
          }
          if (obj && method && /recvData/i.test(method)) {
            var before = hashCodeOf(obj, 'sdata');
            if (before === 'null') {
              if (put(obj, 'sdata', '{}')) {
                injected++;
                log('  injected sdata={} into ' + method + ' (total ' + injected + ')');
              }
            } else {
              log('  recvData already has sdata=' + before);
            }
          }
        } catch (e) {
          log('hook body error: ' + e);
        }
        return ov.apply(this, arguments);
      };
      hooked++;
    });
    log('hooked ' + methodName + ' overloads: ' + hooked);
  }

  hookOverloads('SendMessageWithParameters');
  hookOverloads('sendMessageWithParameters');
  log('ready');
});
