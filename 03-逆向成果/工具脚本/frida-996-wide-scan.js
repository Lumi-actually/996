'use strict';
var OUT = '/data/data/com.fgcq.a143097/files/memscan';
var MARKERS = ['XdvFTgd5YA'];
var hits = 0;
function log(s){ console.log('[wide] ' + s); }
function hexOf(s){ var o=''; for (var i=0;i<s.length;i++) o += ('0'+s.charCodeAt(i).toString(16)).slice(-2); return o; }
function go(){
  var rs = Process.enumerateRanges('rw-');
  log('ranges ' + rs.length);
  for (var i=0;i<rs.length;i++){
    if (hits >= 4) break;
    if (rs[i].size > 400*1024*1024) continue;
    var pat = hexOf(MARKERS[0]);
    var cur = rs[i].base, end = rs[i].base.add(rs[i].size), CH = 8*1024*1024;
    while (cur.compare(end) < 0 && hits < 4) {
      var sz = Math.min(CH, end.sub(cur).toInt32()); if (sz<=0) break;
      var m; try { m = Memory.scanSync(cur, sz, pat); } catch(e){ break; }
      for (var k=0;k<m.length && hits<4;k++){
        hits++;
        var addr = m[k].address;
        var before = 32768, after = 32768;
        try {
          var d = addr.sub(before).readByteArray(before+after);
          var fn = OUT + '/wide' + ('0'+hits).slice(-2) + '.bin';
          var f = new File(fn,'wb'); f.write(d); f.flush(); f.close();
          log('hit#'+hits+' @'+addr+' -> '+fn);
        } catch(e){ log('write fail '+e); }
      }
      cur = cur.add(sz);
    }
  }
  log('done hits='+hits);
}
setTimeout(go, 1000);
