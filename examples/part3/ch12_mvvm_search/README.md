# Chapter 12 – MVVM Search

A search application structured with strict MVVM separation: the service
layer has zero Qt dependencies, the ViewModel wires it to Qt, and the View
(QML) knows nothing about Python internals.

## What it demonstrates

| Concept | Where |
|---|---|
| Pure-Python service layer (no Qt) | `services/search_service.py` |
| `SearchResult` dataclass | `services/search_service.py` |
| `QAbstractListModel` as inner ViewModel type | `viewmodels/search_viewmodel.py` – `ResultModel` |
| `QThreadPool` + `QRunnable` for async work | `viewmodels/search_viewmodel.py` – `_SearchWorker` |
| Posting results back to main thread via `Signal(object)` | `_searchDone` signal |
| Settable `@Property` (two-way `query` binding) | `SearchViewModel.query` |
| `BusyIndicator` driven by `vm.searching` | `qml/Main.qml` |
| Result count label | `qml/Main.qml` |
| Empty-state placeholder | `qml/Main.qml` |
| Dependency injection (service → viewmodel) | `main.py` |

## Project layout

```
ch12_mvvm_search/
├── main.py
├── services/
│   ├── __init__.py
│   └── search_service.py    # Pure Python – SearchService, SearchResult
├── viewmodels/
│   ├── __init__.py
│   └── search_viewmodel.py  # SearchViewModel + ResultModel QmlElements
└── qml/
    ├── qmldir               # QML module: SearchApp
    └── Main.qml
```

## How to run

```bash
cd examples/part3/ch12_mvvm_search
python main.py
```

Try searching for: `qml`, `model`, `thread`, `deploy`, `animation`

## Requirements

- Python 3.10+
- PySide6 ≥ 6.5  (`pip install PySide6`)
