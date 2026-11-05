'use strict';
function log(s){ console.log('[probe] ' + s); }
setTimeout(function(){
  var m = Process.findModuleByName('libMyGame.so');
  if (!m) { log('libMyGame.so not loaded'); return; }
  log('base=' + m.base + ' size=' + m.size);
  var want = /lua/i;
  var hits = [];
  try {
    m.enumerateExports().forEach(function(e){
      if (want.test(e.name)) hits.push(e.type + ' ' + e.name);
    });
  } catch(e){ log('enum err ' + e); }
  log('lua exports: ' + hits.length);
  hits.slice(0, 60).forEach(function(h){ log('  ' + h); });
}, 3000);
