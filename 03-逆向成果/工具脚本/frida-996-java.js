'use strict';
var TAG = 'FRIDA996J';
function emit(s){ console.log(TAG + ' ' + s); }
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
  tryHook('login.view.RealNameActivity', function () {
    var C = Java.use('com.xqhy.login.view.RealNameActivity');
    C.onCreate.overload('android.os.Bundle').implementation = function (b) {
      emit('RealNameActivity.onCreate intercepted -> finish()');
      try { this.finish(); } catch (e) { emit('finish err ' + e); }
    };
  });
  emit('java hooks: ' + (done.length ? done.join(', ') : 'none'));
}
Java.perform(hookJava);