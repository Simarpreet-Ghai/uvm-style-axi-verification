# Environment Architecture

This project uses a small UVM-inspired structure without importing the UVM library.

## Blocks

- `tb_top.sv` connects the DUT, driver, monitor, scoreboard, coverage, assertions, and sequences.
- `axi_driver.sv` provides reusable `axi_write` and `axi_read` tasks.
- `axi_monitor.sv` passively watches completed bus transfers and sends observations to the scoreboard log.
- `scoreboard.sv` keeps a reference model of the register bank and checks read data.
- `assertions.sv` implements procedural protocol checks that work with Icarus Verilog.
- `coverage.sv` tracks functional coverage goals with counters and flags.
- `seq_lib.sv` contains directed test sequences.
- `rand_test.sv` runs a small random test of valid register accesses.

## Flow

1. A sequence calls the driver to perform an AXI4-Lite read or write.
2. For writes, the sequence updates the scoreboard reference model.
3. For reads, the sequence asks the scoreboard to compare actual data with expected data.
4. The monitor logs bus-level observed transactions.
5. Coverage counters are updated as tests run.
6. The regression script compiles once and runs each test separately with a plusarg.
