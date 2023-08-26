# On-Chip Debugger

The On-Chip Debugger will be used to control the CPU and access the system bus from a
host debugger such as gdb.

This on-chip debugger will support the minimal [RISC-V External Debug Support](https://riscv.org/wp-content/uploads/2019/03/riscv-debug-release.pdf) v0.13.2
along with some optional extensions.

## Debug Translator (DT) and Debug Transport Hardware (DTH)

A Debug Translator, such as OpenOCD, will be used to
transfer data from the host to the Debug Transport Hardware, which will be a simple
UART module.

### UART Description

TODO: Figure out how I might use OpenOCD to communicate with a DM through UART.

The UART will use 8 data bits, 1 parity bit, and 1 stop bit. It will use a baud rate of
115200, TODO: this might be variable in the future. It will have two 16-byte FIFOs, one
for transmitting and one for receiving. This UART will connect to the DTM.

## Debug Transport Module (DTM)

The initial Debug Transport Module will be simple, as the Debug Module will
only be accessed by the UART. JTAG might be beneficial in the future.

## Debug Module Interface (DMI)

The Debug Module Interface will be a point-to-point Wishbone b4 bus.

## Debug Module (DM)

There will be one Debug Module that has access to all cores on the SoC along with
the system bus.

## Debug Module Extensions

The following capabilities described as optional in the specification will be implemented:

- Provide a mechanism to allow debugging harts immediately out of reset (regardless of thereset cause).
- Provide abstract access to non-GPR hart registers.
- Allow memory access from a hart’s point of view.
- Allow direct System Bus Access.

Some other optional extensions (such as the Program Buffer) might be added in the future.
