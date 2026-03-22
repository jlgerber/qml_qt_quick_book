# Chapter 9: Qt for Python (PySide6): Architecture and Tooling

## Shiboken Bindings: How C++ Types Are Exposed to Python

PySide6 is the official Qt for Python binding library, maintained by The Qt Company. It exposes the Qt C++ API to Python through *Shiboken6*, a binding generator that inspects Qt's C++ headers and generates Python extension modules (`.so`/`.pyd` files) containing the glue code between Python objects and Qt C++ objects.

### The Binding Architecture

For each Qt C++ class, Shiboken generates:

1. **A Python type object**: The `PySide6.QtCore.QObject` type, for example, wraps `QObject*`.
2. **Method wrappers**: Each `Q_INVOKABLE`, public slot, and public member function becomes a callable Python function.
3. **Property descriptors**: `Q_PROPERTY` declarations become Python descriptors with `__get__` and `__set__` methods.
4. **Signal objects**: Each signal becomes a `PySide6.QtCore.Signal` descriptor that supports `connect()`, `disconnect()`, and `emit()`.

When you access a property in Python:

```python
label = QLabel("Hello")
text = label.text()     # calls generated wrapper -> QLabel::text() -> Python str
label.setText("World")  # Python str -> generated wrapper -> QLabel::setText()
```

The generated code handles:
- Reference counting synchronization between Python's GC and Qt's parent-child ownership
- Type conversion between Python types and Qt types (`str` ↔ `QString`, `list` ↔ `QList`, etc.)
- Signal-slot connections across the Python/C++ boundary

### Memory Model

PySide6 objects follow a dual ownership model:

**Python-owned**: The Python GC manages lifetime. When the Python reference count drops to zero, the object is deleted. This applies to Qt objects with no C++ parent.

**C++-owned**: Qt's parent-child mechanism owns the object. Even if Python holds no reference, the object lives until its C++ parent is deleted. PySide6 tracks these objects internally to prevent double deletion.

```python
parent = QWidget()
child = QLabel(parent)  # C++ owned — parent=parent
del child               # Python reference gone, but QLabel lives (owned by parent)
parent.show()           # QLabel still shows correctly
```

The dangerous case: a C++-owned object outliving the Python wrapper. If `parent` is deleted from C++ (e.g., by a C++ function), accessing the Python `parent` object raises `RuntimeError: Internal C++ object already deleted`.

### Type System and Conversion

Shiboken's type conversion table for common types:

| Python type | Qt type |
|---|---|
| `str` | `QString` |
| `bytes` | `QByteArray` |
| `int` | `int`, `qint64`, `uint`, enum values |
| `float` | `double`, `float` |
| `bool` | `bool` |
| `list[T]` | `QList<T>` |
| `dict` | `QVariantMap` / `QHash` |
| `tuple` | `QSize`, `QPoint`, `QRect` (for 2/4-tuples in some contexts) |
| `None` | `nullptr` |
| `object` | `QVariant` |

For Qt value types without a natural Python equivalent (`QColor`, `QFont`, `QMatrix4x4`), PySide6 wraps them as Python objects. They behave like Python objects but are backed by the C++ value type.

---

## The `QmlElement`, `QmlSingleton`, and `QmlAnonymous` Decorators

Qt 6.3+ introduced a class-decorator approach for registering Python classes with the QML type system, mirroring the C++ `QML_ELEMENT` macro family.

### `QmlElement`

`@QmlElement` registers a Python `QObject` subclass as a QML type. The class name becomes the QML type name; the URI and version are taken from the enclosing `QmlModule` or specified in the decorator:

```python
from PySide6.QtCore import QObject, Property, Signal, Slot
from PySide6.QtQml import QmlElement

QML_IMPORT_NAME = "com.example.backend"
QML_IMPORT_MAJOR_VERSION = 1

@QmlElement
class Counter(QObject):
    valueChanged = Signal(int)

    def __init__(self, parent=None):
        super().__init__(parent)
        self._value = 0

    @Property(int, notify=valueChanged)
    def value(self):
        return self._value

    @value.setter
    def value(self, v):
        if self._value != v:
            self._value = v
            self.valueChanged.emit(v)

    @Slot()
    def increment(self):
        self.value += 1
```

In QML:

```qml
import com.example.backend

Counter {
    id: counter
    onValueChanged: console.log("count:", value)
}
Button {
    text: "Increment"
    onClicked: counter.increment()
}
```

### `QmlSingleton`

`@QmlSingleton` combined with `@QmlElement` registers the type as a QML singleton — one shared instance for the entire engine:

```python
@QmlElement
@QmlSingleton
class AppSettings(QObject):
    themeChanged = Signal(str)

    def __init__(self, parent=None):
        super().__init__(parent)
        self._theme = "dark"

    @Property(str, notify=themeChanged)
    def theme(self):
        return self._theme
```

QML accesses it without instantiating:

```qml
import com.example.backend

Rectangle {
    color: AppSettings.theme === "dark" ? "#1e1e2e" : "#eff1f5"
}
```

The singleton instance is created on first access by the engine.

### `QmlAnonymous`

`@QmlAnonymous` registers a type that can be used as a property value type in QML but cannot be instantiated directly by QML code. Use this for types that only appear as the return value of a C++/Python function:

```python
@QmlAnonymous
class SearchResult(QObject):
    def __init__(self, title, url, parent=None):
        super().__init__(parent)
        self._title = title
        self._url = url

    @Property(str, constant=True)
    def title(self): return self._title

    @Property(str, constant=True)
    def url(self): return self._url
```

QML can hold a reference and read properties, but cannot write `SearchResult { }` in a QML file.

### `QmlNamedElement`

When the QML name should differ from the Python class name:

```python
@QmlElement
@QmlNamedElement("FileIO")
class PythonFileHelper(QObject):
    ...
```

---

## Project Structure, `pyproject.toml`, and the PySide6 Build System

### Project Layout

A well-organized PySide6 project separates Python backend code from QML frontend code:

```
my_app/
├── pyproject.toml
├── main.py
├── backend/
│   ├── __init__.py
│   ├── models.py           # QAbstractItemModel subclasses
│   ├── settings.py         # QmlSingleton classes
│   └── services.py         # business logic, no Qt dependency
├── qml/
│   ├── qmldir
│   ├── Main.qml
│   ├── components/
│   │   ├── SearchBar.qml
│   │   └── ResultList.qml
│   └── screens/
│       ├── HomeScreen.qml
│       └── DetailScreen.qml
└── resources/
    ├── images/
    └── fonts/
```

### `pyproject.toml`

PySide6 uses `pyproject.toml` both as a standard Python packaging manifest and as the configuration file for `pyside6-project` tools:

```toml
[build-system]
requires = ["setuptools", "wheel"]
build-backend = "setuptools.backends.legacy:build"

[project]
name = "my-app"
version = "1.0.0"
requires-python = ">=3.10"
dependencies = ["PySide6>=6.6"]

[tool.pyside6-project]
# Files to include in pyside6-deploy
input_file = "main.py"

[tool.pyside6-project.nuitka]
# Nuitka compilation flags
extra-nuitka-args = ["--follow-import-to=backend"]
```

### Application Entry Point

```python
# main.py
import sys
from pathlib import Path

from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtQuickControls2 import QQuickStyle

# Import all QmlElement-decorated modules to ensure registration
import backend.models      # noqa: F401
import backend.settings    # noqa: F401

def main():
    app = QGuiApplication(sys.argv)
    QQuickStyle.setStyle("Material")

    engine = QQmlApplicationEngine()
    engine.addImportPath(str(Path(__file__).parent / "qml"))
    engine.loadFromModule("MyApp", "Main")

    if not engine.rootObjects():
        sys.exit(-1)

    sys.exit(app.exec())

if __name__ == "__main__":
    main()
```

The `import backend.models` lines are necessary because Python only executes module-level code — including `@QmlElement` decorator registration — when the module is imported. Failing to import a module means its types are unknown to the QML engine.

### QML Module Registration

In Qt 6, QML files are organized into *modules* with a URI. For PySide6, declare the module in `qmldir`:

```
# qml/qmldir
module MyApp
Main 1.0 Main.qml
```

Or use `QQmlEngine.addImportPath()` and follow the directory naming convention: a directory named after the module URI with dots replaced by slashes.

For typed QML modules (compatible with `qmlsc` ahead-of-time compilation), generate a `.pyi` stub and `qmltypes` file using `pyside6-genpyi` and register them.

---

## PySide6 Developer Tooling

### `pyside6-uic`

Converts Qt Designer `.ui` files to Python code. Less relevant for Qt Quick projects (which use `.qml`), but useful for hybrid applications using Qt Widgets for dialogs.

### `pyside6-rcc`

Compiles Qt resource files (`.qrc`) into Python modules that embed images, fonts, and other assets into the application binary:

```bash
pyside6-rcc resources.qrc -o resources_rc.py
```

```python
import resources_rc  # registers resources; must be imported before use
```

### `pyside6-designer`

Launches Qt Designer with PySide6 plugin support for visually editing `.ui` files.

### `pyside6-genpyi`

Generates Python stub files (`.pyi`) for PySide6 modules. Enables IDE type-checking and autocompletion for Qt types in Python.

### `pyside6-deploy`

Packages the application into a standalone executable using Nuitka (covered in depth in Chapter 13).

### `pyside6-project`

Orchestrates builds, resource compilation, and type stub generation from `pyproject.toml`.

---

## Summary

PySide6's Shiboken-generated bindings give Python code natural access to the full Qt API with automatic type conversion and memory management. The `@QmlElement`, `@QmlSingleton`, and `@QmlAnonymous` decorators provide a clean, Pythonic way to expose backend types to QML without manual registration boilerplate. A disciplined project structure — separating Python backend from QML frontend — keeps the codebase maintainable as it grows. The PySide6 toolchain covers the full development cycle from UI design through resource compilation to deployment.
