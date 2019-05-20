cmake_minimum_required(VERSION 3.0.0 FATAL_ERROR)

project("stl_container_test_cpp" CXX)

set(CMAKE_VERBOSE_MAKEFILE ON)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_library(stl_container_test_cpp allocator_cpp.cpp array_cpp.cpp new_cpp.cpp string_cpp.cpp string_view_cpp.cpp vector_cpp.cpp)

target_include_directories(stl_container_test_cpp PRIVATE .)

if(WIN32)
	set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} /MT")
	set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} /MTd")
endif()
