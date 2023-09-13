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

After deciding between C, C++, and Rust, I have chosen C to write the operating system
in. This choice has pros and cons that are listed below.

#### Pros

__Minimal Language Abstractions__

Compared to C++ and Rust, C has a minimal amount of first-class language abstractions.
An advantage of using C for the operating system is that people studying the code won't need to understand the
implementation details of language abstractions, as would be necessary with C++ and Rust.
Some examples of these abstractions are classes/traits, templates/generics, and operator
overloading.

One counter to this is that I don't need to use all the abstractions provided by C++/Rust,
so it could be possible to use a subset of either language that only uses abstractions that
I believe are useful enough that they are worth the added complexity. I am actually considering
using a subset of C++ without classes because of the added errors around implicit type coercion
(see this example: <https://godbolt.org/z/WbE99G>. taken from [C xor C++ Programming](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n3065.pdf),
which has other good examples of some differences between C and C++).

Note that the absense of abstractions can also be considered a downside (see [cons](#cons)).

__Universal API__

By using only funtions and data structures, a lot of C code can automatically be imported
and used in C++ or Rust with minimal overhead. On the other side, there will often be some
overhead when importing C++ or Rust functions in another language. It would be necessary to
lower the abstraction levels to only use functions and data structures in an exported API.
As a few examples, you cannot directly import a Rust trait in C/C++ or a C++ class in C/Rust.

By having a universal API in C, I could potentially use C++ or Rust in the operating system
for future versions. Thus, C gives the advantage that I am not locked down to the language
by its abstractions.

__Support from Multiple Compilers__

One of the problems with using Rust is, as an emerging language, it is currently only supported
by LLVM and not GCC (though GCC support is potentially being worked on). C (and C++) have support
from LLVM, GCC, and many other smaller compilers (especially C). Since C is a comparatively small
language, I could even implement my own compiler if I want to in the future (... who knows? :D).
As older languages, C and C++ have had compiler support for much longer as well.

This problem doesn't really have direct consequences, but I simply feel better about using an
older, more supported language where its flaws are more well known. When working on operating
systems in Rust, I had some difficulties with implementing certain things that are necessary for
an operating system. A lot of these difficulties centered around how the compiler generates
executables. It felt much more difficult to control compilation output in Rust compared to C/C++.
However, note that I mainly used Cargo instead of directly using `rustc`, so that might be worth
a try to see how it feels.

#### Cons

__Minimal Language Abstractions__

While having a minimal amount of language abstractions is one of my main reasons for going with C, 
this also has some downsides.

One of these downsides is in memory safety. With no destructors, memory has to be allocated and
deallocated by manually calling the necessary functions. This requires more care to be taken
when dealing with memory allocations. This can also be considered a benefit, because having the
allocations and deallocations explicitly called could make it easier to determine where allocations
and deallocations are taking place in the code.

Another downside is that, when compared to Rust, first-class string support is lacking in C (and C++).
In Rust, the language has first-class support for UTF-8 strings, even without a standard library. As
I probably want to use UTF-8, this would be a benefit of using Rust. In C, I will need to implement
UTF-8 support manually. However, this can also be considered an upside, because if the Pumpkin Computer
has a built-in UTF-8 implementation, it will be more self-contained, which is a large part of the project's
goal.

__No Tagged Unions__

While C has enums, they are limited to being defined as integers and can only be compared using normal
if/else statements. Rust has [Tagged union](https://en.wikipedia.org/wiki/Tagged_union) enum types that
have a few major benefits over C's enums.

One benefit is that a Rust enum is not limited to being defined as an integer. They can also be defined
as a struct or a tuple, or any other Rust primitive. See the following examples for the differences
between C and Rust enums.

```c
// C
typedef enum {
    A = 0,
    B = 0xf,
    C = 20
} example_enum;
```

```rust
// Rust

// This enums is the same as the C example above
enum ExampleCLikeEnum {
    A = 0,
    B = 0xf,
    C = 20,
}

// This example is not possible to represent with C enums
enum ExampleRustEnum {
    D(char, bool),
    E{x: i32, y: f32},
    F(i32)
}
```
