"""cocotb tests for sisAxiLiteM — AXI4-Lite bridge verification."""
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer, with_timeout
import random

MASK32 = 0xFFFFFFFF


async def reset_dut(dut):
    """Apply reset to the bridge."""
    dut.rst_n.value = 0
    dut.req_valid.value = 0
    dut.req_addr.value = 0
    dut.req_we.value = 0
    dut.req_wdata.value = 0
    dut.req_wstrb.value = 0
    dut.rsp_ready.value = 0
    dut.awready.value = 0
    dut.wready.value = 0
    dut.bvalid.value = 0
    dut.bresp.value = 0
    dut.arready.value = 0
    dut.rvalid.value = 0
    dut.rdata.value = 0
    dut.rresp.value = 0
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)


async def do_read(dut, addr, stall_ar=0, stall_r=0, rdata=0xDEADBEEF, rresp=0):
    """Perform an AXI-Lite read transaction through the bridge."""
    # Issue corebus read request
    dut.req_valid.value = 1
    dut.req_addr.value = addr & MASK32
    dut.req_we.value = 0
    dut.req_wstrb.value = 0
    dut.rsp_ready.value = 1

    # Wait for req_ready
    for _ in range(100):
        await RisingEdge(dut.clk)
        if int(dut.req_ready.value) == 1:
            break
    dut.req_valid.value = 0

    # Stall before AR ready
    for _ in range(stall_ar):
        dut.arready.value = 0
        await RisingEdge(dut.clk)

    # AR handshake
    dut.arready.value = 1
    for _ in range(100):
        await RisingEdge(dut.clk)
        if int(dut.arvalid.value) == 1:
            break
    assert int(dut.arvalid.value) == 1, "ARVALID never asserted"
    assert int(dut.araddr.value) == (addr & MASK32), \
        f"ARADDR mismatch: expected 0x{addr:08x}, got 0x{int(dut.araddr.value):08x}"
    dut.arready.value = 0
    await RisingEdge(dut.clk)

    # Stall before R valid
    for _ in range(stall_r):
        dut.rvalid.value = 0
        await RisingEdge(dut.clk)

    # R data
    dut.rvalid.value = 1
    dut.rdata.value = rdata & MASK32
    dut.rresp.value = rresp

    for _ in range(100):
        await RisingEdge(dut.clk)
        if int(dut.rready.value) == 1:
            break
    dut.rvalid.value = 0
    await RisingEdge(dut.clk)

    # Wait for corebus response
    for _ in range(100):
        await RisingEdge(dut.clk)
        if int(dut.rsp_valid.value) == 1:
            break

    result = int(dut.rsp_rdata.value)
    err = int(dut.rsp_err.value)

    # Consume response
    dut.rsp_ready.value = 1
    await RisingEdge(dut.clk)
    dut.rsp_ready.value = 0

    return result, err


async def do_write(dut, addr, data, strb=0xF, stall_aw=0, stall_w=0, stall_b=0, bresp=0):
    """Perform an AXI-Lite write transaction through the bridge."""
    # Issue corebus write request
    dut.req_valid.value = 1
    dut.req_addr.value = addr & MASK32
    dut.req_we.value = 1
    dut.req_wdata.value = data & MASK32
    dut.req_wstrb.value = strb
    dut.rsp_ready.value = 1

    # Wait for req_ready
    for _ in range(100):
        await RisingEdge(dut.clk)
        if int(dut.req_ready.value) == 1:
            break
    dut.req_valid.value = 0

    # Handle AW and W channels (can complete in any order)
    aw_done = False
    w_done = False

    # Apply stalls
    dut.awready.value = 0
    dut.wready.value = 0
    for _ in range(max(stall_aw, stall_w)):
        await RisingEdge(dut.clk)

    # AW+W handshake
    for _ in range(100):
        if not aw_done:
            dut.awready.value = 1
        if not w_done:
            dut.wready.value = 1
        await RisingEdge(dut.clk)

        if not aw_done and int(dut.awvalid.value) == 1 and int(dut.awready.value) == 1:
            assert int(dut.awaddr.value) == (addr & MASK32)
            aw_done = True
            dut.awready.value = 0
        if not w_done and int(dut.wvalid.value) == 1 and int(dut.wready.value) == 1:
            assert int(dut.wdata.value) == (data & MASK32)
            assert int(dut.wstrb.value) == strb
            w_done = True
            dut.wready.value = 0

        if aw_done and w_done:
            break

    assert aw_done and w_done, "AW/W handshake failed"

    # B stall
    for _ in range(stall_b):
        dut.bvalid.value = 0
        await RisingEdge(dut.clk)

    # B response
    dut.bvalid.value = 1
    dut.bresp.value = bresp
    for _ in range(100):
        await RisingEdge(dut.clk)
        if int(dut.bready.value) == 1:
            break
    dut.bvalid.value = 0
    await RisingEdge(dut.clk)

    # Wait for corebus response
    for _ in range(100):
        await RisingEdge(dut.clk)
        if int(dut.rsp_valid.value) == 1:
            break

    err = int(dut.rsp_err.value)
    dut.rsp_ready.value = 1
    await RisingEdge(dut.clk)
    dut.rsp_ready.value = 0

    return err


@cocotb.test()
async def test_axil_reset(dut):
    """After reset, bridge should be idle with req_ready=1."""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    await reset_dut(dut)

    assert int(dut.req_ready.value) == 1, "Bridge should be ready after reset"
    assert int(dut.arvalid.value) == 0, "ARVALID should be 0 after reset"
    assert int(dut.awvalid.value) == 0, "AWVALID should be 0 after reset"
    assert int(dut.wvalid.value) == 0, "WVALID should be 0 after reset"
    assert int(dut.rsp_valid.value) == 0, "RSP_VALID should be 0 after reset"

    dut._log.info("Reset state: PASS")


@cocotb.test()
async def test_axil_basic_read(dut):
    """Basic read transaction through bridge."""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    await reset_dut(dut)

    result, err = await do_read(dut, 0x00001000, rdata=0xCAFEBABE)
    assert result == 0xCAFEBABE, f"Read data mismatch: got 0x{result:08x}"
    assert err == 0, "Unexpected error"

    dut._log.info("Basic read: PASS")


@cocotb.test()
async def test_axil_basic_write(dut):
    """Basic write transaction through bridge."""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    await reset_dut(dut)

    err = await do_write(dut, 0x80000000, 0xDEADBEEF)
    assert err == 0, "Unexpected error"

    dut._log.info("Basic write: PASS")


@cocotb.test()
async def test_axil_read_error(dut):
    """Read with DECERR (rresp=0b11) should set rsp_err."""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    await reset_dut(dut)

    result, err = await do_read(dut, 0xFFFF0000, rdata=0, rresp=0b11)
    assert err == 1, "Expected error for DECERR response"

    dut._log.info("Read error: PASS")


@cocotb.test()
async def test_axil_write_error(dut):
    """Write with SLVERR (bresp=0b10) should set rsp_err."""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    await reset_dut(dut)

    err = await do_write(dut, 0xFFFF0000, 0x12345678, bresp=0b10)
    assert err == 1, "Expected error for SLVERR response"

    dut._log.info("Write error: PASS")


@cocotb.test()
async def test_axil_stalled_read(dut):
    """Read with stalls on AR and R channels."""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    await reset_dut(dut)

    result, err = await do_read(dut, 0x00002000, stall_ar=5, stall_r=3, rdata=0xA5A5A5A5)
    assert result == 0xA5A5A5A5, f"Stalled read data mismatch: got 0x{result:08x}"
    assert err == 0

    dut._log.info("Stalled read: PASS")


@cocotb.test()
async def test_axil_stalled_write(dut):
    """Write with stalls on AW, W, and B channels."""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    await reset_dut(dut)

    err = await do_write(dut, 0x80001000, 0x5A5A5A5A, stall_aw=4, stall_w=2, stall_b=3)
    assert err == 0

    dut._log.info("Stalled write: PASS")


@cocotb.test()
async def test_axil_back_to_back(dut):
    """Multiple back-to-back transactions."""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    await reset_dut(dut)

    for i in range(10):
        if i % 2 == 0:
            result, err = await do_read(dut, i * 4, rdata=i * 0x11111111)
            assert result == (i * 0x11111111) & MASK32
        else:
            err = await do_write(dut, 0x80000000 + i * 4, i * 0x22222222)
        assert err == 0

    dut._log.info("Back-to-back (10 txns): PASS")


@cocotb.test()
async def test_axil_random_stall_stress(dut):
    """Randomized read/write stress with random stalls (100 transactions)."""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    await reset_dut(dut)

    random.seed(42)
    count = 100

    for i in range(count):
        is_write = random.choice([True, False])
        addr = random.choice([
            random.randint(0, 0x0000FFFF),       # ROM range
            random.randint(0x80000000, 0x8003FFFF), # RAM range
            0x10000000,                            # MMIO
        ])
        stall_a = random.randint(0, 5)
        stall_d = random.randint(0, 5)

        if is_write:
            data = random.randint(0, MASK32)
            stall_b = random.randint(0, 3)
            err = await do_write(dut, addr, data, stall_aw=stall_a, stall_w=stall_d, stall_b=stall_b)
        else:
            rdata = random.randint(0, MASK32)
            result, err = await do_read(dut, addr, stall_ar=stall_a, stall_r=stall_d, rdata=rdata)
            assert result == rdata, \
                f"Txn {i}: read data mismatch 0x{result:08x} vs 0x{rdata:08x}"

    dut._log.info(f"Random stall stress ({count} txns): PASS")


@cocotb.test()
async def test_axil_wstrb_variations(dut):
    """Test different write strobe patterns."""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    await reset_dut(dut)

    for strb in [0x1, 0x2, 0x4, 0x8, 0x3, 0xC, 0xF, 0x5, 0xA]:
        err = await do_write(dut, 0x80000000, 0xFFFFFFFF, strb=strb)
        assert err == 0

    dut._log.info("Write strobe variations: PASS")


@cocotb.test()
async def test_axil_valid_stability(dut):
    """Verify ARVALID stays high until ARREADY (handshake compliance)."""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    await reset_dut(dut)

    # Issue read request
    dut.req_valid.value = 1
    dut.req_addr.value = 0x00001000
    dut.req_we.value = 0
    dut.rsp_ready.value = 1
    dut.arready.value = 0  # Don't accept AR yet

    # Wait for bridge to enter read state
    for _ in range(10):
        await RisingEdge(dut.clk)
        if int(dut.req_ready.value) == 1:
            dut.req_valid.value = 0
            break

    # ARVALID should be asserted and stay high while ARREADY is low
    saw_arvalid = False
    for cycle in range(10):
        await RisingEdge(dut.clk)
        if int(dut.arvalid.value) == 1:
            saw_arvalid = True
        if saw_arvalid:
            assert int(dut.arvalid.value) == 1, \
                f"ARVALID dropped before ARREADY at cycle {cycle}"

    assert saw_arvalid, "ARVALID was never asserted"

    # Complete the transaction
    dut.arready.value = 1
    await RisingEdge(dut.clk)
    dut.arready.value = 0
    await RisingEdge(dut.clk)
    dut.rvalid.value = 1
    dut.rdata.value = 0
    dut.rresp.value = 0
    for _ in range(10):
        await RisingEdge(dut.clk)
        if int(dut.rready.value) == 1:
            break
    dut.rvalid.value = 0
    for _ in range(10):
        await RisingEdge(dut.clk)
        if int(dut.rsp_valid.value) == 1:
            break
    await RisingEdge(dut.clk)

    dut._log.info("VALID stability: PASS")
