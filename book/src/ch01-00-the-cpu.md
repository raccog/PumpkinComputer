# The CPU

The CPU used in The Pumpkin Computer will evolve over time to increase processing power, but it will start off with the simplest implementation. Future implementations should retain
backwards compatibility with the operating system.

## CPU Description

The first implementation of the CPU will have the following specifications:

- Single-core RV32IMAC ISA implementation (this might change to RV64IMAC. I plan to test out the difference in FPGA resources between the 32-bit and 64-bit implementations. Using RV32
would complicate the software so it can handle 32-bit and 64-bit pointers. But using RV64 would use more FPGA resources. I'm not sure what I will choose yet)
- Single-cycle with no pipeline
- Small data and instruction caches (unsure of the specific sizes; probably a few kilobytes. TODO: test out cache sizes with [Ripes](https://github.com/mortbopet/Ripes))
- Exceptions and interrupts
- Machine and user privilege modes
- MMU (probably Sv39; I plan on testing the FPGA resource usage for different MMUs)
