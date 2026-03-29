#include <QGuiApplication>
#include <QQmlApplicationEngine>

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    QQmlApplicationEngine engine;

    // Load the root QML component from the registered QML module.
    // "com.example.app" is the URI declared in qml/CMakeLists.txt and
    // "Main" is the component name derived from Main.qml.
    engine.loadFromModule("com.example.app", "Main");

    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}
