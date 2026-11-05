'use strict';
function log(s){ console.log('[diag] ' + s); }
Java.perform(function(){
  // 1) boot class
  try {
    var SB = Java.use('java.lang.StringBuilder');
    SB.append.overload('java.lang.String').implementation = function (s) {
      return this.append(s);
    };
    log('boot class hook OK (StringBuilder.append)');
  } catch(e){ log('boot hook FAIL: ' + e); }
  // 2) app class already loaded
  try {
    var LC = Java.use('com.xqhy.login.bean.LoginBean');
    var m = LC.getAgeStatus;
    log('app class resolve OK (LoginBean.getAgeStatus)');
  } catch(e){ log('app resolve FAIL: ' + e); }
  // 3) the target class, simple method
  try {
    var AH = Java.use('com.easyndk.classes.AndroidNDKHelper');
    AH.SetNDKReceiver.implementation = function (cb) { return this.SetNDKReceiver(cb); };
    log('target class hook OK (SetNDKReceiver)');
  } catch(e){ log('target hook FAIL: ' + e); }
  log('done');
});
