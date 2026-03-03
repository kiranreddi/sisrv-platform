#include <verilated.h>
#include <verilated_fst_c.h>
#include <cstdint>
#include <cstdio>
#include <cstdlib>

#include "VsisPlatformTop.h"

static const uint64_t kMaxCycles = 200000; // watchdog
static const uint64_t kResetCycles = 10;

int main(int argc, char** argv) {
  Verilated::commandArgs(argc, argv);
  auto* top = new VsisPlatformTop;

  VerilatedFstC* tfp = new VerilatedFstC;
  Verilated::traceEverOn(true);
  top->trace(tfp, 99);
  tfp->open("build/wave.fst");

  // init
  top->clk = 0;
  top->rst_n = 0;

  uint64_t cycle = 0;
  for (; cycle < kMaxCycles; ++cycle) {
    // clock toggle
    for (int half = 0; half < 2; ++half) {
      top->clk = !top->clk;
      top->eval();
      tfp->dump((vluint64_t)(cycle*2 + half));
    }

    if (cycle == kResetCycles) {
      top->rst_n = 1;
    }

    if (Verilated::gotFinish()) break;
  }

  tfp->close();
  delete tfp;
  delete top;

  if (cycle >= kMaxCycles) {
    std::fprintf(stderr, "TIMEOUT after %llu cycles\n", (unsigned long long)kMaxCycles);
    return 2;
  }

  std::printf("SIM DONE cycles=%llu\n", (unsigned long long)cycle);
  return 0;
}
