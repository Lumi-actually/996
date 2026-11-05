'use strict';
function log(s) { console.log('[diag] ' + s); }

log('script loaded');
try { log('typeof Java = ' + (typeof Java)); } catch (e) { log('typeof err: ' + e); }
try { log('Java.available = ' + Java.available); } catch (e) { log('available err: ' + e); }

try {
  Java.perform(function () {
    log('inside perform');
    try {
      var C = Java.use('com.xqhy.login.bean.LoginBean');
      log('LoginBean resolved: ' + C);
      log('has getAgeStatus: ' + (!!C.getAgeStatus));
      log('has setAgeStatus: ' + (!!C.setAgeStatus));
    } catch (e) { log('Java.use err: ' + e); }
    try {
      var R = Java.use('com.xqhy.login.view.RealNameActivity');
      log('RealNameActivity resolved: ' + R);
    } catch (e) { log('RealNameActivity err: ' + e); }
  });
  log('perform() call returned');
} catch (e) { log('perform err: ' + e); }

setTimeout(function () { log('tick 5s'); }, 5000);
