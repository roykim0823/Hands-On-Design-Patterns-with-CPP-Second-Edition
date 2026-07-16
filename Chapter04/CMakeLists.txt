cmake_minimum_required(VERSION 3.14)
project(Chapter04 CXX)

include(${CMAKE_CURRENT_LIST_DIR}/../cmake/chapter_executables.cmake)

# The SKIP examples intentionally fail to compile (the book demonstrates the error)
chapter_executables(CXX_STANDARD 17
    SKIP 02b_std_swap_noncopyable 02d_std_swap_nonmovable 08_nonmember_swap_std
)
