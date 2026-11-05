/*
 * frida-996-connect-redirect.js  (spawn phase, native only)
 *
 * v2: Android's Java network stack normally uses AF_INET6 sockets even for
 * IPv4 destinations (v4-mapped ::ffff:a.b.c.d), so v1 (AF_INET only) never
 * matched anything. This version handles both families, logs every connect and
 * every getaddrinfo, and can rewrite gate connections to the local server.
 */
'use strict';

var TAG = '[996-net]';
var LOCAL_V4 = [10, 0, 2, 2];
var LOCAL_PORT = 7000;
var REDIRECT_PORTS = [8081, 8080, 7100, 7102, 7001, 9000, 8001];

function log(s) { console.log(TAG + ' ' + s); }

function findExport(name) {
  var a = null;
  try { a = Module.getGlobalExportByName(name); } catch (e) { }
  if (!a) { try { a = Module.getExportByName(null, name); } catch (e) { } }
  if (!a) { try { a = Module.getExportByName('libc.so', name); } catch (e) { } }
  return a;
}

function hookConnect() {
  var t = findExport('connect');
  if (!t) { log('connect not found'); return; }
  Interceptor.attach(t, {
    onEnter: function (args) {
      try {
        var sa = args[1];
        if (sa.isNull()) return;
        var fam = sa.readU16();
        var port, ipStr, isV6 = false, v4 = null;

        if (fam === 2) {                                   // AF_INET
          port = (sa.add(2).readU8() << 8) | sa.add(3).readU8();
          v4 = [sa.add(4).readU8(), sa.add(5).readU8(),
                sa.add(6).readU8(), sa.add(7).readU8()];
          ipStr = v4.join('.');
        } else if (fam === 10) {                           // AF_INET6
          isV6 = true;
          port = (sa.add(2).readU8() << 8) | sa.add(3).readU8();
          var b = [];
          for (var i = 0; i < 16; i++) b.push(sa.add(8 + i).readU8());
          var zero10 = true;
          for (var j = 0; j < 10; j++) if (b[j] !== 0) { zero10 = false; break; }
          if (zero10 && b[10] === 0xff && b[11] === 0xff) {
            v4 = [b[12], b[13], b[14], b[15]];
            ipStr = 'v4mapped:' + v4.join('.');
          } else {
            ipStr = 'v6:' + b.map(function (x) {
              return ('0' + x.toString(16)).slice(-2);
            }).join('');
          }
        } else {
          return;
        }

        var isLocal = v4 && v4[0] === 10 && v4[1] === 0 && v4[2] === 2;
        var want = (REDIRECT_PORTS.indexOf(port) >= 0) && !isLocal;
        log('connect ' + ipStr + ':' + port + ' fam=' + fam + (want ? '  [REDIRECT]' : ''));

        if (want && v4) {
          // rewrite to v4-mapped 10.0.2.2:LOCAL_PORT (keep family as-is)
          var base = isV6 ? 8 : 4;
          sa.add(base + 0).writeU8(LOCAL_V4[0]);
          sa.add(base + 1).writeU8(LOCAL_V4[1]);
          sa.add(base + 2).writeU8(LOCAL_V4[2]);
          sa.add(base + 3).writeU8(LOCAL_V4[3]);
          sa.add(2).writeU8((LOCAL_PORT >> 8) & 0xff);
          sa.add(3).writeU8(LOCAL_PORT & 0xff);
          log('   -> ' + LOCAL_V4.join('.') + ':' + LOCAL_PORT);
        }
      } catch (e) { }
    }
  });
  log('connect hooked @ ' + t);
}

function hookGetaddrinfo() {
  var t = findExport('getaddrinfo');
  if (!t) { log('getaddrinfo not found'); return; }
  Interceptor.attach(t, {
    onEnter: function (args) {
      try {
        if (args[0].isNull()) return;
        var name = args[0].readCString();
        if (name) log('dns ' + name);
      } catch (e) { }
    }
  });
  log('getaddrinfo hooked @ ' + t);
}

hookConnect();
hookGetaddrinfo();
log('ready');
