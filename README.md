# Hands-On Design Patterns with C++ - Second Edition

<a href="https://www.packtpub.com/product/hands-on-design-patterns-with-c-second-edition/9781804611555?utm_source=github&utm_medium=repository&utm_campaign="><img src="https://content.packt.com/B19262/cover_image_small.jpg" alt="Hands-On Design Patterns with C++ - Second Edition" height="256px" align="right"></a>

This is the code repository for [Hands-On Design Patterns with C++ - Second Edition](https://www.packtpub.com/product/hands-on-design-patterns-with-c-second-edition/9781804611555?utm_source=github&utm_medium=repository&utm_campaign=), published by Packt.

**Solve common C++ problems with modern design patterns and build robust applications**

## What is this book about?
Design patterns is a library of reusable components designed for software architecture, not for concrete implementation. In this book, you’ll learn to recognize and apply various C++ design patterns and idioms. In this second edition, you’ll gain a deep understanding of design patterns and become empowered to create robust, reusable, and maintainable code.

This book covers the following exciting features:
* Recognize the most common design patterns used in C++
* Understand how to use C++ generic programming to solve common design problems
* Explore the most powerful C++ idioms, their strengths, and their drawbacks
* Rediscover how to use popular C++ idioms with generic programming
* Discover new patterns and idioms made possible by language features of C++17 and C++20
* Understand the impact of design patterns on the program’s performance

If you feel this book is for you, get your [copy](https://www.amazon.com/dp/1804611557) today!

<a href="https://www.packtpub.com/?utm_source=github&utm_medium=banner&utm_campaign=GitHubBanner"><img src="https://raw.githubusercontent.com/PacktPublishing/GitHub/master/GitHub.png" 
alt="https://www.packtpub.com/" border="5" /></a>

## Instructions and Navigations
All of the code is organized into folders. For example, Chapter02.

The code will look like the following:
```
class Database {
   class Storage { ... }; // Disk storage Storage S;
   class Index { ... }; // Memory index Index I;
   public:
     void insert(const Record& r);
 ...
};
```

## How to Build

Each `ChapterNN/` directory contains its examples as `src/*.cc`, built as one executable per file.

Requirements: CMake 3.14+ and a C++20 compiler. [Google Benchmark](https://github.com/google/benchmark) and [GoogleTest](https://github.com/google/googletest) are optional — examples that need them are skipped with a message when the library is not installed. A few examples that intentionally fail to compile (the book demonstrates the compile error) are also skipped; see the `SKIP` lists in the chapter `CMakeLists.txt` files.

### Entire build

Configure once from the repository root, then build everything or any single example by target name:

```sh
cmake --preset default            # configures into build/ (Debug, exports compile_commands.json)
cmake --build build --parallel 8  # build all chapters
cmake --build build --target 01_visitor   # or build a single example
./build/Chapter17/01_visitor              # run it
```

For the benchmark examples, use the optimized build — timing numbers from a Debug build are meaningless:

```sh
cmake --preset release
cmake --build build-release --parallel 8
```

### Per-chapter build

Every chapter is also an independent CMake project. Presets only apply at the repository root, so pass the options yourself. For example, inside a chapter directory:

```sh
cd Chapter04
cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug
cmake --build build --parallel 8
./build/01a_vector_swap
```

**Following is what you need for this book:**
This book is for experienced C++ developers and programmers who wish to learn about software design patterns and principles and apply them to create robust, reusable, and easily maintainable programs and software systems.

With the following software and hardware list you can run all code files present in the book (Chapter 1-18).
### Software and Hardware List
| Chapter | Software required | OS required |
| -------- | ------------------------------------ | ----------------------------------- |
| 1 |  GCC, Clang or Visual Studio  | Windows, Mac OS X, and Linux (Any) |



We also provide a PDF file that has color images of the screenshots/diagrams used in this book. [Click here to download it]().

## Errata
* Page 64 (code example under 'Expressing exclusive ownership'): **DoWork()** _should be_ **Work()**

### Related products
* Template Metaprogramming with C++ [[Packt]](https://www.packtpub.com/product/template-metaprogramming-with-c/9781803243450?utm_source=github&utm_medium=repository&utm_campaign=) [[Amazon]](https://www.amazon.com/dp/1803243457)

* C++20 STL Cookbook [[Packt]](https://www.packtpub.com/product/c20-stl-cookbook/9781803248714?utm_source=github&utm_medium=repository&utm_campaign=) [[Amazon]](https://www.amazon.com/dp/1803248718)


## Get to Know the Author
**Fedor G. Pikus**
is a Technical Fellow and head of the Advanced Projects Team in Siemens Digital Industries Software. His responsibilities include planning the long-term technical direction of Calibre products, directing and training the engineers who work on these products, design, and architecture of the software, and researching new design and software technologies.
His earlier positions included a Chief Scientist at Mentor Graphics (acquired by Siemens Software), a Senior Software Engineer at Google, and a Chief Software Architect for Calibre Design Solutions at Mentor Graphics. He joined Mentor Graphics in 1998 when he made a switch from academic research in computational physics to the software industry.
Fedor is a recognized expert in high-performance computing and C++. He is the author of two books on C++ and software design, has presented his works at CPPNow, CPPCon, SD West, DesignCon, and in software development journals, and is also an O’Reilly author. Fedor has over 30 patents and over 100 papers and conference presentations on physics, EDA, software design, and C++ language.


