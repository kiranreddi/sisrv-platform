"""cocotb tests for sisAlu — Randomized ALU verification."""
import cocotb
from cocotb.triggers import Timer
import random

# ALU operation encoding (matches sisAlu.sv)
ALU_ADD  = 0b0000
ALU_SUB  = 0b1000
ALU_SLL  = 0b0001
ALU_SLT  = 0b0010
ALU_SLTU = 0b0011
ALU_XOR  = 0b0100
ALU_SRL  = 0b0101
ALU_SRA  = 0b1101
ALU_OR   = 0b0110
ALU_AND  = 0b0111

MASK32 = 0xFFFFFFFF


def to_signed32(val):
    """Convert unsigned 32-bit to signed Python int."""
    val &= MASK32
    return val if val < 0x80000000 else val - 0x100000000


def alu_ref(a, b, op):
    """Reference model for ALU operations."""
    a &= MASK32
    b &= MASK32
    if op == ALU_ADD:
        return (a + b) & MASK32
    elif op == ALU_SUB:
        return (a - b) & MASK32
    elif op == ALU_SLL:
        return (a << (b & 0x1F)) & MASK32
    elif op == ALU_SLT:
        return 1 if to_signed32(a) < to_signed32(b) else 0
    elif op == ALU_SLTU:
        return 1 if a < b else 0
    elif op == ALU_XOR:
        return (a ^ b) & MASK32
    elif op == ALU_SRL:
        return (a >> (b & 0x1F)) & MASK32
    elif op == ALU_SRA:
        sa = to_signed32(a)
        return (sa >> (b & 0x1F)) & MASK32
    elif op == ALU_OR:
        return (a | b) & MASK32
    elif op == ALU_AND:
        return (a & b) & MASK32
    else:
        return 0


ALL_OPS = [ALU_ADD, ALU_SUB, ALU_SLL, ALU_SLT, ALU_SLTU,
           ALU_XOR, ALU_SRL, ALU_SRA, ALU_OR, ALU_AND]

OP_NAMES = {
    ALU_ADD: "ADD", ALU_SUB: "SUB", ALU_SLL: "SLL",
    ALU_SLT: "SLT", ALU_SLTU: "SLTU", ALU_XOR: "XOR",
    ALU_SRL: "SRL", ALU_SRA: "SRA", ALU_OR: "OR", ALU_AND: "AND",
}


async def apply_and_check(dut, a, b, op):
    """Apply inputs and check result after a small delay."""
    dut.a.value = a & MASK32
    dut.b.value = b & MASK32
    dut.op.value = op
    await Timer(1, unit="ns")

    expected = alu_ref(a, b, op)
    result = int(dut.result.value)
    exp_zero = 1 if expected == 0 else 0
    got_zero = int(dut.zero.value)

    assert result == expected, (
        f"ALU {OP_NAMES.get(op, '?')}: a=0x{a:08x} b=0x{b:08x} "
        f"expected=0x{expected:08x} got=0x{result:08x}"
    )
    assert got_zero == exp_zero, (
        f"ALU {OP_NAMES.get(op, '?')}: zero flag mismatch "
        f"expected={exp_zero} got={got_zero}"
    )


@cocotb.test()
async def test_alu_directed(dut):
    """Directed test: edge-case values for all ALU operations."""
    edge_values = [0, 1, 2, 0x7FFFFFFF, 0x80000000, 0xFFFFFFFF,
                   0x12345678, 0xDEADBEEF, 0x00FF00FF, 0xFF00FF00]

    count = 0
    for op in ALL_OPS:
        for a in edge_values:
            for b in edge_values:
                await apply_and_check(dut, a, b, op)
                count += 1

    dut._log.info(f"Directed tests passed: {count} checks")


@cocotb.test()
async def test_alu_random(dut):
    """Randomized test: random operands and operations."""
    random.seed(42)  # Reproducible
    count = 1000

    for _ in range(count):
        a = random.randint(0, MASK32)
        b = random.randint(0, MASK32)
        op = random.choice(ALL_OPS)
        await apply_and_check(dut, a, b, op)

    dut._log.info(f"Random tests passed: {count} checks")


@cocotb.test()
async def test_alu_shift_all_amounts(dut):
    """Test all 32 shift amounts for SLL, SRL, SRA."""
    for shamt in range(32):
        for a in [0x80000001, 0x7FFFFFFF, 0xAAAAAAAA, 0x55555555, 1]:
            for op in [ALU_SLL, ALU_SRL, ALU_SRA]:
                await apply_and_check(dut, a, shamt, op)

    dut._log.info("Shift amount sweep passed")
