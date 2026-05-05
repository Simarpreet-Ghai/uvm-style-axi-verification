#!/usr/bin/env python3
from pathlib import Path
import subprocess
import sys


ROOT = Path(__file__).resolve().parents[1]
RESULTS = ROOT / "results"
SIM_OUT = RESULTS / "tb.vvp"
REPORT = RESULTS / "regression_report.txt"

SOURCES = [
    "src/axi_regbank.sv",
    "sim/axi_driver.sv",
    "sim/axi_monitor.sv",
    "sim/scoreboard.sv",
    "sim/assertions.sv",
    "sim/coverage.sv",
    "sim/seq_lib.sv",
    "sim/rand_test.sv",
    "sim/tb_top.sv",
]

TESTS = [
    "seq_reset",
    "seq_all_registers",
    "seq_irq",
    "seq_walk_ones",
    "rand_test",
]


def run_cmd(cmd):
    return subprocess.run(
        cmd,
        cwd=ROOT,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=False,
    )


def main():
    RESULTS.mkdir(exist_ok=True)
    compile_cmd = ["iverilog", "-g2012", "-o", str(SIM_OUT)] + SOURCES
    compile_result = run_cmd(compile_cmd)

    report_lines = []
    report_lines.append("Compile command:")
    report_lines.append(" ".join(compile_cmd))
    report_lines.append("")
    report_lines.append(compile_result.stdout)

    if compile_result.returncode != 0:
        report_lines.append("Compile FAILED")
        REPORT.write_text("\n".join(report_lines))
        print("Compile FAILED")
        print(f"See {REPORT}")
        return 1

    passing = 0
    for test in TESTS:
        result = run_cmd(["vvp", str(SIM_OUT), f"+TEST={test}"])
        passed = result.returncode == 0 and "FINAL PASS" in result.stdout
        if passed:
            passing += 1
        status = "PASS" if passed else "FAIL"
        print(f"{test} {status}")
        report_lines.append("")
        report_lines.append(f"===== {test} {status} =====")
        report_lines.append(result.stdout)

    summary = f"Result: {passing}/{len(TESTS)} tests passing"
    print(summary)
    report_lines.append("")
    report_lines.append(summary)
    REPORT.write_text("\n".join(report_lines))
    return 0 if passing == len(TESTS) else 1


if __name__ == "__main__":
    sys.exit(main())
