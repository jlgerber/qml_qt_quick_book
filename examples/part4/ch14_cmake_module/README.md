# Chapter 14 — `qt_add_qml_module` and the CMake Module System

## What this example demonstrates

This project shows how to structure a real Qt Quick application using CMake's
`qt_add_qml_module()` command introduced in Qt 6.2 and stabilised in Qt 6.5.

Key concepts covered:

| Concept | Where to look |
|---|---|
| Multi-library CMake layout | Root `CMakeLists.txt`, `backend/`, `qml/` |
| `qt_add_qml_module` for a C++ library | `backend/CMakeLists.txt` |
| `qt_add_qml_module` for a QML-only library | `qml/CMakeLists.txt` |
| `QML_ELEMENT` auto-registration | `backend/counter.h` |
| `engine.loadFromModule()` | `main.cpp` |
| QML depending on a sibling module | `qml/Main.qml` imports `com.example.backend` |

The application itself is a simple bounded counter (0–99) with increment,
decrement, and reset controls, plus `atMinimum`/`atMaximum` guard properties
that disable the corresponding buttons.

## Project layout

```
ch14_cmake_module/
├── CMakeLists.txt          Root: wires backend + qml subprojects together
├── main.cpp                Entry point
├── backend/
│   ├── CMakeLists.txt      Builds counterapp_backend, URI com.example.backend
│   ├── counter.h
│   └── counter.cpp
└── qml/
    ├── CMakeLists.txt      Builds counterapp_qml, URI com.example.app
    └── Main.qml
```

## Prerequisites

- Qt 6.6 or later (Qt 6.5 works but 6.6 is recommended)
- CMake 3.27 or later
- A C++20-capable compiler (GCC 11+, Clang 13+, MSVC 2022+)

## Build instructions

```bash
cmake -B build -DCMAKE_PREFIX_PATH=/path/to/Qt6
cmake --build build
./build/counterapp
```

On Windows with the MSVC generator use:

```cmd
cmake -B build -DCMAKE_PREFIX_PATH=C:\Qt\6.6.0\msvc2019_64
cmake --build build --config Release
build\Release\counterapp.exe
```

## Things to try

- Change `k_max` in `counter.cpp` and rebuild — no QML changes needed.
- Add a second C++ type to `backend/` and import it in `Main.qml` without
  touching any `qmldir` file by hand.
- Rename `Main.qml` to something else and observe how `loadFromModule`
  must be updated to match.
