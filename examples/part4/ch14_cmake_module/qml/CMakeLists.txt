qt_add_library(counterapp_qml STATIC)

qt_add_qml_module(counterapp_qml
    URI "com.example.app"
    VERSION 1.0
    QML_FILES
        Main.qml
)

target_link_libraries(counterapp_qml PUBLIC
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    counterapp_backend
)
