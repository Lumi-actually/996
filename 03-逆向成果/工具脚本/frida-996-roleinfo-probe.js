'use strict';
function log(s){ console.log('[probe] ' + s); }
Java.perform(function(){
  try {
    var r = Java.enumerateMethods('*!setRoleInfo');
    log('rawType=' + (Object.prototype.toString.call(r)));
    log('raw=' + JSON.stringify(r).slice(0, 1500));
    if (r.length) { log('keys=' + Object.keys(r[0]).join(',')); }
  } catch(e){ log('ERR ' + e); }
  log('done');
});
