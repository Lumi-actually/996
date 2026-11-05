'use strict';
function log(s){ console.log('[diag] ' + s); }
Java.perform(function(){
  try {
    var AH = Java.use('com.easyndk.classes.AndroidNDKHelper');
    var ovs = AH.SendMessageWithParameters.overloads;
    log('SendMessageWithParameters overloads: ' + ovs.length);
    ovs.forEach(function(o, i){
      var types = o.argumentTypes.map(function(t){ return t.className; }).join(',');
      log('  [' + i + '] (' + types + ')');
    });
  } catch(e){ log('ERR ' + e); }
  try {
    var N = Java.use('org.cocos2dx.cpp.NDKHelperCocosFunc');
    log('NDKHelperCocosFunc.run overloads: ' + N.run.overloads.length);
    N.run.overloads.forEach(function(o,i){
      log('  run[' + i + '] (' + o.argumentTypes.map(function(t){return t.className;}).join(',') + ')');
    });
  } catch(e){ log('ERR2 ' + e); }
  log('done');
});
