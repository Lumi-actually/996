#!/usr/bin/env python3
"""Disassemble the key-setting functions in libMyGame.so and resolve their rodata references.

Symbols (AArch64 ELF, .dynsym present):
  LuaBridgeCtl::initXXTeaAndLookups                0x72202c
  LuaBridgeCtl::SetXXTEAKeyGM(std::string)         0x723abc
  lua_..._LuaBridgeCtl_SetXXTEAKeyGM(lua_State*)   0x7360d8
  cocos2d::FileUtils::addXXTEAKeyAndSign*          0xd18e84 / 0xd190b0 / 0xd192dc
"""
import struct
import sys

from capstone import Cs, CS_ARCH_ARM64, CS_MODE_ARM
from capstone.arm64 import ARM64_OP_REG, ARM64_OP_IMM, ARM64_OP_MEM
from elftools.elf.elffile import ELFFile

sys.stdout.reconfigure(encoding="utf-8", errors="replace")

SO = r"D:\asdk\tmp\libMyGame.so"

TARGETS = [
    ("LuaBridgeCtl::initXXTeaAndLookups", 0x72202c, 3288),
    ("LuaBridgeCtl::SetXXTEAKeyGM(string)", 0x723abc, 2016),
    ("lua_SetXXTEAKeyGM(lua_State*)", 0x7360d8, 500),
    ("FileUtils::addXXTEAKeyAndSign", 0xd18e84, 556),
    ("FileUtils::addXXTEAKeyAndSignV3", 0xd192dc, 916),
]


class Image:
    def __init__(self, path):
        self.f = open(path, "rb")
        self.elf = ELFFile(self.f)
        self.segments = []
        for seg in self.elf.iter_segments():
            if seg["p_type"] == "PT_LOAD":
                self.segments.append((seg["p_vaddr"], seg["p_vaddr"] + seg["p_filesz"], seg["p_offset"]))

    def read(self, vaddr, n):
        for start, end, off in self.segments:
            if start <= vaddr and vaddr + n <= end:
                self.f.seek(off + (vaddr - start))
                return self.f.read(n)
        return b""

    def cstr(self, vaddr, cap=64):
        raw = self.read(vaddr, cap)
        if not raw:
            return None
        s = raw.split(b"\x00")[0]
        return s


def printable(b):
    if not b:
        return False
    ok = sum(1 for c in b if 32 <= c < 127 or c in (9, 10, 13))
    return ok / len(b) > 0.85


def analyze(img: Image, name: str, vaddr: int, size: int) -> None:
    code = img.read(vaddr, size)
    if not code:
        print("!! cannot read %s at %#x" % (name, vaddr))
        return
    md = Cs(CS_ARCH_ARM64, CS_MODE_ARM)
    md.detail = True
    print("\n" + "=" * 78)
    print("%s @ %#x  (%d bytes)" % (name, vaddr, len(code)))

    adrp = {}          # reg -> page address
    seen = set()
    for ins in md.disasm(code, vaddr):
        m = ins.mnemonic
        ops = ins.operands
        # adrp xN, #imm
        if m == "adrp" and len(ops) == 2 and ops[0].type == ARM64_OP_REG and ops[1].type == ARM64_OP_IMM:
            adrp[ins.reg_name(ops[0].reg)] = ops[1].imm
            continue
        # add xN, xM, #imm   (xM from adrp)
        if m in ("add", "ldr", "adr") and len(ops) >= 3:
            dst = ins.reg_name(ops[0].reg) if ops[0].type == ARM64_OP_REG else None
            base = ins.reg_name(ops[1].reg) if ops[1].type == ARM64_OP_REG else None
            if m == "add" and base in adrp and ops[2].type == ARM64_OP_IMM:
                addr = adrp[base] + ops[2].imm
                adrp[dst] = addr
                data = img.cstr(addr, 48)
                if data and printable(data) and addr not in seen:
                    seen.add(addr)
                    print("  %#010x  add      -> %#x  %r" % (ins.address, addr, data.decode("latin1")))
                continue
            # ldr xN, [xM, #imm]
            if m == "ldr" and ops[1].type == ARM64_OP_MEM:
                mb = ins.reg_name(ops[1].mem.base)
                if mb in adrp:
                    addr = adrp[mb] + ops[1].mem.disp
                    ptr = img.read(addr, 8)
                    if ptr and len(ptr) == 8:
                        target = struct.unpack("<Q", ptr)[0]
                        data = img.cstr(target, 48) if target else None
                        if data and printable(data) and target not in seen:
                            seen.add(target)
                            print("  %#010x  ldr ptr  -> %#x  %r" % (ins.address, target, data.decode("latin1")))
                    data2 = img.cstr(addr, 32)
                    if data2 and printable(data2) and addr not in seen:
                        seen.add(addr)
                        print("  %#010x  ldr      -> %#x  %r" % (ins.address, addr, data2.decode("latin1")))
        # bl xxtea_decrypt?
        if m == "bl" and ops and ops[0].type == ARM64_OP_IMM:
            tgt = ops[0].imm
            if 0xdc9000 <= tgt <= 0xdcb000:
                print("  %#010x  bl       -> %#x  (xxtea family)" % (ins.address, tgt))


def main() -> int:
    img = Image(SO)
    for name, vaddr, size in TARGETS:
        analyze(img, name, vaddr, size)
    print("\nnote: 16-byte keys are read from these addresses and tested offline")
    return 0


if __name__ == "__main__":
    sys.exit(main())
