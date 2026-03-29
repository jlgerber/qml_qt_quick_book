cmake_minimum_required(VERSION 3.21)
project(tst_taskmodel LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Let CMake find the Qt installation.  Set CMAKE_PREFIX_PATH if Qt is not on
# the default search path, e.g.:
#   cmake -DCMAKE_PREFIX_PATH=/opt/Qt/6.7.0/gcc_64 -S . -B build
find_package(Qt6 REQUIRED COMPONENTS Test)

qt_standard_project_setup()

# -------------------------------------------------------------------------- #
# Test executable
# -------------------------------------------------------------------------- #
qt_add_executable(tst_taskmodel
    tst_taskmodel.cpp
)

target_link_libraries(tst_taskmodel
    PRIVATE
        Qt6::Test
)

# Ensure the MOC-generated file is found at compile time
set_target_properties(tst_taskmodel PROPERTIES
    AUTOMOC ON
)

# -------------------------------------------------------------------------- #
# CTest integration
# -------------------------------------------------------------------------- #
enable_testing()

add_test(
    NAME    tst_taskmodel
    COMMAND tst_taskmodel
)

# Optional: make ctest output verbose for CI pipelines
list(APPEND CMAKE_CTEST_ARGUMENTS "--output-on-failure")
