'use strict';
// Minimal no-op spawn payload: keeps frida holding the process at spawn so the
// ARM-translation layer survives startup on this emulator.
console.log('[noop] attached at spawn');
