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

__Chosen Language - _Unsure___

I am still unsure of the language(s) that I want to use for the operating system. This
sections describes which languages I am considering and why.

Currently, I am debating using one of three languages; C, C++, or Rust.

#### First-Class Language Constructs

With no first-class support for classes (or any advanced language construct) C might be
the language with the most "clarity". By this, I mean that in C++ and Rust, there are
often hidden procedures being run without being explicitly called as a function. There
are class constructors and/or destructors, iterators, and operator overloading (along with
other complex language constructs) that could make it more difficult to understand the
purpose of a piece of code. In other words, C++ and Rust use more first-class abstractions
that C does not. This allows C++ and Rust to be more expressive with fewer lines of code,
but it is a tradeoff between the clarity of C.

However, this tradeoff means that Rust/C++ would be more beneficial in the areas where
first-class abstractions are useful. One example is templating in C++ and generics in Rust.
This allows a function to run on multiple data types as long as each data type implements the
required interface. Another example is the first-class support for UTF-8 strings in Rust.
In C or C++, I would need to provide my own UTF-8 support and it would make working with
strings more difficult in C/C++ compared to Rust.

#### Compiler Support

Though it's not as important of an issue, it is still one that I want to write down. C and C++
both have much more diverse compiler support than Rust. C/C++ are both implemented in GCC and
LLVM along with other smaller compilers. Meanwhile, Rust only has major support from LLVM,
though I think GCC support is being worked on.

#### Build Systems

While C/C++ don't have built-in support for a build system, Make and CMake are commonly used.
Rust can be compiled by calling `rustc` in Make or CMake, but it has native support for the
Cargo build system, so it would be preferrable to use Cargo if possible.

Even though native support for a build system is beneficial because the build system is made
specifically to interact with the language, it can also be a downside. I have worked with an
operating system using Cargo before, and it does necessitate a few creative solutions to build
problems. One of these problems is with invoking external tools such as the binutils toolset.
Cargo's support for this is somewhat complex and requires writing a Rust program that, in turn,
invokes the external tools depending on what command line arguments are given to Cargo. See
"cargo xtask" for examples of this solution.

