cmake_minimum_required(VERSION 3.27)
project(CounterApp VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick)

qt_standard_project_setup(REQUIRES 6.6)

add_subdirectory(backend)
add_subdirectory(qml)

qt_add_executable(counterapp
    main.cpp
)

target_link_libraries(counterapp PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    counterapp_backend
    counterapp_qml
)
