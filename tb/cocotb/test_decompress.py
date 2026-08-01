"""cocotb unit tests for sisDecompress (RV32C expander).

Functional coverage is collected as Python bins (Verilator has no covergroups).
"""
from __future__ import annotations

import cocotb
from cocotb.triggers import Timer
import random

# ---------------------------------------------------------------------------
# Lightweight Python fcov (Phase-0 decision: bins live here for Verilator CI)
# ---------------------------------------------------------------------------
FC = {
    "quad0": 0,
    "quad1": 0,
    "quad2": 0,
    "uncompressed": 0,
    "illegal": 0,
    "legal_compressed": 0,
}


def _fc_note(c_instr: int, illegal: bool, is_c: bool) -> None:
    q = c_instr & 0x3
    if not is_c:
        FC["uncompressed"] += 1
    elif illegal:
        FC["illegal"] += 1
    else:
        FC["legal_compressed"] += 1
        FC[{0: "quad0", 1: "quad1", 2: "quad2"}.get(q, "quad0")] += 1


async def apply(dut, c_instr: int):
    dut.c_instr.value = c_instr & 0xFFFF
    await Timer(1, units="ns")
    is_c = int(dut.is_compressed_o.value) == 1
    illegal = int(dut.illegal_o.value) == 1
    instr = int(dut.instr_o.value) & 0xFFFFFFFF
    _fc_note(c_instr, illegal, is_c)
    return is_c, illegal, instr


def enc_c0_addi4spn(nzuimm: int, rdp: int) -> int:
    """C.ADDI4SPN — nzuimm is the 10-bit zero-extended immediate (multiple of 4)."""
    assert nzuimm & 0x3 == 0 and nzuimm != 0
    # RTL: {c[10:7], c[12:11], c[5], c[6], 2'b00} = nzuimm
    c10_7 = (nzuimm >> 6) & 0xF
    c12_11 = (nzuimm >> 4) & 0x3
    c5 = (nzuimm >> 3) & 1
    c6 = (nzuimm >> 2) & 1
    rdp_enc = rdp & 0x7  # low 3 bits; high forced 01 in RTL
    return (c12_11 << 11) | (c10_7 << 7) | (c6 << 6) | (c5 << 5) | (rdp_enc << 2) | 0x0


def enc_c_nop() -> int:
    return 0x0001  # c.nop


def enc_c_addi(rd: int, imm6: int) -> int:
    imm6 &= 0x3F
    return ((imm6 >> 5) << 12) | ((rd & 0x1F) << 7) | ((imm6 & 0x1F) << 2) | 0x1


def enc_c_li(rd: int, imm6: int) -> int:
    imm6 &= 0x3F
    return (0b010 << 13) | ((imm6 >> 5) << 12) | ((rd & 0x1F) << 7) | ((imm6 & 0x1F) << 2) | 0x1


def enc_c_mv(rd: int, rs2: int) -> int:
    return (0b100 << 13) | (0 << 12) | ((rd & 0x1F) << 7) | ((rs2 & 0x1F) << 2) | 0x2


def enc_c_add(rd: int, rs2: int) -> int:
    return (0b100 << 13) | (1 << 12) | ((rd & 0x1F) << 7) | ((rs2 & 0x1F) << 2) | 0x2


@cocotb.test()
async def test_uncompressed_passthrough_flags(dut):
    """Quadrant 11 is not compressed; illegal must be 0."""
    for _ in range(64):
        w = random.randint(0, 0xFFFF) | 0x3  # force quad=11
        is_c, illegal, _ = await apply(dut, w)
        assert is_c == 0
        assert illegal == 0


@cocotb.test()
async def test_c_nop_and_c_addi(dut):
    is_c, illegal, instr = await apply(dut, enc_c_nop())
    assert is_c and not illegal
    assert instr == 0x00000013  # addi x0,x0,0

    is_c, illegal, instr = await apply(dut, enc_c_addi(8, 1))
    assert is_c and not illegal
    # addi x8,x8,1
    assert (instr & 0x7F) == 0x13
    assert ((instr >> 7) & 0x1F) == 8
    assert ((instr >> 15) & 0x1F) == 8
    assert ((instr >> 20) & 0xFFF) == 1


@cocotb.test()
async def test_c_li_mv_add(dut):
    is_c, illegal, instr = await apply(dut, enc_c_li(5, 3))
    assert is_c and not illegal
    assert (instr & 0x7F) == 0x13
    assert ((instr >> 7) & 0x1F) == 5
    assert ((instr >> 15) & 0x1F) == 0
    assert ((instr >> 20) & 0xFFF) == 3

    is_c, illegal, instr = await apply(dut, enc_c_mv(9, 8))
    assert is_c and not illegal
    assert (instr & 0x7F) == 0x33  # add
    assert ((instr >> 7) & 0x1F) == 9
    assert ((instr >> 15) & 0x1F) == 0
    assert ((instr >> 20) & 0x1F) == 8

    is_c, illegal, instr = await apply(dut, enc_c_add(9, 8))
    assert is_c and not illegal
    assert (instr & 0x7F) == 0x33
    assert ((instr >> 7) & 0x1F) == 9
    assert ((instr >> 15) & 0x1F) == 9
    assert ((instr >> 20) & 0x1F) == 8


@cocotb.test()
async def test_c_addi4spn_legal_and_illegal(dut):
    # legal: nzuimm!=0
    c = enc_c0_addi4spn(4, 0b010)  # x10 (01_010)
    is_c, illegal, instr = await apply(dut, c)
    assert is_c and not illegal
    assert (instr & 0x7F) == 0x13
    assert ((instr >> 15) & 0x1F) == 2  # x2
    assert ((instr >> 7) & 0x1F) == 0b01010

    # illegal: zero immediate (c.addi4spn with imm=0)
    is_c, illegal, _ = await apply(dut, 0x0000)
    assert is_c and illegal


@cocotb.test()
async def test_random_compressed_smoke(dut):
    """Random halfwords: flags must be consistent; no X on outputs."""
    rng = random.Random(0xC0C0)
    for _ in range(500):
        c = rng.randint(0, 0xFFFF)
        is_c, illegal, instr = await apply(dut, c)
        assert instr == (instr & 0xFFFFFFFF)
        if (c & 0x3) == 0x3:
            assert is_c == 0 and illegal == 0
        else:
            assert is_c == 1
    # Ensure fcov bins moved
    assert FC["uncompressed"] > 0
    assert FC["quad0"] + FC["quad1"] + FC["quad2"] + FC["illegal"] > 0
    dut._log.info(f"decompress fcov bins: {FC}")
