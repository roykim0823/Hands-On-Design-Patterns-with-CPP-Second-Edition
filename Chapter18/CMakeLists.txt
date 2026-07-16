cmake_minimum_required(VERSION 3.14)
project(Chapter18 CXX)

include(${CMAKE_CURRENT_LIST_DIR}/../cmake/chapter_executables.cmake)

# The global 'index' in these examples clashes with POSIX ::index() on macOS
chapter_executables(CXX_STANDARD 20
    SKIP 16_atomic_index 27_monitor
)
