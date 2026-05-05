# uvm-style-axi-verification

A beginner-readable, UVM-inspired SystemVerilog verification project for an AXI4-Lite slave register bank. It uses plain modules, tasks, a driver, monitor, scoreboard, directed sequences, a random test, procedural checks, and simple coverage counters.

This project does not use the real UVM library.

## DUT Overview

The DUT in `src/axi_regbank.sv` is a synthesizable AXI4-Lite slave with eight 32-bit registers:

| Address | Register | Behavior |
| --- | --- | --- |
| `0x00` | `CTRL` | enable, self-clearing soft reset, mode |
| `0x04` | `STATUS` | read-only status |
| `0x08` | `DATA_IN` | writable data input |
| `0x0c` | `DATA_OUT` | processed data output |
| `0x10` | `IRQ_EN` | interrupt enable mask |
| `0x14` | `IRQ_STAT` | interrupt status with write-1-to-clear |
| `0x18` | `SCRATCH0` | read/write scratch |
| `0x1c` | `SCRATCH1` | read/write scratch |

When enabled, `DATA_OUT` returns bit-reversed `DATA_IN` XOR `0xa5a55a5a`. A data write while enabled sets interrupt status bit 0. `irq_out` asserts only when an enabled interrupt status bit is set.

## Verification Environment

- `axi_driver.sv` provides `axi_write(addr, data)` and `axi_read(addr, data_out)` tasks.
- `axi_monitor.sv` observes completed reads and writes.
- `scoreboard.sv` models expected register behavior and checks read data.
- `assertions.sv` contains procedural protocol checks for Icarus compatibility.
- `coverage.sv` tracks simple functional coverage counters and flags.
- `seq_lib.sv` contains directed sequences.
- `rand_test.sv` runs about 100 random valid register transactions.
- `tb_top.sv` connects everything and writes a VCD waveform.

## Tools

- Icarus Verilog with `iverilog -g2012`
- `vvp`
- Python 3 for the regression script
- Optional VCD viewer such as GTKWave

## Build and Run

```sh
make clean
make regression
```

Run all tests in one simulation:

```sh
make run
```

Run a single test directly:

```sh
make
vvp results/tb.vvp +TEST=seq_irq
```

## Expected Output

The regression prints a clean summary:

```text
seq_reset PASS
seq_all_registers PASS
seq_irq PASS
seq_walk_ones PASS
rand_test PASS
Result: 5/5 tests passing
```

Generated result files:

- `results/regression_report.txt`
- `results/scoreboard_log.csv`
- `results/coverage_report.txt`
- `results/waveform.vcd`

## File Guide

- `src/axi_regbank.sv`: AXI4-Lite register bank DUT.
- `sim/tb_top.sv`: top-level testbench.
- `sim/axi_driver.sv`: AXI read/write bus driver.
- `sim/axi_monitor.sv`: passive bus monitor.
- `sim/scoreboard.sv`: reference model and comparisons.
- `sim/assertions.sv`: simple protocol and IRQ checks.
- `sim/coverage.sv`: coverage counters and report writer.
- `sim/seq_lib.sv`: directed sequence library.
- `sim/rand_test.sv`: constrained random-style test.
- `scripts/run_regression.py`: compile and regression runner.
- `docs/`: verification plan, AXI notes, and environment architecture.

## Known Limitations

- UVM-style only; no real UVM library.
- Procedural checks are used instead of advanced SVA for Icarus compatibility.
- Coverage is counter-based instead of covergroup-based.
- The AXI4-Lite slave and tests are intentionally small.
- No formal verification or FPGA deployment is claimed.

## Future Improvements

- Add byte-strobe-focused tests.
- Add backpressure tests with delayed ready/valid behavior.
- Add invalid-address behavior checks.
- Expand the interrupt model with multiple status bits.
- Add a small CI workflow for regression runs.
