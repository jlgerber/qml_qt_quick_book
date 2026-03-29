#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>

#include "taskmodel.h"
#include "taskfilterproxy.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    // Create the source model and the sort/filter proxy.
    TaskModel taskModel;

    // Seed a few initial tasks so the UI is non-empty on first launch.
    taskModel.addTask(QStringLiteral("Buy groceries"),    false, 2);
    taskModel.addTask(QStringLiteral("Write unit tests"), false, 1);
    taskModel.addTask(QStringLiteral("Fix bug #42"),      false, 3);
    taskModel.addTask(QStringLiteral("Read Qt docs"),     true,  1);

    TaskFilterProxy proxy;
    proxy.setSourceModel(&taskModel);

    QQmlApplicationEngine engine;

    // Expose both objects to QML via initial properties so QML does not
    // need to instantiate them itself (the C++ side owns their lifetime).
    engine.setInitialProperties({
        { QStringLiteral("taskModel"),  QVariant::fromValue(&taskModel) },
        { QStringLiteral("taskProxy"),  QVariant::fromValue(&proxy)     }
    });

    engine.loadFromModule("com.example.models", "Main");

    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}
