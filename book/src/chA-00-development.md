# Appendix A - Development Information

This appendix includes my ideas on what tools and strategies I will utilize to
develop the Pumpkin Computer.

## Programming Languages

The choice of which programming languages to use is an important one. There are many
factors to consider, such as which programming concepts are supported, how the code
will be structured, which tools are supported, how easy it is to setup the development
environment, etc. Thus, the choice of which languages to use in each part of the
Pumpkin Computer will directly impact the development trajectory of the project.

### Hardware Description Language

__Chosen Language - _SystemVerilog___

Currently, I am using SystemVerilog as an HDL for developing the processor. This may
change, as I'm new to HDL development and don't have much experience with non-Verilog
languages.

I'm choosing to use SystemVerilog instead of Verilog for a few reasons.

The first reason is because SystemVerilog supports C-like structs and enums, while Verilog
does not. This allows me to make it more clear in the code which signals are related.

The second reason is because the `always` blocks are more precise in SystemVerilog. In
Verilog, there is only the `always` block which is used for both combinational
and synchronous circuits. SystemVerilog includes the `always_ff` block for synchronous
circuits and the `always_comb` block for combinational circuits. Similarly to the structs
and enums, this allows me to make the purpose of each block more clear.

### Processor Simulations

__Chosen Language - _C++___

The processor simulations will be written in C++. I chose C++ instead of writing the
simulations in SystemVerilog (or another language such as C) for a few reasons.

The first is because I am using Verilator to run simulations and it has a native C++
interface that provides me with all the control necessary to write decent simulations.
This is why I am not using another language such as C.

I am using C++ instead of SystemVerilog simply because I have more experience in C++.
To write simulations in SystemVerilog, I would need to learn more complex parts of the
language and I am unsure that this would benefit the project at all. I also think that
a simulation is easier to understand in a normal programming language instead of an HDL.

### Operating System

__Chosen Language - _C___

