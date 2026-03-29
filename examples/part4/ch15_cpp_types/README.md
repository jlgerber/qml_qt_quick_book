# Chapter 15 — C++ Types in QML: Q_PROPERTY, Q_INVOKABLE, Q_ENUM, Q_GADGET

## What this example demonstrates

This project shows every major mechanism for sharing C++ types and values
with QML beyond the basic `QObject`/`Q_PROPERTY` combination.

| Concept | File |
|---|---|
| `Q_OBJECT_BINDABLE_PROPERTY` / `QBindable` | `backend/temperature.h/.cpp` |
| Bidirectional bindable property (celsius ↔ fahrenheit) | `backend/temperature.cpp` |
| Computed `Q_OBJECT_COMPUTED_PROPERTY` (kelvin) | `backend/temperature.h` |
| `Q_INVOKABLE` method callable from QML | `TemperatureConverter::formatCelsius()` |
| `Q_NAMESPACE` + `Q_ENUM_NS` + `QML_ELEMENT` | `backend/unit.h` |
| `Q_GADGET` + `QML_VALUE_TYPE` | `TemperatureReading` in `backend/unit.h` |
| Two-way `Binding` element pattern in QML | `qml/Main.qml` |
| `ComboBox` driven by a C++ enum | `qml/Main.qml` |

## Project layout

```
ch15_cpp_types/
├── CMakeLists.txt
├── main.cpp
├── backend/
│   ├── temperature.h
│   ├── temperature.cpp
│   └── unit.h              (header-only: namespace enum + gadget)
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
./build/cpptypesapp
```

## Things to try

- Move the Celsius slider and observe Fahrenheit updating automatically
  through the Qt binding system (no QML Binding element required for that
  direction — it's driven by `m_fahrenheit.setBinding()`).
- Move the Fahrenheit slider and note that the Celsius value derives from it.
- Switch the ComboBox to Kelvin and verify the formatted output changes.
- In `unit.h` add a fourth enum value (e.g. `Rankine`) and add a case in
  `Main.qml`'s `switch` — no changes to the registered module URI are needed.
