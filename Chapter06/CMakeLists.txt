cmake_minimum_required(VERSION 3.14)
project(Chapter06 CXX)

include(${CMAKE_CURRENT_LIST_DIR}/../cmake/chapter_executables.cmake)

# 02_unique_ptr intentionally fails to compile (the book demonstrates the error)
chapter_executables(CXX_STANDARD 20
    SKIP 02_unique_ptr
    COMPILE_ONLY 07_smartptr_ext
)

# 07_smartptr_ext.cc has no main(); it provides get_raw_ptr() for 07_smartptr
if(TARGET 07_smartptr)
    target_link_libraries(07_smartptr PRIVATE 07_smartptr_ext)
endif()
