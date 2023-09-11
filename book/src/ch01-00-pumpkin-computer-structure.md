# The Pumpkin Computer Structure

The Pumpkin Computer contains an HDL implementation of a RISC-V processing environment along with a
minimal desktop operating system. This book describes my plans for version 1.0 of the Pumpking Computer.
Some notes may be included to describe additions that I want to make in future versions.

The next 3 chapters of this book provide an overview of the RISC-V processing environment, operating
system, and userspace environment respectively.

## Version 1.0 Structure

In version 1.0, the RISC-V processing environment will contain a minimal set of modules that are
necessary to support the operating system. Similarly, the operating system will contain infrastructure
required to support terminal-based userspace programs.

The userspace programs in version 1.0 will be minimal, but should properly demonstrate the capabilities
of the Pumpkin Computer. See the userspace chapter for examples of programs.

### Note: Future Versions of Userspace

Although they will be restricted to a text-based terminal in version 1.0, future versions will
have a GUI.
