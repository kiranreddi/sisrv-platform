#!/usr/bin/env python3
"""Convert a RISC-V ELF (32- or 64-bit class) into sisrv ROM/RAM hex images."""

from __future__ import annotations

import argparse
import struct
import sys
from pathlib import Path

ROM_BASE = 0x00000000
RAM_BASE = 0x80000000
PT_LOAD = 1
EM_RISCV = 243
ELFCLASS32 = 1
ELFCLASS64 = 2


def read_u16(data: bytes, off: int) -> int:
    return struct.unpack_from("<H", data, off)[0]


def read_u32(data: bytes, off: int) -> int:
    return struct.unpack_from("<I", data, off)[0]


def read_u64(data: bytes, off: int) -> int:
    return struct.unpack_from("<Q", data, off)[0]


def load_segments(elf_path: Path) -> tuple[dict[int, int], dict[int, int]]:
    data = elf_path.read_bytes()
    if data[:4] != b"\x7fELF":
        raise ValueError(f"{elf_path}: not an ELF file")

    elf_class = data[4]
    if elf_class not in (ELFCLASS32, ELFCLASS64):
        raise ValueError(f"{elf_path}: unsupported ELF class {elf_class}")

    if read_u16(data, 0x12) != EM_RISCV:
        raise ValueError(f"{elf_path}: expected EM_RISCV machine type")

    rom: dict[int, int] = {}
    ram: dict[int, int] = {}

    if elf_class == ELFCLASS32:
        e_phoff = read_u32(data, 0x1C)
        e_phentsize = read_u16(data, 0x2A)
        e_phnum = read_u16(data, 0x2C)
        for idx in range(e_phnum):
            off = e_phoff + idx * e_phentsize
            p_type = read_u32(data, off)
            if p_type != PT_LOAD:
                continue
            p_offset = read_u32(data, off + 4)
            p_vaddr = read_u32(data, off + 8)
            p_filesz = read_u32(data, off + 16)
            _load_bytes(data, p_offset, p_vaddr, p_filesz, rom, ram)
    else:
        e_phoff = read_u64(data, 0x20)
        e_phentsize = read_u16(data, 0x36)
        e_phnum = read_u16(data, 0x38)
        for idx in range(e_phnum):
            off = e_phoff + idx * e_phentsize
            p_type = read_u32(data, off)
            if p_type != PT_LOAD:
                continue
            p_offset = read_u64(data, off + 8)
            p_vaddr = read_u64(data, off + 16)
            p_filesz = read_u64(data, off + 32)
            if p_vaddr > 0xFFFFFFFF or p_filesz > 0xFFFFFFFF:
                raise ValueError(f"{elf_path}: segment address/size exceeds RV32 map")
            _load_bytes(data, int(p_offset), int(p_vaddr), int(p_filesz), rom, ram)

    return rom, ram


def _load_bytes(
    data: bytes,
    p_offset: int,
    p_vaddr: int,
    p_filesz: int,
    rom: dict[int, int],
    ram: dict[int, int],
) -> None:
    segment = data[p_offset : p_offset + p_filesz]
    for byte_idx, byte_val in enumerate(segment):
        addr = p_vaddr + byte_idx
        if addr >= RAM_BASE:
            ram[addr] = byte_val
        elif addr >= ROM_BASE:
            rom[addr] = byte_val


def write_hex(words: dict[int, int], base: Path) -> None:
    if not words:
        base.write_text("")
        return

    max_addr = max(words)
    min_addr = min(words)
    start_word = min_addr & ~0x3
    end_word = (max_addr + 4) & ~0x3

    lines: list[str] = []
    for addr in range(start_word, end_word, 4):
        word = 0
        for shift in range(4):
            byte_addr = addr + shift
            word |= words.get(byte_addr, 0) << (8 * shift)
        lines.append(f"{word:08x}")

    base.write_text("\n".join(lines) + ("\n" if lines else ""))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("elf", type=Path)
    parser.add_argument("rom_hex", type=Path)
    parser.add_argument("ram_hex", type=Path)
    parser.add_argument(
        "--toolchain-prefix",
        default="riscv64-unknown-elf-",
        help="Toolchain prefix for nm/objcopy helpers",
    )
    args = parser.parse_args()

    rom, ram = load_segments(args.elf)
    write_hex(rom, args.rom_hex)
    write_hex(ram, args.ram_hex)
    return 0


if __name__ == "__main__":
    sys.exit(main())
