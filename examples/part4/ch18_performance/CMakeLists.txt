cmake_minimum_required(VERSION 3.27)
project(PerformanceApp VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick)

qt_standard_project_setup(REQUIRES 6.6)

qt_add_executable(performanceapp
    main.cpp
)

qt_add_qml_module(performanceapp
    URI "com.example.performance"
    VERSION 1.0
    QML_FILES
        qml/Main.qml
    SOURCES
        sensormodel.h
        sensormodel.cpp
)

target_link_libraries(performanceapp PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
)
