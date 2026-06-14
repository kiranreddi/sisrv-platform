"""cocotb tests for sisCsr — CSR unit verification."""
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
import random

MASK32 = 0xFFFFFFFF

# CSR addresses
CSR_MSTATUS  = 0x300
CSR_MISA     = 0x301
CSR_MIE      = 0x304
CSR_MTVEC    = 0x305
CSR_MCOUNTINHIBIT = 0x320
CSR_MSCRATCH = 0x340
CSR_MEPC     = 0x341
CSR_MCAUSE   = 0x342
CSR_MTVAL    = 0x343
CSR_MIP      = 0x344
CSR_MCYCLE   = 0xB00
CSR_MINSTRET = 0xB02
CSR_MCYCLEH  = 0xB80
CSR_MINSTRETH = 0xB82
CSR_MVENDORID = 0xF11
CSR_MARCHID   = 0xF12
CSR_MIMPID    = 0xF13
CSR_MHARTID   = 0xF14
CSR_MCONFIGPTR = 0xF15

# MIP is read-only (MTIP is driven by ext_mtip).
RW_CSRS = [CSR_MSTATUS, CSR_MIE, CSR_MTVEC, CSR_MCOUNTINHIBIT, CSR_MSCRATCH,
           CSR_MEPC, CSR_MCAUSE, CSR_MTVAL, CSR_MCYCLE, CSR_MCYCLEH,
           CSR_MINSTRET, CSR_MINSTRETH]
RO_CSRS = [CSR_MISA, CSR_MIP, CSR_MVENDORID, CSR_MARCHID, CSR_MIMPID,
           CSR_MHARTID, CSR_MCONFIGPTR]
ALL_CSRS = RW_CSRS + RO_CSRS

CSR_NAMES = {
    CSR_MSTATUS: "mstatus", CSR_MISA: "misa", CSR_MIE: "mie", CSR_MTVEC: "mtvec",
    CSR_MCOUNTINHIBIT: "mcountinhibit",
    CSR_MSCRATCH: "mscratch", CSR_MEPC: "mepc", CSR_MCAUSE: "mcause",
    CSR_MTVAL: "mtval", CSR_MIP: "mip",
    CSR_MCYCLE: "mcycle", CSR_MCYCLEH: "mcycleh",
    CSR_MINSTRET: "minstret", CSR_MINSTRETH: "minstreth",
    CSR_MVENDORID: "mvendorid", CSR_MARCHID: "marchid",
    CSR_MIMPID: "mimpid", CSR_MHARTID: "mhartid", CSR_MCONFIGPTR: "mconfigptr",
}

# CSR operations
CSR_OP_NONE = 0b00
CSR_OP_RW   = 0b01
CSR_OP_RS   = 0b10  # set bits
CSR_OP_RC   = 0b11  # clear bits


async def reset_dut(dut):
    """Apply reset to the CSR unit."""
    dut.rst_n.value = 0
    dut.csr_addr.value = 0
    dut.csr_wdata.value = 0
    dut.csr_op.value = 0
    dut.csr_wen.value = 0
    dut.trap_enter.value = 0
    dut.trap_cause.value = 0
    dut.trap_val.value = 0
    dut.trap_epc.value = 0
    dut.mret_exec.value = 0
    dut.instr_retire.value = 0
    dut.ext_mtip.value = 0
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)


async def csr_read(dut, addr):
    """Combinational read of a CSR (no clock edge needed)."""
    dut.csr_addr.value = addr
    dut.csr_op.value = CSR_OP_NONE
    dut.csr_wen.value = 0
    await Timer(1, units="ns")
    return int(dut.csr_rdata.value)


async def csr_write(dut, addr, data, op=CSR_OP_RW):
    """Write to a CSR on the next clock edge."""
    dut.csr_addr.value = addr
    dut.csr_wdata.value = data & MASK32
    dut.csr_op.value = op
    dut.csr_wen.value = 1
    await RisingEdge(dut.clk)
    dut.csr_wen.value = 0


@cocotb.test()
async def test_csr_reset_values(dut):
    """After reset, all CSRs should read as 0."""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    await reset_dut(dut)

    expected_reset = {CSR_MISA: 0x40001100}
    for addr in ALL_CSRS:
        if addr in (CSR_MCYCLE, CSR_MCYCLEH, CSR_MINSTRET, CSR_MINSTRETH):
            continue
        val = await csr_read(dut, addr)
        expected = expected_reset.get(addr, 0)
        assert val == expected, \
            f"{CSR_NAMES[addr]} after reset: expected 0x{expected:08x}, got 0x{val:08x}"

    dut._log.info("CSR reset values: PASS")


@cocotb.test()
async def test_csr_rw_all(dut):
    """CSRRW: write and read back all CSRs."""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    await reset_dut(dut)

    test_val = 0xDEADBEEF
    for addr in RW_CSRS:
        await csr_write(dut, addr, test_val, CSR_OP_RW)
        got = await csr_read(dut, addr)
        if addr == CSR_MEPC:
            expected = test_val & 0xFFFFFFFC  # word-aligned
        elif addr in (CSR_MCYCLE, CSR_MCYCLEH, CSR_MINSTRET, CSR_MINSTRETH):
            expected = test_val
        else:
            expected = test_val
        assert got == expected, \
            f"{CSR_NAMES[addr]}: expected 0x{expected:08x}, got 0x{got:08x}"

    dut._log.info("CSR RW all: PASS")


@cocotb.test()
async def test_csr_rs_set_bits(dut):
    """CSRRS: set bits operation."""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    await reset_dut(dut)

    # Write initial value
    await csr_write(dut, CSR_MSCRATCH, 0x0000FF00, CSR_OP_RW)

    # Set additional bits
    await csr_write(dut, CSR_MSCRATCH, 0x00FF0000, CSR_OP_RS)

    got = await csr_read(dut, CSR_MSCRATCH)
    assert got == 0x00FFFF00, \
        f"CSRRS: expected 0x00FFFF00, got 0x{got:08x}"

    dut._log.info("CSR RS (set bits): PASS")


@cocotb.test()
async def test_csr_rc_clear_bits(dut):
    """CSRRC: clear bits operation."""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    await reset_dut(dut)

    # Write initial value
    await csr_write(dut, CSR_MSCRATCH, 0xFFFFFFFF, CSR_OP_RW)

    # Clear some bits
    await csr_write(dut, CSR_MSCRATCH, 0x0F0F0F0F, CSR_OP_RC)

    got = await csr_read(dut, CSR_MSCRATCH)
    assert got == 0xF0F0F0F0, \
        f"CSRRC: expected 0xF0F0F0F0, got 0x{got:08x}"

    dut._log.info("CSR RC (clear bits): PASS")


@cocotb.test()
async def test_csr_unknown_reads_zero(dut):
    """Reading an unimplemented CSR address should return 0."""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    await reset_dut(dut)

    # Write a non-zero value to mscratch to confirm reads from other CSRs are 0
    await csr_write(dut, CSR_MSCRATCH, 0xDEADBEEF, CSR_OP_RW)

    for unknown_addr in [0x000, 0x001, 0x100, 0xFFF, 0x306, 0xB01]:
        got = await csr_read(dut, unknown_addr)
        assert got == 0, \
            f"Unknown CSR 0x{unknown_addr:03x}: expected 0, got 0x{got:08x}"

    dut._log.info("Unknown CSR reads zero: PASS")


@cocotb.test()
async def test_csr_trap_entry(dut):
    """Verify trap entry saves mepc, mcause, mtval and updates mstatus."""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    await reset_dut(dut)

    # Set MIE bit (bit 3) in mstatus
    await csr_write(dut, CSR_MSTATUS, 0x00000008, CSR_OP_RW)

    # Trigger trap
    dut.trap_enter.value = 1
    dut.trap_cause.value = 11  # ECALL from M-mode
    dut.trap_val.value = 0x12345678
    dut.trap_epc.value = 0x00001000
    await RisingEdge(dut.clk)
    dut.trap_enter.value = 0

    # Check saved state
    mepc = await csr_read(dut, CSR_MEPC)
    mcause = await csr_read(dut, CSR_MCAUSE)
    mtval = await csr_read(dut, CSR_MTVAL)
    mstatus = await csr_read(dut, CSR_MSTATUS)

    assert mepc == 0x00001000, f"mepc: expected 0x00001000, got 0x{mepc:08x}"
    assert mcause == 11, f"mcause: expected 11, got {mcause}"
    assert mtval == 0x12345678, f"mtval: expected 0x12345678, got 0x{mtval:08x}"

    # mstatus: MPIE (bit 7) = old MIE (1), MIE (bit 3) = 0
    assert (mstatus >> 7) & 1 == 1, "MPIE should be 1 (was MIE=1)"
    assert (mstatus >> 3) & 1 == 0, "MIE should be 0 after trap"

    dut._log.info("Trap entry: PASS")


@cocotb.test()
async def test_csr_mret(dut):
    """Verify MRET restores MIE from MPIE, sets MPIE=1."""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    await reset_dut(dut)

    # Set MIE=1
    await csr_write(dut, CSR_MSTATUS, 0x00000008, CSR_OP_RW)

    # Enter trap (MIE→MPIE, MIE=0)
    dut.trap_enter.value = 1
    dut.trap_cause.value = 3  # breakpoint
    dut.trap_epc.value = 0x00002000
    dut.trap_val.value = 0
    await RisingEdge(dut.clk)
    dut.trap_enter.value = 0

    # Verify MIE=0, MPIE=1
    mstatus = await csr_read(dut, CSR_MSTATUS)
    assert (mstatus >> 3) & 1 == 0, "MIE should be 0 after trap"
    assert (mstatus >> 7) & 1 == 1, "MPIE should be 1"

    # Execute MRET
    dut.mret_exec.value = 1
    await RisingEdge(dut.clk)
    dut.mret_exec.value = 0

    # Verify MIE restored from MPIE (1), MPIE=1
    mstatus = await csr_read(dut, CSR_MSTATUS)
    assert (mstatus >> 3) & 1 == 1, "MIE should be restored to 1 after MRET"
    assert (mstatus >> 7) & 1 == 1, "MPIE should be 1 after MRET"

    dut._log.info("MRET: PASS")


@cocotb.test()
async def test_csr_mepc_word_aligned(dut):
    """MEPC should always be word-aligned (lower 2 bits cleared)."""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    await reset_dut(dut)

    for val in [0x00000001, 0x00000002, 0x00000003, 0xFFFFFFFF, 0xDEADBEEF]:
        await csr_write(dut, CSR_MEPC, val, CSR_OP_RW)
        got = await csr_read(dut, CSR_MEPC)
        expected = val & 0xFFFFFFFC
        assert got == expected, \
            f"MEPC: wrote 0x{val:08x}, expected 0x{expected:08x}, got 0x{got:08x}"

    dut._log.info("MEPC word alignment: PASS")


@cocotb.test()
async def test_csr_mtvec_output(dut):
    """Verify mtvec_out reflects the mtvec register."""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    await reset_dut(dut)

    await csr_write(dut, CSR_MTVEC, 0x80000000, CSR_OP_RW)
    await Timer(1, units="ns")
    assert int(dut.mtvec_out.value) == 0x80000000

    dut._log.info("mtvec_out: PASS")


@cocotb.test()
async def test_csr_mepc_output(dut):
    """Verify mepc_out reflects the mepc register."""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    await reset_dut(dut)

    await csr_write(dut, CSR_MEPC, 0x00004000, CSR_OP_RW)
    await Timer(1, units="ns")
    assert int(dut.mepc_out.value) == 0x00004000

    dut._log.info("mepc_out: PASS")


@cocotb.test()
async def test_csr_mtip_irq_pending(dut):
    """Verify ext_mtip reflects in mip and irq_pending works."""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    await reset_dut(dut)

    # Initially no interrupt
    await Timer(1, units="ns")
    assert int(dut.irq_pending.value) == 0, "No interrupt should be pending"

    # Set ext_mtip=1 but MIE=0 and MTIE=0
    dut.ext_mtip.value = 1
    await Timer(1, units="ns")
    assert int(dut.irq_pending.value) == 0, "IRQ should not be pending (MIE=0, MTIE=0)"

    # Enable MTIE (mie bit 7)
    await csr_write(dut, CSR_MIE, 0x00000080, CSR_OP_RW)
    await Timer(1, units="ns")
    assert int(dut.irq_pending.value) == 0, "IRQ should not be pending (MIE=0)"

    # Enable MIE (mstatus bit 3)
    await csr_write(dut, CSR_MSTATUS, 0x00000008, CSR_OP_RW)
    await Timer(1, units="ns")
    assert int(dut.irq_pending.value) == 1, "IRQ should be pending (MIE=1, MTIE=1, MTIP=1)"

    # Read mip — bit 7 should reflect ext_mtip
    mip = await csr_read(dut, CSR_MIP)
    assert (mip >> 7) & 1 == 1, "mip.MTIP should be 1"

    # Clear ext_mtip
    dut.ext_mtip.value = 0
    await Timer(1, units="ns")
    assert int(dut.irq_pending.value) == 0, "IRQ should not be pending (MTIP=0)"

    dut._log.info("MTIP/irq_pending: PASS")


@cocotb.test()
async def test_csr_id_registers(dut):
    """Verify machine ID CSRs expose stable product-visible values."""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    await reset_dut(dut)

    misa = await csr_read(dut, CSR_MISA)
    assert misa == 0x40001100, f"misa expected RV32IM 0x40001100, got 0x{misa:08x}"

    for addr in [CSR_MVENDORID, CSR_MARCHID, CSR_MIMPID, CSR_MHARTID, CSR_MCONFIGPTR]:
        got = await csr_read(dut, addr)
        assert got == 0, f"{CSR_NAMES[addr]} expected 0, got 0x{got:08x}"

    dut._log.info("ID CSRs: PASS")


@cocotb.test()
async def test_csr_counters_and_inhibit(dut):
    """Verify mcycle/minstret count and mcountinhibit can stop them."""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    await reset_dut(dut)

    c0 = await csr_read(dut, CSR_MCYCLE)
    await RisingEdge(dut.clk)
    c1 = await csr_read(dut, CSR_MCYCLE)
    assert c1 > c0, f"mcycle should increment: before={c0} after={c1}"

    i0 = await csr_read(dut, CSR_MINSTRET)
    dut.instr_retire.value = 1
    await RisingEdge(dut.clk)
    dut.instr_retire.value = 0
    i1 = await csr_read(dut, CSR_MINSTRET)
    assert i1 == i0 + 1, f"minstret expected {i0 + 1}, got {i1}"

    await csr_write(dut, CSR_MCOUNTINHIBIT, 0x5, CSR_OP_RW)
    c_hold = await csr_read(dut, CSR_MCYCLE)
    i_hold = await csr_read(dut, CSR_MINSTRET)
    dut.instr_retire.value = 1
    for _ in range(3):
        await RisingEdge(dut.clk)
    dut.instr_retire.value = 0
    assert await csr_read(dut, CSR_MCYCLE) == c_hold, "mcycle should stop when CY is inhibited"
    assert await csr_read(dut, CSR_MINSTRET) == i_hold, "minstret should stop when IR is inhibited"

    dut._log.info("Counters and mcountinhibit: PASS")


@cocotb.test()
async def test_csr_sync_exception_traps(dut):
    """Verify CSR trap entry records synchronous exception causes and mtval."""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    await reset_dut(dut)

    cases = [
        ("instr addr misaligned", 0, 0x00000082, 0x00000080),
        ("instr access fault", 1, 0x20000000, 0x20000000),
        ("load addr misaligned", 4, 0x80000002, 0x00000100),
        ("load access fault", 5, 0x20000000, 0x00000104),
        ("store addr misaligned", 6, 0x80000001, 0x00000108),
        ("store access fault", 7, 0x20000000, 0x0000010C),
    ]

    for name, cause, mtval, epc in cases:
        dut.trap_enter.value = 1
        dut.trap_cause.value = cause
        dut.trap_val.value = mtval
        dut.trap_epc.value = epc
        await RisingEdge(dut.clk)
        dut.trap_enter.value = 0

        got_cause = await csr_read(dut, CSR_MCAUSE)
        got_mtval = await csr_read(dut, CSR_MTVAL)
        got_mepc = await csr_read(dut, CSR_MEPC)

        assert got_cause == cause, \
            f"{name}: mcause expected {cause}, got {got_cause}"
        assert got_mtval == mtval, \
            f"{name}: mtval expected 0x{mtval:08x}, got 0x{got_mtval:08x}"
        assert got_mepc == epc, \
            f"{name}: mepc expected 0x{epc:08x}, got 0x{got_mepc:08x}"

    dut._log.info("Synchronous exception trap causes: PASS")
