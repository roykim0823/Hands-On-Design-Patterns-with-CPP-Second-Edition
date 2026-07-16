# Shared build logic for the chapter directories.
#
# Usage, from a ChapterNN/CMakeLists.txt:
#
#   include(${CMAKE_CURRENT_LIST_DIR}/../cmake/chapter_executables.cmake)
#   chapter_executables(
#       [CXX_STANDARD <17|20>]   # defaults to 17
#       [SKIP <name>...]         # examples that intentionally do not compile
#       [COMPILE_ONLY <name>...] # examples without main(); built as object libraries
#   )
#
# Builds one executable per src/*.cc. Sources that use Google Benchmark or
# GoogleTest are skipped with a message if the library is not installed.
include_guard(GLOBAL)

function(chapter_executables)
    # find_package is called here, not at file scope, so that the imported
    # targets (which are directory-scoped) exist in every chapter that calls
    # this function, even when all chapters are built from the top level
    set(THREADS_PREFER_PTHREAD_FLAG ON)
    find_package(Threads REQUIRED)
    # Google Benchmark and GoogleTest are optional
    find_package(benchmark QUIET)
    find_package(GTest QUIET)

    cmake_parse_arguments(ARG "" "CXX_STANDARD" "SKIP;COMPILE_ONLY" ${ARGN})
    if(NOT ARG_CXX_STANDARD)
        set(ARG_CXX_STANDARD 17)
    endif()

    file(GLOB sources "${CMAKE_CURRENT_SOURCE_DIR}/src/*.cc")
    foreach(source ${sources})
        # Get the filename without the path or extension ("src/hello.cc" -> "hello")
        get_filename_component(name ${source} NAME_WE)

        if(name IN_LIST ARG_SKIP)
            message(STATUS "Skipping ${name}: does not compile by design (see source comments)")
            continue()
        endif()

        if(name IN_LIST ARG_COMPILE_ONLY)
            add_library(${name} OBJECT ${source})
            set_target_properties(${name} PROPERTIES
                CXX_STANDARD ${ARG_CXX_STANDARD} CXX_STANDARD_REQUIRED ON)
            message(STATUS "Configured object library: ${name}")
            continue()
        endif()

        # Skip sources whose required library is not available
        file(STRINGS ${source} uses_benchmark REGEX "benchmark/benchmark\\.h")
        file(STRINGS ${source} uses_gtest REGEX "gtest/gtest\\.h")
        if(uses_benchmark AND NOT benchmark_FOUND)
            message(STATUS "Skipping ${name}: requires Google Benchmark (not found)")
            continue()
        endif()
        if(uses_gtest AND NOT GTest_FOUND)
            message(STATUS "Skipping ${name}: requires GoogleTest (not found)")
            continue()
        endif()

        add_executable(${name} ${source})
        set_target_properties(${name} PROPERTIES
            CXX_STANDARD ${ARG_CXX_STANDARD} CXX_STANDARD_REQUIRED ON)
        target_link_libraries(${name} PRIVATE Threads::Threads)
        if(uses_benchmark)
            target_link_libraries(${name} PRIVATE benchmark::benchmark)
        endif()
        if(uses_gtest)
            # Sources without their own main() get the one from gtest_main
            file(STRINGS ${source} has_main REGEX "int main")
            if(has_main)
                target_link_libraries(${name} PRIVATE GTest::gtest)
            else()
                target_link_libraries(${name} PRIVATE GTest::gtest_main)
            endif()
        endif()
        message(STATUS "Configured executable: ${name}")
    endforeach()
endfunction()
