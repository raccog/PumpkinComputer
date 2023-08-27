# Operating System

The operating system should have the following capabilities:

- Round-robin multi-tasking scheduler
- Protected virtual memory for userland programs
- A basic filesystem (using a RAM-disk)
- An init program that runs a minimal shell
- Basic system calls
- Text I/O stream using the UART
- Dynamic memory allocation for userland programs
- Signals(?) for userland programs
- Basic synchronization and IPC primitives

These capabilities are purposefully vague, as I have not made my choices for the implementations of each capability yet.

## Development Plan

Though I am currently focusing on the CPU, I can start the operating system before the CPU is finished. To do this, I would use QEMU as a simulated version of my CPU design.
