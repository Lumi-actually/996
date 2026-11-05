/*
 * frida-996-age-hooks.js  (attach phase - java only)
 *
 * Make the 996 SDK believe the account already passed real-name verification,
 * so RealNameActivity never blocks the login flow.
 * Class names were verified with diag-java.js:
 *   com.xqhy.login.bean.LoginBean
 *   com.xqhy.login.view.RealNameActivity
 *   com.xqhy.cloudphone.bean.SDKLoginResultBean
 */
'use strict';

var TAG = '[996-age]';
function log(s) { console.log(TAG + ' ' + s); }

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
      log('RealNameActivity.onCreate -> skip + relaunch AppActivity');
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

Java.perform(function () {
  log('===== installing =====');
  var n = 0;
  n += hookGetter('com.xqhy.login.bean.LoginBean', 'getAgeStatus');
  n += hookSetter('com.xqhy.login.bean.LoginBean', 'setAgeStatus');
  n += hookGetter('com.xqhy.cloudphone.bean.SDKLoginResultBean', 'getAgeStatus');
  n += watchRealName();
  log('===== done (' + n + ') =====');
});
