# Chapter 9 – Hello PySide6

A minimal PySide6 + QML application that demonstrates the essential wiring
between Python and QML.

## What it demonstrates

| Concept | Where |
|---|---|
| `QGuiApplication` + `QQmlApplicationEngine` bootstrap | `main.py` |
| `@QmlElement` decorator (no manual `qmlRegisterType`) | `main.py` – `AppInfo` |
| `@Property(str, constant=True)` exposed to QML | `main.py` – `AppInfo` |
| Loading a component via `loadFromModule` | `main.py` |
| QML module declaration (`qmldir`) | `qml/qmldir` |
| Consuming a Python type from QML | `qml/Main.qml` |

## Project layout

```
ch09_hello_pyside6/
├── main.py          # Python entry point + AppInfo backend
└── qml/
    ├── qmldir       # QML module: HelloApp
    └── Main.qml     # ApplicationWindow
```

## How to run

```bash
cd examples/part3/ch09_hello_pyside6
python main.py
```

## Requirements

- Python 3.10+
- PySide6 ≥ 6.5  (`pip install PySide6`)
