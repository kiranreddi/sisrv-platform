"""cocotb tests for sisPmp — RV32 PMP region matcher."""
import cocotb
from cocotb.triggers import Timer

PRIV_M = 0b11
PRIV_U = 0b00

A_OFF = 0
A_TOR = 1
A_NA4 = 2
A_NAPOT = 3


def napot_mask(pa: int) -> int:
    pa &= 0xFFFFFFFF
    if pa == 0xFFFFFFFF:
        return 0xFFFFFFFF
    return ~(pa ^ (pa + 1)) & 0xFFFFFFFF


PMP_ENTRIES = 8
CFG_MASK_ALL = (1 << (PMP_ENTRIES * 8)) - 1
ADDR_MASK_ALL = (1 << (PMP_ENTRIES * 32)) - 1

_pmp_cfg_shadow = 0
_pmp_addr_shadow = 0


def entry_cfg_shift(idx: int) -> int:
    # Verilator packs [N:0][7:0] arrays with index 0 in the LSB byte.
    return idx * 8


def entry_addr_shift(idx: int) -> int:
    return idx * 32


def set_entry(dut, idx: int, cfg: int, addr: int) -> None:
    global _pmp_cfg_shadow, _pmp_addr_shadow
    cfg_shift = entry_cfg_shift(idx)
    addr_shift = entry_addr_shift(idx)
    cfg_byte_mask = 0xFF << cfg_shift
    addr_word_mask = ((1 << 32) - 1) << addr_shift
    _pmp_cfg_shadow = (_pmp_cfg_shadow & ~cfg_byte_mask) | ((cfg & 0xFF) << cfg_shift)
    _pmp_addr_shadow = (_pmp_addr_shadow & ~addr_word_mask) | ((addr & 0xFFFFFFFF) << addr_shift)
    dut.pmpcfg.value = _pmp_cfg_shadow
    dut.pmpaddr.value = _pmp_addr_shadow


def set_harness_entry0(dut) -> None:
    """Match asm tests: whole-space NAPOT on entry 0."""
    set_entry(dut, 0, 0x1F, 0x1FFF)


def clear_entries(dut, n: int = PMP_ENTRIES) -> None:
    global _pmp_cfg_shadow, _pmp_addr_shadow
    _pmp_cfg_shadow = 0
    _pmp_addr_shadow = 0
    dut.pmpcfg.value = 0
    dut.pmpaddr.value = 0


async def check_access(
    dut,
    addr: int,
    priv: int,
    req_r: int,
    req_w: int,
    req_x: int,
    expect_allow: int,
) -> None:
    dut.addr.value = addr & 0xFFFFFFFF
    dut.priv.value = priv
    dut.req_r.value = req_r
    dut.req_w.value = req_w
    dut.req_x.value = req_x
    await Timer(1, unit="ns")
    got = int(dut.allow.value)
    assert got == expect_allow, (
        f"addr=0x{addr:08x} priv={priv} r={req_r} w={req_w} x={req_x}: "
        f"expected allow={expect_allow} got={got}"
    )


@cocotb.test()
async def napot_decode_sizes(dut):
    """NAPOT sizes 8B through whole-space including all-ones pmpaddr."""
    clear_entries(dut)
    set_harness_entry0(dut)
    base = 0x80000000

    # 8-byte region (t=0): pmpaddr = 0x20000000
    set_entry(dut, 0, 0x1F, 0x1FFF)  # asm harness entry 0
    set_entry(dut, 1, 0x1B, 0x20000000)
    await check_access(dut, base, PRIV_U, 1, 1, 0, 1)
    await check_access(dut, base + 4, PRIV_U, 1, 0, 0, 1)
    await check_access(dut, base + 8, PRIV_U, 1, 0, 0, 0)

    # 16-byte region (t=1): pmpaddr = 0x20000001
    set_entry(dut, 1, 0x1B, 0x20000001)
    await check_access(dut, base + 8, PRIV_U, 1, 0, 0, 1)
    await check_access(dut, base + 16, PRIV_U, 1, 0, 0, 0)

    clear_entries(dut)
    set_entry(dut, 0, 0x1F, 0x1FFF)
    set_entry(dut, 1, 0x1F, 0x200001FF)
    await check_access(dut, base + 0x1000 - 4, PRIV_U, 0, 0, 1, 1)
    await check_access(dut, base + 0x1000, PRIV_U, 0, 0, 1, 0)

    clear_entries(dut)
    # whole-space NAPOT
    set_entry(dut, 0, 0x1F, 0xFFFFFFFF)
    await check_access(dut, 0x00000000, PRIV_U, 1, 1, 1, 1)
    await check_access(dut, 0xDEADBEEF, PRIV_U, 1, 1, 1, 1)


@cocotb.test()
async def tor_boundaries(dut):
    """TOR lower-inclusive / upper-exclusive; entry 0 lower bound is 0."""
    clear_entries(dut)
    set_entry(dut, 0, 0, 0x20000000)
    set_entry(dut, 1, (A_TOR << 3) | 0x3, 0x20000400)

    await check_access(dut, 0x80000000, PRIV_U, 1, 0, 0, 1)
    await check_access(dut, 0x80000FFC, PRIV_U, 1, 0, 0, 1)
    await check_access(dut, 0x80001000, PRIV_U, 1, 0, 0, 0)
    await check_access(dut, 0x7FFFFFFF, PRIV_U, 1, 0, 0, 0)


@cocotb.test()
async def na4_exact_word(dut):
    clear_entries(dut)
    set_harness_entry0(dut)
    set_entry(dut, 1, 0x11, 0x20000000)
    await check_access(dut, 0x80000000, PRIV_U, 1, 0, 0, 1)
    await check_access(dut, 0x80000004, PRIV_U, 1, 0, 0, 0)


@cocotb.test()
async def lowest_index_priority(dut):
    clear_entries(dut)
    set_harness_entry0(dut)
    set_entry(dut, 1, 0x19, 0x20007FFF)
    set_entry(dut, 2, 0x1B, 0x20007FFF)
    await check_access(dut, 0x80000000, PRIV_U, 0, 1, 0, 0)
    await check_access(dut, 0x80000000, PRIV_M, 0, 1, 0, 1)


@cocotb.test()
async def no_match_defaults(dut):
    clear_entries(dut)
    await check_access(dut, 0x80000000, PRIV_M, 1, 1, 1, 1)
    await check_access(dut, 0x80000000, PRIV_U, 1, 1, 1, 0)


@cocotb.test()
async def locked_enforcement_in_m(dut):
    clear_entries(dut)
    set_harness_entry0(dut)
    set_entry(dut, 1, (A_NAPOT << 3) | 0x1 | 0x80, 0x20007FFF)
    await check_access(dut, 0x80000000, PRIV_M, 0, 1, 0, 0)
    await check_access(dut, 0x80000000, PRIV_M, 1, 0, 0, 1)


@cocotb.test()
async def perm_combinations(dut):
    clear_entries(dut)
    set_harness_entry0(dut)
    set_entry(dut, 1, 0x1F, 0x20007FFF)  # R|W|X NAPOT
    await check_access(dut, 0x80000000, PRIV_U, 1, 0, 0, 1)
    await check_access(dut, 0x80000000, PRIV_U, 0, 1, 0, 1)
    await check_access(dut, 0x80000000, PRIV_U, 0, 0, 1, 1)
    await check_access(dut, 0x80000000, PRIV_U, 1, 1, 0, 1)
    await check_access(dut, 0x80000000, PRIV_U, 1, 1, 1, 1)

    clear_entries(dut)
    set_harness_entry0(dut)
    set_entry(dut, 1, 0x1D, 0x20007FFF)  # R|X NAPOT
    await check_access(dut, 0x80000000, PRIV_U, 1, 0, 0, 1)
    await check_access(dut, 0x80000000, PRIV_U, 0, 1, 0, 0)
    await check_access(dut, 0x80000000, PRIV_U, 0, 0, 1, 1)
