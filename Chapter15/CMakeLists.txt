cmake_minimum_required(VERSION 3.14)
project(Chapter15 CXX)

include(${CMAKE_CURRENT_LIST_DIR}/../cmake/chapter_executables.cmake)

# 25_conversions_sfinae_NOT intentionally fails to compile (the book demonstrates the error)
chapter_executables(CXX_STANDARD 20
    SKIP 25_conversions_sfinae_NOT
)
