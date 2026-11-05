'use strict';
function log(s){ console.log('[probe] ' + s); }
Java.perform(function(){
  var pats = ['*SDKConfigure*!*', '*NDKHelperCocosFunc*!*', '*SDKLoginManager*!*', '*!*Login*CB*'];
  pats.forEach(function(p){
    try {
      var r = Java.enumerateMethods(p);
      var out = [];
      r.forEach(function(b){
        (b.classes || []).forEach(function(c){
          out.push(c.name + ' [' + (c.methods||[]).join(',') + ']');
        });
      });
      log('=== ' + p + ' (' + out.length + ') ===');
      out.slice(0,15).forEach(function(l){ log('  ' + l); });
    } catch(e){ log('ERR ' + p + ': ' + e); }
  });
  log('done');
});
