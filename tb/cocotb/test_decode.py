"""cocotb tests for sisDecode — Instruction decoder verification."""
import cocotb
from cocotb.triggers import Timer
import random

MASK32 = 0xFFFFFFFF


def sign_extend(val, bits):
    """Sign-extend a value from `bits` width to 32 bits."""
    if val & (1 << (bits - 1)):
        return val | (MASK32 << bits) & MASK32
    return val & MASK32


def encode_r(funct7, rs2, rs1, funct3, rd, opcode):
    return (funct7 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode


def encode_i(imm12, rs1, funct3, rd, opcode):
    return ((imm12 & 0xFFF) << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode


def encode_s(imm12, rs2, rs1, funct3, opcode):
    imm11_5 = (imm12 >> 5) & 0x7F
    imm4_0 = imm12 & 0x1F
    return (imm11_5 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (imm4_0 << 7) | opcode


def encode_b(imm13, rs2, rs1, funct3, opcode):
    """imm13 is 13-bit signed offset (bit 0 always 0)."""
    b12 = (imm13 >> 12) & 1
    b11 = (imm13 >> 11) & 1
    b10_5 = (imm13 >> 5) & 0x3F
    b4_1 = (imm13 >> 1) & 0xF
    return (b12 << 31) | (b10_5 << 25) | (rs2 << 20) | (rs1 << 15) | \
           (funct3 << 12) | (b4_1 << 8) | (b11 << 7) | opcode


def encode_u(imm20, rd, opcode):
    return ((imm20 & 0xFFFFF) << 12) | (rd << 7) | opcode


def encode_j(imm21, rd, opcode):
    """imm21 is 21-bit signed offset (bit 0 always 0)."""
    b20 = (imm21 >> 20) & 1
    b19_12 = (imm21 >> 12) & 0xFF
    b11 = (imm21 >> 11) & 1
    b10_1 = (imm21 >> 1) & 0x3FF
    return (b20 << 31) | (b10_1 << 21) | (b11 << 20) | (b19_12 << 12) | (rd << 7) | opcode


# RV32I opcode constants
OP_LUI     = 0b0110111
OP_AUIPC   = 0b0010111
OP_JAL     = 0b1101111
OP_JALR    = 0b1100111
OP_BRANCH  = 0b1100011
OP_LOAD    = 0b0000011
OP_STORE   = 0b0100011
OP_ALU_IMM = 0b0010011
OP_ALU_REG = 0b0110011
OP_FENCE   = 0b0001111
OP_SYSTEM  = 0b1110011

LEGAL_OPCODES = [OP_LUI, OP_AUIPC, OP_JAL, OP_JALR, OP_BRANCH,
                 OP_LOAD, OP_STORE, OP_ALU_IMM, OP_ALU_REG, OP_FENCE, OP_SYSTEM]


@cocotb.test()
async def test_decode_type_flags(dut):
    """Verify that each legal opcode sets exactly one type flag."""
    type_flags = {
        OP_LUI:     "is_lui",
        OP_AUIPC:   "is_auipc",
        OP_JAL:     "is_jal",
        OP_JALR:    "is_jalr",
        OP_BRANCH:  "is_branch",
        OP_LOAD:    "is_load",
        OP_STORE:   "is_store",
        OP_ALU_IMM: "is_alu_imm",
        OP_ALU_REG: "is_alu_reg",
        OP_FENCE:   "is_fence",
        OP_SYSTEM:  "is_system",
    }

    all_flags = list(type_flags.values())

    for opcode, expected_flag in type_flags.items():
        # Minimal valid instruction with this opcode
        instr = opcode  # rd=0, funct3=0, rs1=0, etc.
        dut.instr.value = instr
        await Timer(1, units="ns")

        # Check expected flag is set
        assert int(getattr(dut, expected_flag).value) == 1, \
            f"Opcode 0x{opcode:02x}: {expected_flag} should be 1"

        # Check all other flags are clear
        for flag in all_flags:
            if flag != expected_flag:
                assert int(getattr(dut, flag).value) == 0, \
                    f"Opcode 0x{opcode:02x}: {flag} should be 0 but is 1"

        # Check legality
        assert int(dut.is_legal.value) == 1, \
            f"Opcode 0x{opcode:02x} should be legal"

    dut._log.info("Type flag decode: PASS (all 11 opcodes)")


@cocotb.test()
async def test_decode_illegal_opcodes(dut):
    """Verify that illegal opcodes are flagged as illegal."""
    count = 0
    for opcode in range(128):
        if opcode in LEGAL_OPCODES:
            continue
        instr = opcode  # all other fields zero
        dut.instr.value = instr
        await Timer(1, units="ns")

        assert int(dut.is_legal.value) == 0, \
            f"Opcode 0x{opcode:02x} should be illegal but is_legal=1"
        count += 1

    dut._log.info(f"Illegal opcode detection: PASS ({count} illegal opcodes tested)")


@cocotb.test()
async def test_decode_register_extraction(dut):
    """Verify rs1, rs2, rd extraction from instruction fields."""
    for rd_val in [0, 1, 15, 31]:
        for rs1_val in [0, 1, 15, 31]:
            for rs2_val in [0, 1, 15, 31]:
                instr = encode_r(0, rs2_val, rs1_val, 0, rd_val, OP_ALU_REG)
                dut.instr.value = instr
                await Timer(1, units="ns")

                assert int(dut.rd.value) == rd_val, \
                    f"rd: expected {rd_val}, got {int(dut.rd.value)}"
                assert int(dut.rs1.value) == rs1_val, \
                    f"rs1: expected {rs1_val}, got {int(dut.rs1.value)}"
                assert int(dut.rs2.value) == rs2_val, \
                    f"rs2: expected {rs2_val}, got {int(dut.rs2.value)}"

    dut._log.info("Register extraction: PASS")


@cocotb.test()
async def test_decode_imm_i(dut):
    """Verify I-type immediate extraction and sign extension."""
    test_cases = [
        (0x000, 0x00000000),   # zero
        (0x001, 0x00000001),   # +1
        (0x7FF, 0x000007FF),   # max positive (2047)
        (0x800, 0xFFFFF800),   # -2048 (sign bit set)
        (0xFFF, 0xFFFFFFFF),   # -1
        (0x555, 0x00000555),   # positive pattern
        (0xAAA, 0xFFFFFAAA),   # negative pattern
    ]
    for imm12, expected in test_cases:
        instr = encode_i(imm12, 0, 0, 0, OP_ALU_IMM)
        dut.instr.value = instr
        await Timer(1, units="ns")
        got = int(dut.imm_i.value)
        assert got == expected, \
            f"I-imm: imm12=0x{imm12:03x} expected=0x{expected:08x} got=0x{got:08x}"

    dut._log.info("I-type immediate: PASS")


@cocotb.test()
async def test_decode_imm_s(dut):
    """Verify S-type immediate extraction and sign extension."""
    test_cases = [
        (0x000, 0x00000000),
        (0x001, 0x00000001),
        (0x7FF, 0x000007FF),
        (0x800, 0xFFFFF800),
        (0xFFF, 0xFFFFFFFF),
    ]
    for imm12, expected in test_cases:
        instr = encode_s(imm12, 0, 0, 0, OP_STORE)
        dut.instr.value = instr
        await Timer(1, units="ns")
        got = int(dut.imm_s.value)
        assert got == expected, \
            f"S-imm: imm12=0x{imm12:03x} expected=0x{expected:08x} got=0x{got:08x}"

    dut._log.info("S-type immediate: PASS")


@cocotb.test()
async def test_decode_imm_u(dut):
    """Verify U-type immediate (upper 20 bits, lower 12 zeroed)."""
    test_cases = [
        (0x00000, 0x00000000),
        (0x00001, 0x00001000),
        (0x12345, 0x12345000),
        (0xFFFFF, 0xFFFFF000),
        (0x80000, 0x80000000),
    ]
    for imm20, expected in test_cases:
        instr = encode_u(imm20, 1, OP_LUI)
        dut.instr.value = instr
        await Timer(1, units="ns")
        got = int(dut.imm_u.value)
        assert got == expected, \
            f"U-imm: imm20=0x{imm20:05x} expected=0x{expected:08x} got=0x{got:08x}"

    dut._log.info("U-type immediate: PASS")


@cocotb.test()
async def test_decode_imm_b(dut):
    """Verify B-type immediate extraction (13-bit signed, bit[0]=0)."""
    # B-immediate: {instr[31], instr[7], instr[30:25], instr[11:8], 1'b0}
    test_cases = [
        (0x0000, 0x00000000),   # zero offset
        (0x0002, 0x00000002),   # +2
        (0x0FFE, 0x00000FFE),   # max positive-ish
        (0x1000, 0xFFFFF000),   # -4096 (sign bit set in 13-bit)
        (0x1FFE, 0xFFFFFFFE),   # -2
    ]
    for imm13, expected in test_cases:
        instr = encode_b(imm13, 0, 0, 0, OP_BRANCH)
        dut.instr.value = instr
        await Timer(1, units="ns")
        got = int(dut.imm_b.value)
        assert got == expected, \
            f"B-imm: imm13=0x{imm13:04x} expected=0x{expected:08x} got=0x{got:08x}"

    dut._log.info("B-type immediate: PASS")


@cocotb.test()
async def test_decode_imm_j(dut):
    """Verify J-type immediate extraction (21-bit signed, bit[0]=0)."""
    # J-immediate: {instr[31], instr[19:12], instr[20], instr[30:21], 1'b0}
    test_cases = [
        (0x000000, 0x00000000),   # zero
        (0x000002, 0x00000002),   # +2
        (0x0FFFFE, 0x000FFFFE),   # large positive
        (0x100000, 0xFFF00000),   # -1048576 (sign bit)
        (0x1FFFFE, 0xFFFFFFFE),   # -2
    ]
    for imm21, expected in test_cases:
        instr = encode_j(imm21, 1, OP_JAL)
        dut.instr.value = instr
        await Timer(1, units="ns")
        got = int(dut.imm_j.value)
        assert got == expected, \
            f"J-imm: imm21=0x{imm21:06x} expected=0x{expected:08x} got=0x{got:08x}"

    dut._log.info("J-type immediate: PASS")


@cocotb.test()
async def test_decode_funct_fields(dut):
    """Verify funct3 and funct7 extraction."""
    for f3 in range(8):
        for f7 in [0x00, 0x20, 0x7F]:
            instr = encode_r(f7, 0, 0, f3, 0, OP_ALU_REG)
            dut.instr.value = instr
            await Timer(1, units="ns")
            assert int(dut.funct3.value) == f3, \
                f"funct3: expected {f3}, got {int(dut.funct3.value)}"
            assert int(dut.funct7.value) == f7, \
                f"funct7: expected 0x{f7:02x}, got 0x{int(dut.funct7.value):02x}"

    dut._log.info("funct3/funct7 extraction: PASS")


@cocotb.test()
async def test_decode_random_instructions(dut):
    """Randomized decoder test with 1000 random instructions."""
    random.seed(99)
    count = 0

    for _ in range(1000):
        instr = random.randint(0, MASK32)
        dut.instr.value = instr
        await Timer(1, units="ns")

        opcode = instr & 0x7F
        expected_legal = 1 if opcode in LEGAL_OPCODES else 0
        got_legal = int(dut.is_legal.value)
        assert got_legal == expected_legal, \
            f"instr=0x{instr:08x} opcode=0x{opcode:02x}: " \
            f"is_legal expected={expected_legal} got={got_legal}"

        # Verify register field extraction
        assert int(dut.rd.value) == (instr >> 7) & 0x1F
        assert int(dut.rs1.value) == (instr >> 15) & 0x1F
        assert int(dut.rs2.value) == (instr >> 20) & 0x1F
        assert int(dut.funct3.value) == (instr >> 12) & 0x7
        assert int(dut.funct7.value) == (instr >> 25) & 0x7F
        count += 1

    dut._log.info(f"Random decode: PASS ({count} instructions)")
