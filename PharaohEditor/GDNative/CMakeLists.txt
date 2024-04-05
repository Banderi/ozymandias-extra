cmake_minimum_required(VERSION 3.22)
project(GDNative)

set(CMAKE_CXX_STANDARD 14)

set(GODOT_HEADER_INCLUDES
    ${PROJECT_SOURCE_DIR}/godot-cpp/godot-headers
    ${PROJECT_SOURCE_DIR}/godot-cpp/include
    ${PROJECT_SOURCE_DIR}/godot-cpp/include/core
    ${PROJECT_SOURCE_DIR}/godot-cpp/include/gen)

set(SOURCE_FILES
    library.cpp
    gdlibrary.cpp
    Memory.cpp)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${PROJECT_SOURCE_DIR}/..)

add_library(GDN SHARED ${SOURCE_FILES})

target_link_libraries(GDN ${PROJECT_SOURCE_DIR}/godot-cpp/bin/libgodot-cpp.windows.debug.64.a)
target_include_directories(GDN PRIVATE ${GODOT_HEADER_INCLUDES})

set_property(TARGET GDN APPEND_STRING PROPERTY COMPILE_FLAGS "-fPIC -Wwrite-strings")
set_property(TARGET GDN APPEND_STRING PROPERTY LINK_FLAGS "-static -static-libgcc -static-libstdc++") # the -static flag is what fixes the error!