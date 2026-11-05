'use strict';
function log(s){ console.log('[diag] ' + s); }
var targets = [
  ['com.xqhy.login.SDKLoginManager','callbackLoginSuccess'],
  ['com.xqhy.login.SDKLoginManager','callbackChangeSuccess'],
  ['com.xqhy.login.SDKLoginManager','login'],
  ['com.easyndk.classes.AndroidNDKHelper','ReceiveCppMessage'],
  ['com.easyndk.classes.AndroidNDKHelper','CPPNativeCallHandler'],
  ['com.easyndk.classes.AndroidNDKHelper','SetNDKReceiver']
];
Java.perform(function(){
  targets.forEach(function(t){
    var cn = t[0], mn = t[1];
    try {
      var C = Java.use(cn);
      if (!C[mn]) { log(mn + ' absent in ' + cn); return; }
      var ovs = C[mn].overloads;
      var okCount = 0, failMsg = '';
      ovs.forEach(function(o){
        try {
          o.implementation = function () { return o.apply(this, arguments); };
          okCount++;
        } catch(e){ failMsg = String(e).slice(0, 60); }
      });
      log(cn.split('.').pop() + '.' + mn + ' overloads=' + ovs.length + ' hooked=' + okCount + (failMsg ? ' fail=' + failMsg : ''));
    } catch(e){ log(cn.split('.').pop() + '.' + mn + ' ERR ' + e); }
  });
  log('done');
});
