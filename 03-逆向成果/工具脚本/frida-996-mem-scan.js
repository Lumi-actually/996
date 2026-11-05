/*
 * frida-996-mem-scan.js  (attach phase)
 *
 * The ARM64 client runs under libndk_translation, so Frida cannot enumerate or
 * hook its guest modules. But Frida CAN read the host process' address space,
 * and the decrypted Lua text lives there. Scan for known plaintext markers and
 * dump the surrounding bytes so the script source can be recovered offline.
 */
'use strict';

var TAG = '[memscan]';
var OUT_DIR = '/data/data/com.fgcq.a143097/files/memscan';
var MARKERS = [
  'request roleinfo',
  'paramJson.sdata',
  'http callback',
  'SDKLoginCallback',
];
var MAX_HITS = 40;
var hits = 0;

function log(s) { console.log(TAG + ' ' + s); }

function ensureDir() {
  try { new File(OUT_DIR, 'x').parent.mkdirs(); } catch (e) { }
}

function hexOf(s) {
  var out = '';
  for (var i = 0; i < s.length; i++) {
    out += ('0' + s.charCodeAt(i).toString(16)).slice(-2);
  }
  return out;
}

function scanRange(range, marker) {
  if (hits >= MAX_HITS) return;
  var pat = hexOf(marker);
  var cursor = range.base;
  var end = range.base.add(range.size);
  var CHUNK = 8 * 1024 * 1024;
  while (cursor.compare(end) < 0 && hits < MAX_HITS) {
    var size = Math.min(CHUNK, end.sub(cursor).toInt32());
    if (size <= 0) break;
    var matches;
    try {
      matches = Memory.scanSync(cursor, size, pat);
    } catch (e) {
      return;
    }
    for (var i = 0; i < matches.length && hits < MAX_HITS; i++) {
      var addr = matches[i].address;
      hits++;
      var before = 1500, after = 6000;
      var startPtr = addr.sub(before);
      var total = before + after;
      var ok = true;
      try {
        var data = startPtr.readByteArray(total);
      } catch (e2) { ok = false; }
      if (!ok) continue;
      var fn = OUT_DIR + '/hit' + ('00' + hits).slice(-3) + '_' +
               marker.replace(/[^A-Za-z0-9]/g, '_') + '.bin';
      try {
        var f = new File(fn, 'wb');
        f.write(data); f.flush(); f.close();
        log('hit#' + hits + ' ' + marker + ' @ ' + addr + ' -> ' + fn);
      } catch (e3) { log('write failed ' + e3); }
    }
    cursor = cursor.add(size);
  }
}

function run() {
  ensureDir();
  log('scanning address space...');
  var ranges = [];
  try { ranges = Process.enumerateRanges('rw-'); } catch (e) { log('enum rw- err ' + e); }
  log('rw- ranges: ' + ranges.length);
  for (var r = 0; r < ranges.length; r++) {
    var range = ranges[r];
    if (range.size > 400 * 1024 * 1024) continue;
    for (var m = 0; m < MARKERS.length; m++) {
      scanRange(range, MARKERS[m]);
      if (hits >= MAX_HITS) break;
    }
    if (hits >= MAX_HITS) break;
  }
  log('done, hits=' + hits);
}

setTimeout(run, 2000);
