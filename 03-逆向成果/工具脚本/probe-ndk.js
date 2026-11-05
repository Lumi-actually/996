'use strict';
function log(s){ console.log('[probe] ' + s); }
Java.perform(function(){
  ['com.easyndk.classes.AndroidNDKHelper','org.cocos2dx.cpp.NDKHelperCocosFunc'].forEach(function(cn){
    try {
      var r = Java.enumerateMethods(cn + '!*');
      r.forEach(function(b){
        (b.classes||[]).forEach(function(c){ log(c.name + ' [' + (c.methods||[]).join(',') + ']'); });
      });
    } catch(e){ log(cn + ' ERR ' + e); }
  });
  log('done');
});
