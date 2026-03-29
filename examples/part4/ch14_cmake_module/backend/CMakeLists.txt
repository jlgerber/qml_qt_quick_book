qt_add_library(counterapp_backend STATIC)

qt_add_qml_module(counterapp_backend
    URI "com.example.backend"
    VERSION 1.0
    SOURCES
        counter.h
        counter.cpp
)

target_link_libraries(counterapp_backend PUBLIC
    Qt6::Core
    Qt6::Qml
)

target_include_directories(counterapp_backend PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
