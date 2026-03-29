# Chapter 11 – Contact Model

A contacts application built around a `QAbstractListModel` subclass,
demonstrating the correct way to expose a mutable Python list to QML.

## What it demonstrates

| Concept | Where |
|---|---|
| `QAbstractListModel` subclass | `backend/contact_model.py` |
| Custom `roleNames()` → QML role binding | `contact_model.py` – `NameRole / EmailRole / PhoneRole` |
| `beginInsertRows` / `endInsertRows` | `addContact` slot |
| `beginRemoveRows` / `endRemoveRows` | `removeContact` / `clear` slots |
| Pre-populating a model before QML loads | `main.py` |
| `engine.setInitialProperties` | `main.py` |
| `SwipeDelegate` swipe-to-delete | `qml/Main.qml` |
| Add-contact form with `TextField` | `qml/Main.qml` |

## Project layout

```
ch11_contact_model/
├── main.py
├── backend/
│   ├── __init__.py
│   └── contact_model.py    # ContactModel QmlElement
└── qml/
    ├── qmldir              # QML module: ContactApp
    └── Main.qml
```

## How to run

```bash
cd examples/part3/ch11_contact_model
python main.py
```

## Requirements

- Python 3.10+
- PySide6 ≥ 6.5  (`pip install PySide6`)
