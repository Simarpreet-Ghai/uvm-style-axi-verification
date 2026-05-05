# AXI4-Lite Notes

AXI4-Lite is a simple memory-mapped bus commonly used for control and status registers. It has separate channels for write address, write data, write response, read address, and read data.

## Write Flow

1. The master sends an address using `AWADDR` and `AWVALID`.
2. The slave accepts it with `AWREADY`.
3. The master sends data using `WDATA`, `WSTRB`, and `WVALID`.
4. The slave accepts it with `WREADY`.
5. The slave returns a response using `BRESP` and `BVALID`.
6. The master accepts the response with `BREADY`.

This DUT returns `OKAY`, encoded as `2'b00`, for all accesses.

## Read Flow

1. The master sends an address using `ARADDR` and `ARVALID`.
2. The slave accepts it with `ARREADY`.
3. The slave returns `RDATA`, `RRESP`, and `RVALID`.
4. The master accepts the data with `RREADY`.

## Register Map

| Address | Name | Access | Notes |
| --- | --- | --- | --- |
| `0x00` | `CTRL` | R/W | bit 0 enable, bit 1 soft reset self-clears, bits `[7:4]` mode |
| `0x04` | `STATUS` | R/O | bit 0 busy mirrors enable, bit 1 error/status, bits `[7:4]` state mirrors mode |
| `0x08` | `DATA_IN` | R/W | Input data register |
| `0x0c` | `DATA_OUT` | R/O | Bit-reversed `DATA_IN` XOR `0xa5a55a5a` when enabled |
| `0x10` | `IRQ_EN` | R/W | Interrupt enable mask |
| `0x14` | `IRQ_STAT` | R/W1C | Write 1 to clear interrupt status bits |
| `0x18` | `SCRATCH0` | R/W | General scratch register |
| `0x1c` | `SCRATCH1` | R/W | General scratch register |

## Soft Reset Behavior

Writing `1` to `CTRL[1]` clears `DATA_IN`, `IRQ_STAT`, `SCRATCH0`, and `SCRATCH1`. The bit does not remain set when read back.
