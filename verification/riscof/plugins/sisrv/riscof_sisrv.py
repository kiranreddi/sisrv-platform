import logging
import os
import shutil
import subprocess
import sys

import riscof.utils as utils
from riscof.pluginTemplate import pluginTemplate

logger = logging.getLogger()


class sisrv(pluginTemplate):
    __model__ = "sisrv"
    __version__ = "0.1.0"

    def __init__(self, *args, **kwargs):
        sclass = super().__init__(*args, **kwargs)
        config = kwargs.get("config")
        config_dir = kwargs.get("config_dir")

        if config is None:
            logger.error("Missing [sisrv] section in config.ini")
            raise SystemExit(1)

        self.pluginpath = os.path.abspath(
            os.path.join(config_dir or ".", config.get("pluginpath", "plugins/sisrv"))
        )
        self.isa_spec = os.path.abspath(os.path.join(config_dir or ".", config["ispec"]))
        self.platform_spec = os.path.abspath(os.path.join(config_dir or ".", config["pspec"]))
        self.num_jobs = str(config.get("jobs", 1))
        self.target_run = config.get("target_run", "1") != "0"

        repo_root = os.path.abspath(os.path.join(self.pluginpath, "..", "..", "..", ".."))
        default_sim = os.path.join(repo_root, "build", "sim_sisPlatformTop")
        sim_path = config.get("simulator", default_sim)
        if os.path.isabs(sim_path):
            self.dut_exe = sim_path
        else:
            self.dut_exe = os.path.abspath(os.path.join(config_dir or ".", sim_path))
        self.toolchain_prefix = os.environ.get(
            "RISCOF_TOOLCHAIN_PREFIX",
            os.environ.get(
                "SISRV_TOOLCHAIN_PREFIX",
                config.get("toolchain_prefix", "riscv64-unknown-elf-"),
            ),
        )
        self.elf2sisrv = os.path.join(
            repo_root, "verification", "riscof", "scripts", "elf2sisrv.py"
        )
        self.timeout_cycles = str(config.get("timeout_cycles", 1000000))
        return sclass

    def initialise(self, suite, work_dir, archtest_env):
        self.work_dir = work_dir
        self.suite_dir = suite
        self.compile_cmd = (
            self.toolchain_prefix
            + "gcc -march={0} -mabi=ilp32 -Wl,-melf32lriscv "
            + "-static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -g "
            + "-T "
            + self.pluginpath
            + "/env/link.ld "
            + "-I "
            + self.pluginpath
            + "/env/ "
            + "-I "
            + archtest_env
            + " {1} -o {2} {3}"
        )

    def build(self, isa_yaml, platform_yaml):
        ispec = utils.load_yaml(isa_yaml)["hart0"]
        self.xlen = "64" if 64 in ispec["supported_xlen"] else "32"

        compiler = self.toolchain_prefix + "gcc"
        if shutil.which(compiler) is None:
            for fallback in ("riscv64-unknown-elf-", "riscv64-linux-gnu-"):
                if shutil.which(fallback + "gcc") is not None:
                    old_prefix = self.toolchain_prefix
                    self.toolchain_prefix = fallback
                    self.compile_cmd = self.compile_cmd.replace(old_prefix, fallback)
                    compiler = self.toolchain_prefix + "gcc"
                    break
            else:
                logger.error("%s not found in PATH", compiler)
                raise SystemExit(1)

        if not os.path.isfile(self.dut_exe):
            logger.error("Verilator sim binary not found: %s", self.dut_exe)
            logger.error("Build it first with: make build/sim_sisPlatformTop USE_AXIL=0")
            raise SystemExit(1)

        if not os.path.isfile(self.elf2sisrv):
            logger.error("Missing ELF conversion helper: %s", self.elf2sisrv)
            raise SystemExit(1)

    def _symbol_addr(self, elf_path, name):
        nm = self.toolchain_prefix + "nm"
        proc = subprocess.run(
            [nm, "-g", elf_path],
            check=False,
            capture_output=True,
            text=True,
        )
        if proc.returncode != 0:
            return None
        for line in proc.stdout.splitlines():
            parts = line.split()
            if len(parts) >= 3 and parts[2] == name:
                return int(parts[0], 16)
        return None

    def runTests(self, testList):
        for testname, testentry in testList.items():
            test = testentry["test_path"]
            test_dir = testentry["work_dir"]
            base = os.path.basename(test).replace(".S", "")
            elf = os.path.join(test_dir, base + ".elf")
            sig_file = os.path.join(test_dir, self.name[:-1] + ".signature")
            compile_macros = " -D" + " -D".join(testentry["macros"])

            compile_cmd = self.compile_cmd.format(
                testentry["isa"].lower(), test, elf, compile_macros
            )
            logger.debug("Compiling %s", testname)
            utils.shellCommand(compile_cmd).run(cwd=test_dir)

            if not self.target_run:
                continue

            rom_hex = os.path.join(test_dir, "rom.hex")
            ram_hex = os.path.join(test_dir, "ram.hex")
            elf2sisrv_cmd = (
                f"{sys.executable} {self.elf2sisrv} {elf} {rom_hex} {ram_hex} "
                f"--toolchain-prefix {self.toolchain_prefix}"
            )
            utils.shellCommand(elf2sisrv_cmd).run(cwd=test_dir)

            sig_begin = self._symbol_addr(elf, "begin_signature")
            sig_end = self._symbol_addr(elf, "end_signature")
            if sig_begin is None or sig_end is None:
                logger.error("Signature labels missing in %s", elf)
                raise SystemExit(1)

            sim_cmd = (
                f"{self.dut_exe} "
                f"--rom {rom_hex} "
                f"--ram {ram_hex} "
                f"--signature-start {sig_begin} "
                f"--signature-end {sig_end} "
                f"--signature-out {sig_file} "
                f"--timeout-cycles {self.timeout_cycles}"
            )
            logger.debug("Simulating %s", testname)
            utils.shellCommand(sim_cmd).run(cwd=test_dir)

        if not self.target_run:
            raise SystemExit(0)
