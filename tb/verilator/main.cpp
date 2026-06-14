#include <verilated.h>
#include <verilated_fst_c.h>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <fstream>
#include <iomanip>
#include <string>

#include "VsisPlatformTop.h"
#include "verilated_dpi.h"

extern "C" int unsigned dpi_sisrv_ram_read_word(int unsigned word_idx);

static constexpr uint32_t kRamBase       = 0x80000000u;
static constexpr uint32_t kTohostAddr    = 0x10000000u;
static constexpr uint32_t kRiscofHalt    = 3u;
static constexpr uint64_t kDefaultCycles = 200000;

struct SimConfig {
  std::string rom_hex = "rom.hex";
  std::string ram_hex = "ram.hex";
  std::string signature_out;
  uint32_t    sig_start = 0;
  uint32_t    sig_end   = 0;
  uint64_t    max_cycles = kDefaultCycles;
  bool        enable_trace = false;
};

static void usage(const char* argv0) {
  std::fprintf(stderr,
               "Usage: %s [options]\n"
               "  --rom HEX              ROM init file (default: rom.hex)\n"
               "  --ram HEX              RAM init file (default: ram.hex)\n"
               "  --signature-start ADDR Signature region start (physical)\n"
               "  --signature-end ADDR   Signature region end (exclusive)\n"
               "  --signature-out FILE   Write signature dump to FILE\n"
               "  --timeout-cycles N     Simulation cycle limit (default: %llu)\n"
               "  --trace                Enable FST waveform dump\n",
               argv0, (unsigned long long)kDefaultCycles);
}

static bool parse_u32(const char* text, uint32_t* out) {
  char* end = nullptr;
  unsigned long long value = std::strtoull(text, &end, 0);
  if (end == text || *end != '\0' || value > 0xFFFFFFFFull) {
    return false;
  }
  *out = static_cast<uint32_t>(value);
  return true;
}

static bool parse_u64(const char* text, uint64_t* out) {
  char* end = nullptr;
  unsigned long long value = std::strtoull(text, &end, 0);
  if (end == text || *end != '\0') {
    return false;
  }
  *out = value;
  return true;
}

static bool parse_args(int argc, char** argv, SimConfig* cfg) {
  for (int i = 1; i < argc; ++i) {
    const char* arg = argv[i];
    auto need_value = [&](const char* name) -> const char* {
      if (i + 1 >= argc) {
        std::fprintf(stderr, "Missing value for %s\n", name);
        usage(argv[0]);
        return nullptr;
      }
      return argv[++i];
    };

    if (std::strcmp(arg, "--rom") == 0) {
      const char* value = need_value(arg);
      if (!value) return false;
      cfg->rom_hex = value;
    } else if (std::strcmp(arg, "--ram") == 0) {
      const char* value = need_value(arg);
      if (!value) return false;
      cfg->ram_hex = value;
    } else if (std::strcmp(arg, "--signature-start") == 0) {
      const char* value = need_value(arg);
      if (!value) return false;
      if (!parse_u32(value, &cfg->sig_start)) return false;
    } else if (std::strcmp(arg, "--signature-end") == 0) {
      const char* value = need_value(arg);
      if (!value) return false;
      if (!parse_u32(value, &cfg->sig_end)) return false;
    } else if (std::strcmp(arg, "--signature-out") == 0) {
      const char* value = need_value(arg);
      if (!value) return false;
      cfg->signature_out = value;
    } else if (std::strcmp(arg, "--timeout-cycles") == 0) {
      const char* value = need_value(arg);
      if (!value) return false;
      if (!parse_u64(value, &cfg->max_cycles)) return false;
    } else if (std::strcmp(arg, "--trace") == 0) {
      cfg->enable_trace = true;
    } else if (std::strcmp(arg, "--help") == 0 || std::strcmp(arg, "-h") == 0) {
      usage(argv[0]);
      return false;
    } else {
      std::fprintf(stderr, "Unknown argument: %s\n", arg);
      usage(argv[0]);
      return false;
    }
  }
  return true;
}

static bool copy_hex_file(const std::string& src_path, const char* dst_path) {
  std::ifstream src(src_path, std::ios::binary);
  if (!src) {
    std::fprintf(stderr, "Failed to open hex input: %s\n", src_path.c_str());
    return false;
  }
  std::ofstream dst(dst_path, std::ios::binary);
  if (!dst) {
    std::fprintf(stderr, "Failed to open hex output: %s\n", dst_path);
    return false;
  }
  dst << src.rdbuf();
  if (!dst) {
    std::fprintf(stderr, "Failed to write hex output: %s\n", dst_path);
    return false;
  }
  return true;
}

static bool stage_hex_files(const SimConfig& cfg) {
  if (cfg.rom_hex != "rom.hex" && cfg.rom_hex != "./rom.hex" &&
      !copy_hex_file(cfg.rom_hex, "rom.hex")) {
    return false;
  }
  if (cfg.ram_hex != "ram.hex" && cfg.ram_hex != "./ram.hex" &&
      !copy_hex_file(cfg.ram_hex, "ram.hex")) {
    return false;
  }
  return true;
}

static uint32_t read_ram_word(VsisPlatformTop* top, uint32_t phys_addr) {
  (void)top;
  if (phys_addr < kRamBase) {
    return 0;
  }
  const uint32_t word_idx = (phys_addr - kRamBase) >> 2;
  return dpi_sisrv_ram_read_word(word_idx);
}

static bool dump_signature(VsisPlatformTop* top, const SimConfig& cfg) {
  if (cfg.signature_out.empty() || cfg.sig_end <= cfg.sig_start) {
    std::fprintf(stderr, "Invalid signature dump configuration\n");
    return false;
  }

  std::ofstream out(cfg.signature_out);
  if (!out) {
    std::fprintf(stderr, "Failed to open signature output: %s\n", cfg.signature_out.c_str());
    return false;
  }

  for (uint32_t addr = cfg.sig_start; addr < cfg.sig_end; addr += 4) {
    const uint32_t word = read_ram_word(top, addr);
    out << std::hex << std::setw(8) << std::setfill('0') << word << '\n';
  }

  return true;
}

int main(int argc, char** argv) {
  SimConfig cfg;
  if (!parse_args(argc, argv, &cfg)) {
    return 2;
  }

  if (!stage_hex_files(cfg)) {
    return 2;
  }

  Verilated::commandArgs(argc, argv);
  auto* top = new VsisPlatformTop;

  VerilatedFstC* tfp = nullptr;
  if (cfg.enable_trace) {
    tfp = new VerilatedFstC;
    Verilated::traceEverOn(true);
    top->trace(tfp, 99);
    tfp->open("build/wave.fst");
  }

  top->clk     = 0;
  top->rst_n   = 0;
  top->gpio_in  = 0;
  top->plic_irq = 0;
  top->jtag_tck = 0;
  top->jtag_tms = 0;
  top->jtag_tdi = 0;

  int exit_code = 0;
  uint64_t cycle = 0;
  bool done = false;
  static constexpr uint64_t kResetCycles = 10;

  for (; cycle < cfg.max_cycles && !done; ++cycle) {
    top->clk = 1;
    top->eval();
    if (tfp) {
      tfp->dump(static_cast<vluint64_t>(cycle * 2));
    }

    if (top->uart_tx_valid) {
      std::fputc(top->uart_tx_data, stdout);
      std::fflush(stdout);
    }

    top->clk = 0;
    top->eval();
    if (tfp) {
      tfp->dump(static_cast<vluint64_t>(cycle * 2 + 1));
    }

    if (cycle == kResetCycles) {
      top->rst_n = 1;
    }

    if (cycle > kResetCycles + 5) {
      if (top->tohost_pass) {
        std::printf("*** PASS *** (tohost=0x%08x) at cycle %llu\n",
                    top->tohost_code, (unsigned long long)cycle);
        exit_code = 0;
        done = true;
      } else if (top->tohost_fail) {
        std::printf("*** FAIL *** (tohost=0x%08x) at cycle %llu\n",
                    top->tohost_code, (unsigned long long)cycle);
        exit_code = 1;
        done = true;
      } else if (top->tohost_code == kRiscofHalt) {
        std::printf("*** RISCOF HALT *** (tohost=0x%08x) at cycle %llu\n",
                    top->tohost_code, (unsigned long long)cycle);
        if (!dump_signature(top, cfg)) {
          exit_code = 1;
        } else {
          exit_code = 0;
        }
        done = true;
      }
    }

    if (Verilated::gotFinish()) {
      done = true;
    }
  }

  if (tfp) {
    tfp->close();
    delete tfp;
  }
  delete top;

  if (!done) {
    std::fprintf(stderr, "TIMEOUT after %llu cycles\n", (unsigned long long)cfg.max_cycles);
    return 2;
  }

  return exit_code;
}
