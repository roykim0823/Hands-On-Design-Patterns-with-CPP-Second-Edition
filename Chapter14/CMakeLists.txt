cmake_minimum_required(VERSION 3.14)
project(Chapter14 CXX)

include(${CMAKE_CURRENT_LIST_DIR}/../cmake/chapter_executables.cmake)

# 15_template_customization intentionally fails to compile (the book demonstrates the error)
chapter_executables(CXX_STANDARD 17
    SKIP 15_template_customization
)
