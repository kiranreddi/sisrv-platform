"""cocotb tests for sisRegFile — Register file verification."""
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
import random

MASK32 = 0xFFFFFFFF


@cocotb.test()
async def test_x0_always_zero(dut):
    """x0 must always read as zero regardless of write attempts."""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())

    # Try to write to x0
    dut.wr_en.value = 1
    dut.rd_addr.value = 0
    dut.rd_data.value = 0xDEADBEEF
    await RisingEdge(dut.clk)

    dut.wr_en.value = 0
    dut.rs1_addr.value = 0
    dut.rs2_addr.value = 0
    await Timer(1, units="ns")

    assert int(dut.rs1_data.value) == 0, "x0 read port A should be 0"
    assert int(dut.rs2_data.value) == 0, "x0 read port B should be 0"

    dut._log.info("x0 always zero: PASS")


@cocotb.test()
async def test_write_read_all_regs(dut):
    """Write unique values to x1..x31 and read them back."""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())

    # Write to each register
    for i in range(1, 32):
        dut.wr_en.value = 1
        dut.rd_addr.value = i
        dut.rd_data.value = (i * 0x11111111) & MASK32
        await RisingEdge(dut.clk)

    dut.wr_en.value = 0

    # Read back and verify each register via both ports
    for i in range(1, 32):
        dut.rs1_addr.value = i
        dut.rs2_addr.value = i
        await Timer(1, units="ns")
        expected = (i * 0x11111111) & MASK32
        assert int(dut.rs1_data.value) == expected, \
            f"x{i} rs1 mismatch: expected 0x{expected:08x}"
        assert int(dut.rs2_data.value) == expected, \
            f"x{i} rs2 mismatch: expected 0x{expected:08x}"

    dut._log.info("Write/read all registers: PASS")


@cocotb.test()
async def test_write_does_not_corrupt_others(dut):
    """Writing one register should not change others."""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())

    # Initialize x1..x31
    for i in range(1, 32):
        dut.wr_en.value = 1
        dut.rd_addr.value = i
        dut.rd_data.value = i
        await RisingEdge(dut.clk)

    # Overwrite x5 with new value
    dut.wr_en.value = 1
    dut.rd_addr.value = 5
    dut.rd_data.value = 0xFFFFFFFF
    await RisingEdge(dut.clk)
    dut.wr_en.value = 0

    # Check x5 changed
    dut.rs1_addr.value = 5
    await Timer(1, units="ns")
    assert int(dut.rs1_data.value) == 0xFFFFFFFF

    # Check others unchanged
    for i in range(1, 32):
        if i == 5:
            continue
        dut.rs1_addr.value = i
        await Timer(1, units="ns")
        assert int(dut.rs1_data.value) == i, \
            f"x{i} corrupted: expected {i}, got {int(dut.rs1_data.value)}"

    dut._log.info("Write isolation: PASS")


@cocotb.test()
async def test_random_read_write(dut):
    """Randomized read/write traffic."""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    random.seed(123)

    # Shadow register file (x0 always 0)
    shadow = [0] * 32

    # Initialize all registers to 0 first (avoid X values)
    for i in range(1, 32):
        dut.wr_en.value = 1
        dut.rd_addr.value = i
        dut.rd_data.value = 0
        await RisingEdge(dut.clk)
    dut.wr_en.value = 0

    for _ in range(500):
        # Random write
        addr = random.randint(0, 31)
        data = random.randint(0, MASK32)
        dut.wr_en.value = 1
        dut.rd_addr.value = addr
        dut.rd_data.value = data
        await RisingEdge(dut.clk)
        if addr != 0:
            shadow[addr] = data

        dut.wr_en.value = 0

        # Random read and check
        rs1 = random.randint(0, 31)
        rs2 = random.randint(0, 31)
        dut.rs1_addr.value = rs1
        dut.rs2_addr.value = rs2
        await Timer(1, units="ns")

        assert int(dut.rs1_data.value) == shadow[rs1], \
            f"x{rs1} mismatch: expected 0x{shadow[rs1]:08x}"
        assert int(dut.rs2_data.value) == shadow[rs2], \
            f"x{rs2} mismatch: expected 0x{shadow[rs2]:08x}"

    dut._log.info("Random read/write (500 iterations): PASS")
