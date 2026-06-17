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


def set_entry(dut, idx: int, cfg: int, addr: int) -> None:
    dut.pmpcfg[idx].value = cfg & 0xFF
    dut.pmpaddr[idx].value = addr & 0xFFFFFFFF


def clear_entries(dut, n: int = 8) -> None:
    for i in range(n):
        set_entry(dut, i, 0, 0)


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
    base = 0x80000000

  # 8-byte region
    set_entry(dut, 0, (A_NAPOT << 3) | 0x7, 0x20000001)
    await check_access(dut, base, PRIV_U, 1, 1, 1, 1)
    await check_access(dut, base + 4, PRIV_U, 1, 0, 0, 1)
    await check_access(dut, base + 8, PRIV_U, 1, 0, 0, 0)

  # 4KB region
    set_entry(dut, 0, (A_NAPOT << 3) | 0x7, 0x200001FF)
    await check_access(dut, base + 0x1000 - 4, PRIV_U, 0, 0, 1, 1)
    await check_access(dut, base + 0x1000, PRIV_U, 0, 0, 1, 0)

  # whole-space NAPOT
    set_entry(dut, 0, (A_NAPOT << 3) | 0x7, 0xFFFFFFFF)
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
    set_entry(dut, 0, (A_NA4 << 3) | 0x3, 0x20000000)
    await check_access(dut, 0x80000000, PRIV_U, 1, 1, 0, 1)
    await check_access(dut, 0x80000004, PRIV_U, 1, 0, 0, 0)


@cocotb.test()
async def lowest_index_priority(dut):
    clear_entries(dut)
    set_entry(dut, 0, (A_NAPOT << 3) | 0x1, 0x20007FFF)
    set_entry(dut, 1, (A_NAPOT << 3) | 0x3, 0x20007FFF)
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
    set_entry(dut, 0, (A_NAPOT << 3) | 0x1 | 0x80, 0x20007FFF)
    await check_access(dut, 0x80000000, PRIV_M, 0, 1, 0, 0)
    await check_access(dut, 0x80000000, PRIV_M, 1, 0, 0, 1)


@cocotb.test()
async def perm_combinations(dut):
    clear_entries(dut)
    set_entry(dut, 0, (A_NAPOT << 3) | 0x5, 0x20007FFF)
    await check_access(dut, 0x80000000, PRIV_U, 1, 0, 0, 1)
    await check_access(dut, 0x80000000, PRIV_U, 0, 1, 0, 1)
    await check_access(dut, 0x80000000, PRIV_U, 0, 0, 1, 0)
    await check_access(dut, 0x80000000, PRIV_U, 1, 1, 0, 1)
    await check_access(dut, 0x80000000, PRIV_U, 1, 1, 1, 1)
