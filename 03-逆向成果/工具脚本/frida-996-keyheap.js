/*
 * frida-996-keyheap.js  (v2, O(n) printable-run harvesting)
 *
 * The XXTEA key for the mod assets is passed in from Lua via
 * LuaBridgeCtl::SetXXTEAKeyGM(std::string), so it lives in the heap as an
 * ordinary printable string. Harvest every unique 16-byte printable window.
 */
'use strict';

var OUT = '/data/data/com.fgcq.a143097/files/keycands.bin';
var MAXC = 600000;
var seen = {};
var store = [];
var scanned = 0;

function log(s) { console.log('[keyheap] ' + s); }

function addWindow(u8, off) {
  var key = '';
  for (var m = 0; m < 16; m++) key += String.fromCharCode(u8[off + m]);
  if (seen[key]) return;
  seen[key] = 1;
  store.push(key);
}

function addPadded(u8, start, len) {
  var key = '';
  for (var m = 0; m < 16; m++) key += (m < len) ? String.fromCharCode(u8[start + m]) : '\u0000';
  if (seen[key]) return;
  seen[key] = 1;
  store.push(key);
}

function emitRun(u8, start, end) {
  var len = end - start;
  if (len < 4) return;
  if (len < 16) { addPadded(u8, start, len); return; }
  for (var o = start; o + 16 <= end; o++) {
    addWindow(u8, o);
    if (store.length >= MAXC) return;
  }
  // also the zero-padded prefix form (C string shorter than 16)
  for (var L = 4; L <= 15; L++) addPadded(u8, start, L);
}

// carry: bytes from the tail of the previous chunk that are still printable
var carry = null;

function harvest(buf) {
  var u8 = new Uint8Array(buf);
  scanned += u8.length;
  var data = u8, offset = 0;
  if (carry && carry.length) {
    // build a small prefix so runs spanning the boundary are not lost
    var merged = new Uint8Array(carry.length + Math.min(u8.length, 4096));
    merged.set(carry, 0);
    merged.set(u8.subarray(0, Math.min(u8.length, 4096)), carry.length);
    emitRun(merged, 0, merged.length);
    carry = null;
  }
  var runStart = -1;
  for (var i = 0; i < u8.length; i++) {
    var b = u8[i];
    if (b >= 0x20 && b <= 0x7e) {
      if (runStart < 0) runStart = i;
    } else {
      if (runStart >= 0) emitRun(u8, runStart, i);
      runStart = -1;
      if (store.length >= MAXC) return;
    }
  }
  if (runStart >= 0 && u8.length - runStart >= 16) {
    emitRun(u8, runStart, u8.length);
  }
  // remember trailing printable bytes for the next chunk
  var tailStart = u8.length;
  while (tailStart > 0 && u8[tailStart - 1] >= 0x20 && u8[tailStart - 1] <= 0x7e) tailStart--;
  if (u8.length - tailStart >= 16) {
    carry = u8.subarray(tailStart, u8.length);
  }
}

function writeOut() {
  try {
    var buf = Memory.alloc(store.length * 16);
    for (var i = 0; i < store.length; i++) buf.add(i * 16).writeUtf8String(store[i]);
    var f = new File(OUT, 'wb');
    f.write(buf.readByteArray(store.length * 16));
    f.flush(); f.close();
    log('wrote ' + store.length + ' candidates');
  } catch (e) { log('write failed: ' + e); }
}

setTimeout(function () {
  var ranges = Process.enumerateRanges('rw-');
  log('rw- ranges: ' + ranges.length);
  ranges.sort(function (a, b) { return b.size - a.size; });
  for (var i = 0; i < ranges.length && store.length < MAXC; i++) {
    if (ranges[i].size > 400 * 1024 * 1024) continue;
    var CHUNK = 8 * 1024 * 1024;
    var cur = ranges[i].base, end = ranges[i].base.add(ranges[i].size);
    while (cur.compare(end) < 0 && store.length < MAXC) {
      var sz = Math.min(CHUNK, end.sub(cur).toInt32());
      if (sz <= 0) break;
      var b = null;
      try { b = cur.readByteArray(sz); } catch (e) { break; }
      harvest(b);
      cur = cur.add(sz);
    }
  }
  log('scanned=' + scanned + ' cands=' + store.length);
  writeOut();
  log('done');
}, 1000);
