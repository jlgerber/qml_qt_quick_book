cmake_minimum_required(VERSION 3.27)
project(CppTypesApp VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick)

qt_standard_project_setup(REQUIRES 6.6)

qt_add_executable(cpptypesapp
    main.cpp
    backend/temperature.h
    backend/temperature.cpp
    backend/unit.h
)

qt_add_qml_module(cpptypesapp
    URI "com.example.types"
    VERSION 1.0
    QML_FILES
        qml/Main.qml
    SOURCES
        backend/temperature.h
        backend/temperature.cpp
        backend/unit.h
)

target_include_directories(cpptypesapp PRIVATE backend)

target_link_libraries(cpptypesapp PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
)
