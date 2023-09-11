# The Processing Environment

The processing environment includes all parts of the Pumpkin Computer that would be considered "hardware".
These components are implemented in SystemVerilog, so the processing environment can be run on an FPGA
or simulated on modern PCs.

One goal of the processing environment is to stick close to modern implementations of RISC-V processors.
If successful, this will enable modern software and toolchains to run in the processing environment.
A QEMU RISC-V emulator will be used to ensure that the operating system and userspace programs run
properly on both the SystemVerilog processor implementation and standard RISC-V processors.

## Top-Level Modules

Top-level modules include:

- RV32IMA single-core, single-cycle processor (See Chapter 2.1: "The CPU" for more info)
- Wishbone B4 System Bus
- Small RAM
- On-chip Debugger with JTAG connector
- Mini UART
- Text-based VGA Framebuffer
- System timer
- Watchdog
- Flash with SPI Interface

### Modules' Purpose

Each of the top-level modules in version 1.0 are necessary to support the operating system.

The processor includes an SV32 MMU to provide the operating system with a hardware implementation of
virtual memory. It includes three RISC-V extensions; the base I integer extension, M for integer
multiplication/division, and A for atomic memory interactions. Each of these are necessary for the
operating system (though the M extension could technically be implemented in software).

The Wishbone system bus is required to access RAM and peripherals as memory-mapped registers. A small
RAM stores the running OS/userspace programs and provides a large enough space for
working data sets. The on-chip debugger makes it much easier to debug the running OS
and userspace programs. A mini UART provides a text-based interface. Similarly, the
text-based VGA framebuffer provides a text interface using a VGA monitor (to make this interactive,
I need to figure out how to support a keyboard. USB HID?). The system timer provides a running counter
of how long it has been since the system started up. The watchdog can recover the system to a valid
state if it ever gets stuck. The SPI-based flash interface will provide the operating system with
persistent storage for a filesystem.


