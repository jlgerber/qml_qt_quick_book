# Chapter 16 — C++ Models: QAbstractListModel + QSortFilterProxyModel

## What this example demonstrates

A task-list application that shows the correct way to expose mutable C++
data to QML through Qt's model/view framework.

| Concept | File |
|---|---|
| `QAbstractListModel` subclass with custom roles | `backend/taskmodel.h/.cpp` |
| `beginInsertRows` / `endInsertRows` / `beginRemoveRows` | `taskmodel.cpp` |
| `Q_INVOKABLE` mutations (`addTask`, `removeTask`, `setDone`) | `taskmodel.cpp` |
| `QSortFilterProxyModel` subclass | `backend/taskfilterproxy.h/.cpp` |
| `filterAcceptsRow` override | `taskfilterproxy.cpp` |
| `invalidateFilter()` to re-evaluate the filter at runtime | `taskfilterproxy.cpp` |
| `mapToSource()` — translating proxy indices back to source | `qml/Main.qml` |
| `engine.setInitialProperties()` to inject C++ objects | `main.cpp` |
| `QML_UNCREATABLE` to allow type references without construction | `taskmodel.h`, `taskfilterproxy.h` |

## Project layout

```
ch16_cpp_models/
├── CMakeLists.txt
├── main.cpp                Creates TaskModel + TaskFilterProxy, seeds data
├── backend/
│   ├── taskmodel.h
│   ├── taskmodel.cpp
│   ├── taskfilterproxy.h
│   └── taskfilterproxy.cpp
└── qml/
    └── Main.qml
```

## Prerequisites

- Qt 6.6 or later
- CMake 3.27 or later
- C++20 compiler

## Build instructions

```bash
cmake -B build -DCMAKE_PREFIX_PATH=/path/to/Qt6
cmake --build build
./build/cppmodelsapp
```

## Things to try

- Toggle "Hide completed tasks" and mark a task as done — it disappears
  immediately because `invalidateFilter()` fires on every `setDone` call.
- Remove a task and verify that `beginRemoveRows` keeps delegate indices
  consistent (no index shifting artefacts).
- Change the filter to also hide low-priority tasks by adding a `minPriority`
  property to `TaskFilterProxy` and checking it in `filterAcceptsRow`.
- Add a sort key to `TaskFilterProxy` using `lessThan()` to order by priority.
