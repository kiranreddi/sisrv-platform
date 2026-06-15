#include <verilated.h>
#include <cstdint>
#include <cstdio>

#include "VsisPipelineDebugTb.h"

extern "C" void dpi_sisrv_retire_insn(
    int unsigned pc_val,
    int unsigned insn_val,
    int unsigned rd_val,
    int unsigned wdata_val,
    unsigned char wr_en
) {
  (void)pc_val;
  (void)insn_val;
  (void)rd_val;
  (void)wdata_val;
  (void)wr_en;
}

static uint64_t g_cycle = 0;

static void tick(VsisPipelineDebugTb* top) {
  top->clk = 1;
  top->eval();
  top->clk = 0;
  top->eval();
  ++g_cycle;
}

static bool wait_halted(VsisPipelineDebugTb* top, bool value, uint64_t timeout) {
  for (uint64_t i = 0; i < timeout; ++i) {
    if (static_cast<bool>(top->dbg_halted) == value) {
      return true;
    }
    tick(top);
  }
  return false;
}

static uint32_t read_gpr(VsisPipelineDebugTb* top, uint32_t reg) {
  top->dbg_abs_valid = 1;
  top->dbg_abs_write = 0;
  top->dbg_abs_regaddr = reg & 0x1f;
  top->eval();
  const uint32_t value = top->dbg_abs_rdata;
  top->dbg_abs_valid = 0;
  top->eval();
  return value;
}

static bool step_one(VsisPipelineDebugTb* top) {
  if (!top->dbg_halted) {
    std::fprintf(stderr, "Core is not halted before step at cycle %llu\n",
                 static_cast<unsigned long long>(g_cycle));
    return false;
  }

  top->dbg_single_step = 1;
  top->dbg_resume_req = 1;
  tick(top);
  top->dbg_resume_req = 0;

  bool saw_running = false;
  for (uint64_t i = 0; i < 2000; ++i) {
    tick(top);
    if (!top->dbg_halted) {
      saw_running = true;
    }
    if (saw_running && top->dbg_halted) {
      top->dbg_single_step = 0;
      tick(top);
      return true;
    }
  }

  std::fprintf(stderr, "Single-step did not halt again by cycle %llu\n",
               static_cast<unsigned long long>(g_cycle));
  return false;
}

static bool expect_eq(const char* name, uint32_t got, uint32_t expected) {
  if (got != expected) {
    std::fprintf(stderr, "%s: got 0x%08x expected 0x%08x\n", name, got, expected);
    return false;
  }
  return true;
}

int main(int argc, char** argv) {
  Verilated::commandArgs(argc, argv);
  auto* top = new VsisPipelineDebugTb;

  top->clk = 0;
  top->rst_n = 0;
  top->dbg_halt_req = 1;
  top->dbg_resume_req = 0;
  top->dbg_single_step = 0;
  top->dbg_abs_valid = 0;
  top->dbg_abs_write = 0;
  top->dbg_abs_regaddr = 0;
  top->dbg_abs_wdata = 0;

  for (int i = 0; i < 5; ++i) {
    tick(top);
  }
  top->rst_n = 1;

  if (!wait_halted(top, true, 50)) {
    std::fprintf(stderr, "Core did not enter debug halt\n");
    delete top;
    return 1;
  }

  top->dbg_halt_req = 0;

  if (!step_one(top)) {
    delete top;
    return 1;
  }
  if (!expect_eq("x1 after first step", read_gpr(top, 1), 1) ||
      !expect_eq("x2 before second step", read_gpr(top, 2), 0) ||
      !expect_eq("tohost before second step", top->tohost_code, 0)) {
    delete top;
    return 1;
  }

  if (!step_one(top)) {
    delete top;
    return 1;
  }
  if (!expect_eq("x2 after second step", read_gpr(top, 2), 3) ||
      !expect_eq("x3 before third step", read_gpr(top, 3), 0) ||
      !expect_eq("tohost before third step", top->tohost_code, 0)) {
    delete top;
    return 1;
  }

  if (!step_one(top)) {
    delete top;
    return 1;
  }
  if (!expect_eq("x3 after third step", read_gpr(top, 3), 6) ||
      !expect_eq("tohost before resume", top->tohost_code, 0)) {
    delete top;
    return 1;
  }

  top->dbg_resume_req = 1;
  tick(top);
  top->dbg_resume_req = 0;

  for (uint64_t i = 0; i < 2000; ++i) {
    tick(top);
    if (top->tohost_pass) {
      std::printf("*** PASS *** pipeline debug step at cycle %llu\n",
                  static_cast<unsigned long long>(g_cycle));
      delete top;
      return 0;
    }
    if (top->tohost_fail) {
      std::fprintf(stderr, "Program reported FAIL at cycle %llu\n",
                   static_cast<unsigned long long>(g_cycle));
      delete top;
      return 1;
    }
  }

  std::fprintf(stderr, "Timed out waiting for pass after resume\n");
  delete top;
  return 1;
}
