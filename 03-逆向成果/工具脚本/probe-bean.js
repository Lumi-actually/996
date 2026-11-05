'use strict';
function log(s){ console.log('[bean] ' + s); }
Java.perform(function(){
  ['com.xqhy.login.bean.LoginBean','com.xqhy.cloudphone.bean.SDKLoginResultBean'].forEach(function(cn){
    try {
      var r = Java.enumerateMethods(cn + '!*');
      r.forEach(function(b){
        (b.classes||[]).forEach(function(c){
          log(c.name + ' methods(' + (c.methods||[]).length + '): ' + (c.methods||[]).join(','));
        });
      });
    } catch(e){ log(cn + ' ERR ' + e); }
  });
  log('done');
});
