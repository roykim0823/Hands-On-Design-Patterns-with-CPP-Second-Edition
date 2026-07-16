cmake_minimum_required(VERSION 3.14)
project(Chapter09 CXX)

include(${CMAKE_CURRENT_LIST_DIR}/../cmake/chapter_executables.cmake)

# 06b_poly_chain intentionally fails to compile (the book demonstrates the error)
chapter_executables(CXX_STANDARD 20
    SKIP 06b_poly_chain
)
