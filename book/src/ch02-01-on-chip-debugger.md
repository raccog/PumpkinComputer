# On-Chip Debugger

The On-Chip Debugger will be used to control the CPU and access the system bus from a
host debugger such as gdb.

This on-chip debugger will support the minimal [RISC-V External Debug Support](https://riscv.org/wp-content/uploads/2019/03/riscv-debug-release.pdf) v0.13.2
along with some optional extensions.

## Description

The goal of the on-chip debuger is to support connecting to GDB through OpenOCD. 

## Debug Translator (DT) and Debug Transport Module (DTM)

A Debug Translator, such as OpenOCD, will be used to
transfer data from the host to the Debug Transport Module, which will be a JTAG TAP
conforming to IEEE STD 1149.1.

### JTAG Description

The JTAG TAP will provide a connection that can be accessed by OpenOCD to connect to the
RISC-V Debug Module. It will connect directly to the Debug Module; making up the Debug Module
Interface (DMI) connection.

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
