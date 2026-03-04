#include <verilated.h>
#include <verilated_fst_c.h>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>

#include "VsisPlatformTop.h"

static const uint64_t kMaxCycles   = 200000;
static const uint64_t kResetCycles = 10;

int main(int argc, char** argv) {
  Verilated::commandArgs(argc, argv);
  auto* top = new VsisPlatformTop;

  // FST trace
  VerilatedFstC* tfp = new VerilatedFstC;
  Verilated::traceEverOn(true);
  top->trace(tfp, 99);
  tfp->open("build/wave.fst");

  // Initialize
  top->clk   = 0;
  top->rst_n = 0;

  int exit_code = 0;
  uint64_t cycle = 0;
  bool done = false;

  for (; cycle < kMaxCycles && !done; ++cycle) {
    // Rising edge
    top->clk = 1;
    top->eval();
    tfp->dump((vluint64_t)(cycle * 2));

    // Falling edge
    top->clk = 0;
    top->eval();
    tfp->dump((vluint64_t)(cycle * 2 + 1));

    // Release reset after kResetCycles
    if (cycle == kResetCycles) {
      top->rst_n = 1;
    }

    // Check tohost for pass/fail
    if (cycle > kResetCycles + 5) {
      if (top->tohost_pass) {
        std::printf("*** PASS *** (tohost=0x%08x) at cycle %llu\n",
                    top->tohost_code, (unsigned long long)cycle);
        exit_code = 0;
        done = true;
      }
      if (top->tohost_fail) {
        std::printf("*** FAIL *** (tohost=0x%08x) at cycle %llu\n",
                    top->tohost_code, (unsigned long long)cycle);
        exit_code = 1;
        done = true;
      }
    }

    if (Verilated::gotFinish()) {
      done = true;
    }
  }

  tfp->close();
  delete tfp;
  delete top;

  if (!done) {
    std::fprintf(stderr, "TIMEOUT after %llu cycles\n", (unsigned long long)kMaxCycles);
    return 2;
  }

  return exit_code;
}
