# Chapter 10 – Counter App

A counter application that demonstrates the core PySide6–QML data-binding
primitives: `Signal`, `Property`, and `Slot`.

## What it demonstrates

| Concept | Where |
|---|---|
| `Signal(int)` with typed argument | `backend/counter.py` – `valueChanged` |
| `@Property(int, notify=…)` | `backend/counter.py` – `value` |
| `@Property("QVariantList", notify=…)` | `backend/counter.py` – `history` |
| `@Slot()` / `@Slot(int)` | `backend/counter.py` – increment/decrement/reset/setValue |
| Guarding against invalid state | `_set_value` clamps to `>= 0` |
| Two-way binding with `SpinBox` | `qml/Main.qml` – `onValueModified` |
| `ListView` over a `QVariantList` | `qml/Main.qml` – history list |

## Project layout

```
ch10_counter_app/
├── main.py
├── backend/
│   ├── __init__.py
│   └── counter.py    # Counter QmlElement
└── qml/
    ├── qmldir        # QML module: CounterApp
    └── Main.qml
```

## How to run

```bash
cd examples/part3/ch10_counter_app
python main.py
```

## Requirements

- Python 3.10+
- PySide6 ≥ 6.5  (`pip install PySide6`)
