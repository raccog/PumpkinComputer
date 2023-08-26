# The System-On-Chip (SoC)

The System-on-Chip, or SoC, contains the CPU along with a system bus, an on-chip debugger, RAM,
and peripherals such as UART.

While the CPU is described in Chapter 1, this chapter describes every other module on the SoC.

## SoC Modules

The SoC will contain the following modules:

- A RISC-V CPU described in Chapter 1
- On-chip debugger connected with a UART using a Wishbone b4 point-to-point interface
- Wishbone b4 system bus (TODO: decide bus arbitration implementation. see [crossbar switch](https://en.wikipedia.org/wiki/Crossbar_switch))
- UART for text input/output
- Small RAM (a few kilobytes)

## Development Plan

To start, I am working on the UART transmitter/receiver. This will help me get used to designing digital circuits in Verilog before starting the CPU. I will then move on to the
on-chip debugger and then, finally, the CPU.
