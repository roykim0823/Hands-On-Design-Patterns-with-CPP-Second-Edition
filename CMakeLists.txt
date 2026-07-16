cmake_minimum_required(VERSION 3.14)
project(HandsOnDesignPatternsWithCpp CXX)

# Build every chapter at once; each ChapterNN can also be built on its own
# with: cmake -S ChapterNN -B build && cmake --build build
foreach(N RANGE 1 18)
    if(N LESS 10)
        set(N "0${N}")
    endif()
    add_subdirectory(Chapter${N})
endforeach()
