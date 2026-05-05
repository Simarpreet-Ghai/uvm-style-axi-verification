# Verification Plan

## Feature List

- AXI4-Lite write handshake for AW, W, and B channels.
- AXI4-Lite read handshake for AR and R channels.
- OKAY responses for supported register accesses.
- Eight 32-bit registers from address `0x00` through `0x1c`.
- `CTRL` writable fields: enable at bit 0, self-clearing soft reset at bit 1, mode at bits `[7:4]`.
- `STATUS` read-only behavior.
- `DATA_IN` writable input value.
- `DATA_OUT` read-only processed value when enabled.
- `IRQ_EN` interrupt mask.
- `IRQ_STAT` write-1-to-clear behavior.
- `SCRATCH0` and `SCRATCH1` read/write storage.

## Test Matrix

| Test | Purpose | Main Checks |
| --- | --- | --- |
| `seq_reset` | Check reset defaults and soft reset behavior | All registers read expected defaults, soft reset clears selected state |
| `seq_all_registers` | Touch every register address | Scratch readback, read-only registers, control/status behavior, data output |
| `seq_irq` | Verify interrupt path | IRQ stays low before event, asserts after enabled data event, clears through W1C |
| `seq_walk_ones` | Exercise bit positions | Walking-one writes through scratch registers and data processing path |
| `rand_test` | Add light random traffic | 100 valid reads/writes with scoreboard comparison |

## Coverage Goals

- All eight register addresses accessed.
- At least one read observed.
- At least one write observed.
- IRQ assertion behavior observed.
- Scratch register readback passes.

Icarus Verilog does not reliably support full SystemVerilog covergroups, so this project uses simple counters and flags in `sim/coverage.sv`.

## Pass Criteria

- All directed and random tests print `PASS`.
- Scoreboard reports no read-data mismatches.
- Procedural protocol checks report no assertion failures.
- Regression summary prints `Result: 5/5 tests passing`.

## Known Limitations

- This is UVM-style/UVM-inspired only. It does not use the real UVM library.
- The AXI4-Lite model is intentionally small and student-readable.
- Assertions are procedural checks instead of advanced SVA properties for Icarus compatibility.
- Coverage uses counters instead of SystemVerilog covergroups.
- The project does not claim formal verification, commercial UVM methodology, or FPGA deployment.
