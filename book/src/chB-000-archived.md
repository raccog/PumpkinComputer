# Appendix B - Archived Development Information

This appendix chapter contains information that is no longer applicable to the main
chapters of this book. In order to preserve my previous ideas, they are archived here.
Each archive is labeled with the following date format: YYYY-MM-DD

NOTE: I may want to separate this into multiple files, but I don't want them all listed
in the mdbook table of contents. Not sure how I could do this...

- [2023-09-13: Programming Language Debate](#2023-09-13-programming-language-debate)

# 2023-09-13: Programming Language Debate

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


