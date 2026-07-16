cmake_minimum_required(VERSION 3.14)
project(Chapter12 CXX)

include(${CMAKE_CURRENT_LIST_DIR}/../cmake/chapter_executables.cmake)

# 01_no_access intentionally fails to compile; the COMPILE_ONLY examples have no main()
chapter_executables(CXX_STANDARD 17
    SKIP 01_no_access
    COMPILE_ONLY 08_friend_forward 09_friend_forward
)
