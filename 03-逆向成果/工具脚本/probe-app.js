'use strict';
function log(s){ console.log('[app] ' + s); }
Java.perform(function(){
  try {
    var r = Java.enumerateMethods('org.cocos2dx.cpp.AppActivity!*');
    r.forEach(function(b){
      (b.classes||[]).forEach(function(c){
        var ms = (c.methods||[]);
        log(c.name + ' total=' + ms.length);
        var gn = ms.filter(function(m){ return /^(GN_|get|set)/.test(m); });
        log('  GN_/get/set: ' + gn.join(','));
      });
    });
  } catch(e){ log('ERR ' + e); }
  log('done');
});
