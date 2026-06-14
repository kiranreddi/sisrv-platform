import logging
import os
import shutil

import riscof.utils as utils
from riscof.pluginTemplate import pluginTemplate

logger = logging.getLogger()


class spike(pluginTemplate):
    __model__ = "spike"
    __version__ = "1.0.0"

    def __init__(self, *args, **kwargs):
        sclass = super().__init__(*args, **kwargs)
        config = kwargs.get("config")
        config_dir = kwargs.get("config_dir")

        if config is None:
            logger.error("Missing [spike] section in config.ini")
            raise SystemExit(1)

        self.dut_exe = os.path.join(config.get("PATH", ""), "spike")
        self.num_jobs = str(config.get("jobs", 1))
        self.pluginpath = os.path.abspath(
            os.path.join(config_dir or ".", config.get("pluginpath", "plugins/spike"))
        )
        self.isa_spec = os.path.abspath(os.path.join(config_dir or ".", config["ispec"]))
        self.platform_spec = os.path.abspath(os.path.join(config_dir or ".", config["pspec"]))
        self.make = config.get("make", "make")
        self.toolchain_prefix = os.environ.get(
            "RISCOF_TOOLCHAIN_PREFIX",
            config.get("toolchain_prefix", "riscv64-unknown-elf-"),
        )
        return sclass

    def initialise(self, suite, work_dir, archtest_env):
        self.work_dir = work_dir
        self.compile_cmd = (
            self.toolchain_prefix
            + "gcc -march={0} "
            + "-static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles "
            + "-T "
            + self.pluginpath
            + "/env/link.ld "
            + "-I "
            + self.pluginpath
            + "/env/ "
            + "-I "
            + archtest_env
        )

    def _resolve_toolchain(self):
        compiler = self.toolchain_prefix + "gcc"
        if shutil.which(compiler) is not None:
            return

        for fallback in ("riscv64-unknown-elf-", "riscv64-linux-gnu-"):
            if shutil.which(fallback + "gcc") is not None:
                logger.warning(
                    "Using fallback toolchain prefix %s (configured: %s)",
                    fallback,
                    self.toolchain_prefix,
                )
                self.toolchain_prefix = fallback
                marker = "gcc -march="
                idx = self.compile_cmd.find(marker)
                if idx > 0:
                    self.compile_cmd = self.toolchain_prefix + self.compile_cmd[idx:]
                return

        logger.error("%s not found in PATH", compiler)
        raise SystemExit(1)

    def build(self, isa_yaml, platform_yaml):
        ispec = utils.load_yaml(isa_yaml)["hart0"]
        self.xlen = "64" if 64 in ispec["supported_xlen"] else "32"
        self.isa = "rv" + self.xlen
        if "I" in ispec["ISA"]:
            self.isa += "i"
        if "M" in ispec["ISA"]:
            self.isa += "m"
        if "C" in ispec["ISA"]:
            self.isa += "c"
        self.compile_cmd = self.compile_cmd + " -mabi=ilp32 "

        self._resolve_toolchain()

        if shutil.which(self.dut_exe) is None:
            logger.error("%s not found in PATH", self.dut_exe)
            raise SystemExit(1)

    def runTests(self, testList, cgf_file=None):
        make = utils.makeUtil(
            makefilePath=os.path.join(self.work_dir, "Makefile." + self.name[:-1])
        )
        make.makeCommand = self.make + " -j" + self.num_jobs

        for file in testList:
            testentry = testList[file]
            test = testentry["test_path"]
            test_dir = testentry["work_dir"]
            elf = "ref.elf" if cgf_file is not None else "dut.elf"

            execute = "@cd " + testentry["work_dir"] + ";"
            cmd = (
                self.compile_cmd.format(testentry["isa"].lower())
                + " "
                + test
                + " -o "
                + elf
            )
            compile_cmd = cmd + " -D" + " -D".join(testentry["macros"])
            execute += compile_cmd + ";"

            sig_file = os.path.join(test_dir, self.name[:-1] + ".signature")
            execute += (
                self.dut_exe
                + " --isa={0} +signature={1} +signature-granularity=4 {2};".format(
                    self.isa, sig_file, elf
                )
            )
            make.add_target(execute)

        make.execute_all(self.work_dir)
