# The Operating System

The operating system should have the following capabilities:

- Round-robin multi-tasking scheduler
- Protected virtual memory for userland programs
- A basic filesystem
- An init program that runs a minimal shell
- Basic system calls
- Text I/O stream using the UART
- Dynamic memory allocation for userland programs
- Signals(?) for userland programs
- Basic synchronization and IPC primitives
- Drivers for the processing environment
- TCP/IP networking stack

These capabilities are purposefully vague, as I have not made my choices for the implementations of each capability yet.

