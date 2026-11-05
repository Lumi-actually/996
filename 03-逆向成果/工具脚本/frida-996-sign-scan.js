'use strict';
var OUT_DIR = '/data/data/com.fgcq.a143097/files/memscan';
var MARKERS = ['XdvFTgd5YA', '4meJnPyl'];
var hits = 0;
function log(s){ console.log('[keyscan] ' + s); }
function hexOf(s){ var o=''; for (var i=0;i<s.length;i++) o += ('0'+s.charCodeAt(i).toString(16)).slice(-2); return o; }
function scan(range, marker){
  if (hits >= 20) return;
  var pat = hexOf(marker), cursor = range.base, end = range.base.add(range.size);
  var CHUNK = 8*1024*1024;
  while (cursor.compare(end) < 0 && hits < 20) {
    var size = Math.min(CHUNK, end.sub(cursor).toInt32());
    if (size <= 0) break;
    var m; try { m = Memory.scanSync(cursor, size, pat); } catch(e){ return; }
    for (var i=0;i<m.length && hits<20;i++){
      var addr = m[i].address; hits++;
      var start = addr.sub(2048), total = 2048 + 8192;
      try {
        var data = start.readByteArray(total);
        var fn = OUT_DIR + '/sign' + ('00'+hits).slice(-3) + '_' + marker.replace(/[^A-Za-z0-9]/g,'_') + '.bin';
        var f = new File(fn,'wb'); f.write(data); f.flush(); f.close();
        log('hit#'+hits+' '+marker+' @ '+addr+' -> '+fn);
      } catch(e){ log('write fail ' + e); }
    }
    cursor = cursor.add(size);
  }
}
setTimeout(function(){
  var rs = Process.enumerateRanges('rw-');
  log('rw- ranges: ' + rs.length);
  for (var i=0;i<rs.length;i++){
    if (rs[i].size > 400*1024*1024) continue;
    for (var k=0;k<MARKERS.length;k++){ scan(rs[i], MARKERS[k]); if (hits>=20) break; }
    if (hits>=20) break;
  }
  log('done hits=' + hits);
}, 1500);
