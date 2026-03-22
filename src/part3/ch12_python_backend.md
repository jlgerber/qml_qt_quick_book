# Chapter 12: Python Backend Patterns

## Business Logic Separation: Keeping QML as Pure View Layer

The most sustainable architecture for a PySide6/QML application separates concerns into three layers:

```
┌─────────────────────────────────────────┐
│              QML / View Layer           │
│  Declarations, bindings, animations,    │
│  user input handling, navigation        │
└─────────────────┬───────────────────────┘
                  │ Properties, Signals, Slots
┌─────────────────▼───────────────────────┐
│           ViewModel Layer (Python)      │
│  QObject subclasses, models, singletons │
│  Qt-aware, orchestrates service layer   │
└─────────────────┬───────────────────────┘
                  │ Plain Python calls
┌─────────────────▼───────────────────────┐
│           Service / Domain Layer        │
│  No Qt dependency, pure Python,         │
│  testable in isolation                  │
└─────────────────────────────────────────┘
```

### The Service Layer

The service layer contains domain logic with no Qt dependency. It can be unit-tested with pytest without a `QApplication`, without an event loop, and without a display:

```python
# services/search_service.py
from dataclasses import dataclass
from typing import Protocol

@dataclass
class SearchResult:
    title: str
    url: str
    snippet: str
    score: float

class SearchBackend(Protocol):
    def search(self, query: str, max_results: int) -> list[SearchResult]: ...

class SearchService:
    def __init__(self, backend: SearchBackend):
        self._backend = backend

    def search(self, query: str, max_results: int = 20) -> list[SearchResult]:
        if not query.strip():
            return []
        results = self._backend.search(query.strip(), max_results)
        return sorted(results, key=lambda r: r.score, reverse=True)
```

No `QObject`, no `Signal`, no `Property`. This code runs anywhere Python runs.

### The ViewModel Layer

The viewmodel wraps service calls in Qt-compatible wrappers:

```python
# viewmodels/search_viewmodel.py
from PySide6.QtCore import QObject, Property, Signal, Slot
from PySide6.QtQml import QmlElement
from services.search_service import SearchService
from models.search_result_model import SearchResultModel

QML_IMPORT_NAME = "com.example.app"
QML_IMPORT_MAJOR_VERSION = 1

@QmlElement
class SearchViewModel(QObject):
    queryChanged = Signal()
    searchingChanged = Signal()
    resultsChanged = Signal()

    def __init__(self, service: SearchService, parent=None):
        super().__init__(parent)
        self._service = service
        self._query = ""
        self._searching = False
        self._results = SearchResultModel(parent=self)

    @Property(str, notify=queryChanged)
    def query(self):
        return self._query

    @query.setter
    def query(self, value: str):
        if self._query != value:
            self._query = value
            self.queryChanged.emit()

    @Property(bool, notify=searchingChanged)
    def searching(self):
        return self._searching

    @Property(QObject, notify=resultsChanged)
    def results(self):
        return self._results

    @Slot()
    def performSearch(self):
        if not self._query:
            return
        self._searching = True
        self.searchingChanged.emit()

        # Run in a thread (Chapter 11 pattern)
        worker = ComputeWorker(self._service.search, self._query)
        worker.signals.finished.connect(self._onSearchComplete)
        QThreadPool.globalInstance().start(worker)

    @Slot(object)
    def _onSearchComplete(self, results):
        self._results.setResults(results)
        self._searching = False
        self.searchingChanged.emit()
        self.resultsChanged.emit()
```

QML interacts only with the viewmodel's public interface. The service layer is invisible to QML.

### What Belongs in QML

QML is responsible for:
- Declaring item structure and visual properties
- Binding properties to viewmodel state
- Calling viewmodel slots in response to user interaction
- Animating transitions between states
- Navigation decisions (which screen to show, when)

QML should **not** contain:
- Business rules ("if user has premium plan, enable feature X")
- Data transformation ("convert bytes to human-readable size")
- Validation logic ("is this email address valid")
- Network or file access
- Significant JavaScript computation

The test: could you swap QML for a terminal UI or a REST API without changing the Python layer? If yes, the separation is clean.

---

## Integrating Python Libraries (NumPy, Pandas, SQLAlchemy) as Qt Models

### NumPy Integration

NumPy arrays as model data require conversion at the boundary. For numeric displays (charts, tables, heatmaps), wrap a numpy array in a `QAbstractTableModel`:

```python
import numpy as np
from PySide6.QtCore import QAbstractTableModel, QModelIndex, Qt

class NumpyTableModel(QAbstractTableModel):
    def __init__(self, array: np.ndarray, parent=None):
        super().__init__(parent)
        self._data = array

    def rowCount(self, parent=QModelIndex()) -> int:
        return 0 if parent.isValid() else self._data.shape[0]

    def columnCount(self, parent=QModelIndex()) -> int:
        return 0 if parent.isValid() else self._data.shape[1] if self._data.ndim > 1 else 1

    def data(self, index: QModelIndex, role=Qt.DisplayRole):
        if not index.isValid():
            return None
        value = self._data[index.row(), index.column()]
        if role == Qt.DisplayRole:
            return f"{value:.4f}" if isinstance(value, float) else str(value)
        if role == Qt.UserRole:  # raw value for QML computations
            return float(value)
        return None

    def updateData(self, new_array: np.ndarray):
        self.beginResetModel()
        self._data = new_array
        self.endResetModel()
```

For chart data (series of x/y points), pass numpy arrays directly to a `Slot` and unpack them in QML using JavaScript or a specialized series model:

```python
@Slot(result="QVariantList")
def getChartData(self) -> list:
    # Convert numpy to plain Python list for QML consumption
    return [{"x": float(x), "y": float(y)}
            for x, y in zip(self._xdata, self._ydata)]
```

### Pandas Integration

Pandas `DataFrame`s map naturally to `QAbstractTableModel` (each row is a data row, each column is a field). The earlier `DataFrameModel` example applies directly. Additional considerations:

**Filtering and sorting without copying**:

```python
def applyFilter(self, column: str, value: str):
    self.beginResetModel()
    mask = self._source_df[column].astype(str).str.contains(value, case=False)
    self._df = self._source_df[mask]
    self.endResetModel()
```

**Using `QSortFilterProxyModel` with a DataFrame model**: The built-in proxy model works but re-sorts Python-side when the filtered model is a custom `QAbstractItemModel`. For large DataFrames, implement filtering directly in the model using pandas operations (vectorized, fast) rather than relying on the proxy's row-by-row `filterAcceptsRow`.

### SQLAlchemy Integration

SQLAlchemy provides an ORM for relational databases. Integrating it as a Qt model requires careful session management:

```python
from sqlalchemy import create_engine
from sqlalchemy.orm import Session
from PySide6.QtCore import QAbstractListModel, QModelIndex, Qt, Slot

class ContactRepository:
    """Pure Python, no Qt. Manages SQLAlchemy sessions."""

    def __init__(self, db_url: str):
        self._engine = create_engine(db_url)

    def get_all(self) -> list[Contact]:
        with Session(self._engine) as session:
            return session.query(Contact).order_by(Contact.name).all()

    def add(self, name: str, email: str) -> Contact:
        with Session(self._engine) as session:
            contact = Contact(name=name, email=email)
            session.add(contact)
            session.commit()
            session.refresh(contact)
            return contact

class ContactListModel(QAbstractListModel):
    NameRole = Qt.UserRole + 1
    EmailRole = Qt.UserRole + 2

    def __init__(self, repository: ContactRepository, parent=None):
        super().__init__(parent)
        self._repo = repository
        self._contacts: list[Contact] = []
        self.refresh()

    @Slot()
    def refresh(self):
        self.beginResetModel()
        self._contacts = self._repo.get_all()
        self.endResetModel()

    @Slot(str, str)
    def addContact(self, name: str, email: str):
        contact = self._repo.add(name, email)
        self.beginInsertRows(QModelIndex(), len(self._contacts), len(self._contacts))
        self._contacts.append(contact)
        self.endInsertRows()
```

Keep SQLAlchemy sessions scoped to the repository methods — never hold a long-lived session open. This prevents lock contention on SQLite and avoids stale-data issues on other databases.

---

## Background Threads, `QThreadPool`, and `QRunnable` from Python

### Choosing a Threading Strategy

| Scenario | Recommended approach |
|---|---|
| I/O-bound (network, file) | `asyncio` + `qasync`, or `QThread` with blocking I/O |
| CPU-bound, short tasks | `QThreadPool` + `QRunnable` |
| Long-running background service | Dedicated `QThread` with `moveToThread` worker |
| Reactive streams / event-driven | `QThread` worker emitting signals |

### `QThread` with Worker Object Pattern

The `moveToThread` pattern is the canonical Qt approach for long-running workers:

```python
from PySide6.QtCore import QObject, QThread, Signal, Slot

class DataSyncWorker(QObject):
    syncComplete = Signal(int)   # number of records synced
    errorOccurred = Signal(str)
    progressUpdated = Signal(int, int)  # current, total

    @Slot()
    def startSync(self):
        try:
            records = fetch_remote_records()
            total = len(records)
            for i, record in enumerate(records):
                store_record(record)
                self.progressUpdated.emit(i + 1, total)
            self.syncComplete.emit(total)
        except Exception as e:
            self.errorOccurred.emit(str(e))

class SyncManager(QObject):
    def __init__(self, parent=None):
        super().__init__(parent)
        self._worker = DataSyncWorker()
        self._thread = QThread(parent=self)

        self._worker.moveToThread(self._thread)
        self._thread.started.connect(self._worker.startSync)
        self._worker.syncComplete.connect(self._thread.quit)
        self._worker.syncComplete.connect(self._onSyncComplete)
        self._worker.errorOccurred.connect(self._onError)

    @Slot()
    def sync(self):
        if not self._thread.isRunning():
            self._thread.start()

    @Slot(int)
    def _onSyncComplete(self, count: int):
        print(f"Synced {count} records")

    @Slot(str)
    def _onError(self, message: str):
        print(f"Sync error: {message}")
```

Key points:
- The worker is created on the main thread but moved before starting the thread
- Never call worker methods directly from the main thread after `moveToThread` — use `invokeMethod` or connect-and-emit
- The thread and worker lifetimes must be managed carefully — use parent relationships

### Cancellation

Qt does not have a built-in cancellation mechanism. The standard approach is a cancellation flag:

```python
class CancellableWorker(QObject):
    def __init__(self):
        super().__init__()
        self._cancelled = False

    @Slot()
    def cancel(self):
        self._cancelled = True

    @Slot()
    def run(self):
        for item in large_dataset:
            if self._cancelled:
                break
            process(item)
```

Connect `cancelButton.clicked` to `worker.cancel`. The flag is set on the main thread and read on the worker thread; for a simple boolean, this is typically safe in practice, though a `threading.Event` is more formally correct.

---

## Summary

Clean Python backends for QML applications separate domain logic (no Qt, fully testable) from viewmodel logic (Qt-aware, thin wrappers). Popular Python data libraries — NumPy, Pandas, SQLAlchemy — integrate through `QAbstractItemModel` subclasses that handle the impedance mismatch between Python data structures and Qt's row/column/role model. Threading is the most error-prone aspect: all model mutations must happen on the main thread, and Qt's signal/slot system with `QueuedConnection` is the safest bridge between worker threads and the main thread. The `moveToThread` + worker object pattern handles long-running background operations cleanly and idiomatically.
