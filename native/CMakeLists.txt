cmake_minimum_required(VERSION 3.10)
project(SwoftLang)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Try to find JDK 21 specifically
if(DEFINED JDK_INCLUDE_PATH)
    set(JAVA_INCLUDE_PATH ${JDK_INCLUDE_PATH})
    set(JAVA_INCLUDE_PATH2 ${JDK_INCLUDE_PATH_PLATFORM})
    message(STATUS "Using JDK include path from settings: ${JAVA_INCLUDE_PATH}")
else()
    # JAVA_HOME not set, try to find JDK 21 in common locations
    message(STATUS "JAVA_HOME not set, searching for JDK 21")
    
    # Common JDK 21 installation paths on Windows
    set(JDK21_PATHS
        "C:/Program Files/Java/jdk-21"
        "C:/Program Files/Eclipse Adoptium/jdk-21"
        "C:/Program Files/Microsoft/jdk-21"
        "C:/Program Files/BellSoft/LibericaJDK-21"
        "C:/Program Files/Amazon Corretto/jdk21"
    )
    
    # Find JDK 21
    foreach(JDK_PATH ${JDK21_PATHS})
        if(EXISTS "${JDK_PATH}/bin/javac.exe")
            set(JAVA_HOME ${JDK_PATH})
            message(STATUS "Found JDK 21 at ${JAVA_HOME}")
            break()
        endif()
    endforeach()
    
    if(NOT DEFINED JAVA_HOME)
        message(FATAL_ERROR "JDK 21 not found. Please set JAVA_HOME to point to JDK 21")
    endif()
endif()


# Verify JDK path
if(NOT EXISTS "${JAVA_HOME}/include/jni.h")
    message(FATAL_ERROR "jni.h not found at ${JAVA_HOME}/include/jni.h")
endif()

if(NOT EXISTS "${JAVA_HOME}/include/win32/jni_md.h")
    message(FATAL_ERROR "jni_md.h not found at ${JAVA_HOME}/include/win32/jni_md.h")
endif()

include_directories("${JAVA_HOME}/include")
if(WIN32)
    include_directories("${JAVA_HOME}/include/win32")
elseif(APPLE)
    include_directories("${JAVA_HOME}/include/darwin")
elseif(UNIX)
    include_directories("${JAVA_HOME}/include/linux")
endif()

include_directories(
    ${CMAKE_SOURCE_DIR}/include
    ${CMAKE_SOURCE_DIR}/src
    ${CMAKE_SOURCE_DIR}/src/parser
    ${CMAKE_SOURCE_DIR}/src/parser/command
    ${CMAKE_SOURCE_DIR}/src/parser/block
    ${CMAKE_SOURCE_DIR}/src/parser/event
    ${CMAKE_SOURCE_DIR}/src/jni
    ${CMAKE_SOURCE_DIR}/src/jni/implementations
    ${CMAKE_SOURCE_DIR}/src/types
    ${CMAKE_SOURCE_DIR}/src/ast
    ${CMAKE_SOURCE_DIR}/src/ast/expressions
    ${CMAKE_SOURCE_DIR}/src/ast/statements
)

file(GLOB_RECURSE SOURCES "src/*.cpp" "src/*.c")
add_library(SwoftLang SHARED ${SOURCES})

# For Visual Studio, explicitly set the C++17 flag
if(MSVC)
    target_compile_options(SwoftLang PRIVATE /std:c++17)
endif()

# Set output directory to match Java's native library path expectations
set_target_properties(SwoftLang PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY "${CMAKE_SOURCE_DIR}/../java/src/main/resources"
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_SOURCE_DIR}/../java/src/main/resources"
)

# Print all include directories to verify
get_property(dirs DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PROPERTY INCLUDE_DIRECTORIES)
message(STATUS "Include directories:")
foreach(dir ${dirs})
    message(STATUS "  ${dir}")
endforeach()
