cmake_minimum_required(VERSION 3.14)
project(Chapter03 CXX)

include(${CMAKE_CURRENT_LIST_DIR}/../cmake/chapter_executables.cmake)

chapter_executables(CXX_STANDARD 20)
