# Chapter 14: Qt Quick from C++: Project Structure and Build Systems

## CMake with Qt6: `qt_add_qml_module`, Backing Types, and URI Namespaces

Qt 6 standardized on CMake as the primary build system. The Qt CMake integration provides high-level commands that handle QML module registration, resource compilation, and type stub generation automatically — replacing the manual `RESOURCES` lists and `qmlRegisterType` calls of the Qt 5 era.

### Minimal Project Structure

```
my_app/
├── CMakeLists.txt
├── main.cpp
├── backend/
│   ├── CMakeLists.txt
│   ├── counter.h
│   ├── counter.cpp
│   └── contactmodel.h
│   └── contactmodel.cpp
└── qml/
    ├── CMakeLists.txt
    ├── Main.qml
    ├── components/
    │   └── ContactDelegate.qml
    └── screens/
        └── ContactListScreen.qml
```

### Root `CMakeLists.txt`

```cmake
cmake_minimum_required(VERSION 3.27)
project(MyApp VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 6.6 REQUIRED COMPONENTS
    Core Gui Qml Quick QuickControls2
)

qt_standard_project_setup(REQUIRES 6.6)

add_subdirectory(backend)
add_subdirectory(qml)

qt_add_executable(myapp main.cpp)

target_link_libraries(myapp PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    myapp_backend
    myapp_qml
)
```

### `qt_add_qml_module`

`qt_add_qml_module` is the central command for registering a QML module. It:

- Compiles QML files as resources
- Generates type registration code from `QML_ELEMENT` macros
- Produces `qmltypes` files for tooling
- Optionally invokes `qmlsc` for ahead-of-time compilation

```cmake
# backend/CMakeLists.txt
qt_add_library(myapp_backend STATIC)

qt_add_qml_module(myapp_backend
    URI "com.example.backend"
    VERSION 1.0
    SOURCES
        counter.h counter.cpp
        contactmodel.h contactmodel.cpp
    # No QML_FILES here — backend has no QML
)

target_link_libraries(myapp_backend PUBLIC
    Qt6::Core Qt6::Qml Qt6::Quick
)
```

```cmake
# qml/CMakeLists.txt
qt_add_library(myapp_qml STATIC)

qt_add_qml_module(myapp_qml
    URI "com.example.app"
    VERSION 1.0
    QML_FILES
        Main.qml
        components/ContactDelegate.qml
        screens/ContactListScreen.qml
    RESOURCE_PREFIX "/qt/qml"
)

target_link_libraries(myapp_qml PUBLIC
    Qt6::Quick
    myapp_backend
)
```

### The `RESOURCE_PREFIX` Convention

Qt 6.5+ standardizes on `/qt/qml` as the resource prefix for QML modules. QML files under this prefix are accessible as `qrc:/qt/qml/<URI path>/FileName.qml`. The engine automatically searches this prefix when resolving module URIs — no `addImportPath` needed.

### `main.cpp`

```cpp
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickStyle>

// Include the generated module registration header
#include "myapp_backend/myapp_backendplugin.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    QQuickStyle::setStyle("Material");

    QQmlApplicationEngine engine;

    // Qt 6.5+: modules are auto-registered via linker initialization
    // For older versions or static builds, explicit registration may be needed:
    // MyApp_backendPlugin::registerTypes("com.example.backend");

    engine.loadFromModule("com.example.app", "Main");

    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}
```

For static builds (`STATIC` libraries), the linker may strip unreferenced symbols including the auto-registration functions. Add explicit linker hints:

```cmake
target_link_libraries(myapp PRIVATE
    Qt6::QmlImportScanner
)
qt_import_qml_plugins(myapp)   # ensures static QML plugins are linked
```

---

## The QML Type Registration System: `QML_ELEMENT`, `QML_SINGLETON`, `QML_FOREIGN`

These macros are placed in the class definition header and processed by `qt_add_qml_module`'s code generator (`qmlcachegen`) to produce registration boilerplate.

### `QML_ELEMENT`

Registers the C++ class as a creatable QML type. The QML type name equals the C++ class name by default:

```cpp
// counter.h
#pragma once
#include <QObject>
#include <QtQml/qqml.h>

class Counter : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(int value READ value WRITE setValue NOTIFY valueChanged)

public:
    explicit Counter(QObject *parent = nullptr);
    int value() const;
    void setValue(int v);

public slots:
    void increment();
    void reset();

signals:
    void valueChanged(int value);

private:
    int m_value = 0;
};
```

In QML (after `import com.example.backend`):

```qml
Counter {
    id: counter
    onValueChanged: console.log("Count:", value)
}
```

### `QML_SINGLETON`

Registers as a singleton. The engine calls the static `create()` factory or the constructor if no factory is provided:

```cpp
class AppSettings : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(QString theme READ theme WRITE setTheme NOTIFY themeChanged)

public:
    // Static factory — called by the engine
    static AppSettings *create(QQmlEngine *engine, QJSEngine *scriptEngine)
    {
        Q_UNUSED(engine)
        Q_UNUSED(scriptEngine)
        static AppSettings instance;
        return &instance;
    }

    // ... rest of implementation
};
```

### `QML_ANONYMOUS`

Registers a type that can be used as a property type (returned from C++ functions, held in `Q_PROPERTY`) but cannot be instantiated in QML:

```cpp
class SearchResult : public QObject
{
    Q_OBJECT
    QML_ANONYMOUS

    Q_PROPERTY(QString title READ title CONSTANT)
    Q_PROPERTY(QUrl url READ url CONSTANT)

public:
    SearchResult(QString title, QUrl url, QObject *parent = nullptr);
    QString title() const { return m_title; }
    QUrl url() const { return m_url; }

private:
    QString m_title;
    QUrl m_url;
};
```

### `QML_NAMED_ELEMENT`

Override the QML name when the C++ name is unsuitable:

```cpp
class InternalHttpClient : public QObject
{
    Q_OBJECT
    QML_NAMED_ELEMENT(HttpClient)   // exposed as "HttpClient" in QML
    // ...
};
```

### `QML_FOREIGN`

Registers a type defined in external code (a third-party library or a Qt class) that you cannot modify to add macros. Create a wrapper struct:

```cpp
// Expose QProcess to QML without modifying Qt's source
struct QProcessForeign
{
    Q_GADGET
    QML_FOREIGN(QProcess)
    QML_NAMED_ELEMENT(Process)
    QML_UNCREATABLE("Use processManager.create()")
};
```

### `QML_UNCREATABLE`

Marks a type as non-instantiable (error message shown if QML tries to create it directly), while still allowing it as a property type:

```cpp
class AbstractDevice : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("AbstractDevice cannot be instantiated directly")
    // ...
};
```

### `QML_INTERFACE`

Declares a C++ interface (pure virtual class) as a QML interface type. QML does not use this for instantiation but tooling and `qmlsc` use it for type checking.

---

## `qmllint` and `qmlsc`: Static Analysis and Ahead-of-Time Compilation

### `qmllint`

`qmllint` performs static analysis on QML files, catching:
- Undefined properties and signals
- Type mismatches
- Deprecated API usage
- Import issues
- Unused imports

```bash
qmllint --qmltypes path/to/module.qmltypes qml/Main.qml
```

With CMake, enable linting as a build step:

```cmake
qt_add_qml_module(myapp_qml
    URI "com.example.app"
    VERSION 1.0
    QML_FILES Main.qml
    ENABLE_TYPE_COMPILER   # enables qmlsc
)

# Add linting target
set_target_properties(myapp_qml PROPERTIES
    QT_QML_MODULE_LINTING ON
)
```

Run `cmake --build . --target myapp_qml_qmllint` to lint all QML files in the module.

Common `qmllint` warning categories and how to address them:

| Warning | Fix |
|---|---|
| `Unqualified access` | Use `id.property` instead of bare `property` |
| `Deprecated` | Update to the current API |
| `Missing type` | Ensure all imports are present |
| `Type mismatch` | Correct the type annotation or cast |

### `qmlsc` (QML Static Compiler)

`qmlsc` compiles QML to C++ during the build, replacing runtime JavaScript interpretation with compiled C++ for binding expressions and simple functions. Benefits:

- Faster startup (no JIT warm-up for bindings)
- Better type checking at compile time
- Potentially faster runtime for property-access-heavy bindings

Enable in `qt_add_qml_module`:

```cmake
qt_add_qml_module(myapp_qml
    URI "com.example.app"
    VERSION 1.0
    QML_FILES Main.qml
    ENABLE_TYPE_COMPILER    # CMake ≥ 3.25, Qt ≥ 6.4
)
```

**Requirements for `qmlsc` compatibility**:
- All properties must have explicit type annotations
- No `Qt.createQmlObject()` with dynamic strings
- No `eval()` or other reflection
- All imported types must have `qmltypes` metadata

**Verify compatibility**: Set `QT_QMLCOMPILER_PASS_WARNINGS=1` in the environment during the build to see which parts of your QML `qmlsc` could not compile and why.

### Generating `qmltypes` for Your Modules

`qmltypes` files are metadata that `qmllint`, `qmlsc`, and IDEs use to understand your C++ types. `qt_add_qml_module` generates them automatically:

```
build/
└── com/example/backend/
    ├── backend.qmltypes     # generated from QML_ELEMENT macros
    └── qmldir               # generated module declaration
```

For standalone use (shipping a library to other developers), install the `qmltypes` alongside the header files.

---

## Summary

Qt 6's CMake integration with `qt_add_qml_module` unifies C++ type registration, QML resource compilation, and tooling metadata generation into a single declarative command. The `QML_ELEMENT` macro family provides a clean, in-header API for exposing C++ types to QML without separate registration calls scattered across `main.cpp`. `qmllint` catches QML errors at build time; `qmlsc` compiles QML bindings to C++ for faster startup and tighter type safety. Together, these tools make large-scale C++/QML projects tractable and auditable.
