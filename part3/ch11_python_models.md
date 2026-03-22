# Chapter 11: Data Models in Python

## Subclassing `QAbstractListModel`, `QAbstractTableModel`, and `QSortFilterProxyModel`

The Qt model-view framework defines a protocol — the `QAbstractItemModel` interface — that views use to query data, receive change notifications, and (optionally) submit edits. Implementing this protocol in Python gives you a model that any Qt Quick view can consume without the view knowing or caring whether the data comes from a Python list, a database, a network API, or a sensor stream.

### The Model Protocol

A model must implement a small core interface:

| Method | Purpose |
|---|---|
| `rowCount(parent)` | Returns number of rows |
| `data(index, role)` | Returns data for a cell at role |
| `roleNames()` | Returns a dict mapping role integers to QML role name bytes |

For tables, also:

| Method | Purpose |
|---|---|
| `columnCount(parent)` | Returns number of columns |

For mutable models, additionally:

| Method | Purpose |
|---|---|
| `setData(index, value, role)` | Applies an edit |
| `flags(index)` | Returns item flags (e.g., `Qt.ItemIsEditable`) |

Change notification is communicated through signals defined on `QAbstractItemModel`:

| Signal | When to emit |
|---|---|
| `dataChanged(topLeft, bottomRight, roles)` | Data changed in a range |
| `beginInsertRows(parent, first, last)` + `endInsertRows()` | Rows are being inserted |
| `beginRemoveRows(parent, first, last)` + `endRemoveRows()` | Rows are being removed |
| `beginResetModel()` + `endResetModel()` | Complete model restructuring |

### `QAbstractListModel`

A flat list model. `parent` in `rowCount()` and `data()` is always `QModelIndex()` (the root) for list models — pass it through but do not use it:

```python
from PySide6.QtCore import (
    QAbstractListModel, QModelIndex, Qt, Signal
)

class ContactModel(QAbstractListModel):
    # Custom roles start above Qt.UserRole (256)
    NameRole = Qt.UserRole + 1
    EmailRole = Qt.UserRole + 2
    AvatarRole = Qt.UserRole + 3

    def __init__(self, parent=None):
        super().__init__(parent)
        self._contacts: list[dict] = []

    # --- Required interface ---

    def rowCount(self, parent=QModelIndex()) -> int:
        if parent.isValid():
            return 0  # flat list: no children
        return len(self._contacts)

    def data(self, index: QModelIndex, role: int = Qt.DisplayRole):
        if not index.isValid() or not (0 <= index.row() < len(self._contacts)):
            return None
        contact = self._contacts[index.row()]
        match role:
            case self.NameRole:  return contact["name"]
            case self.EmailRole: return contact["email"]
            case self.AvatarRole: return contact["avatar_url"]
            case Qt.DisplayRole: return contact["name"]
            case _: return None

    def roleNames(self) -> dict[int, bytes]:
        return {
            self.NameRole:   b"name",
            self.EmailRole:  b"email",
            self.AvatarRole: b"avatar",
        }

    # --- Mutation API ---

    def appendContact(self, name: str, email: str, avatar: str = ""):
        self.beginInsertRows(QModelIndex(), len(self._contacts), len(self._contacts))
        self._contacts.append({"name": name, "email": email, "avatar_url": avatar})
        self.endInsertRows()

    def removeContact(self, row: int):
        if not (0 <= row < len(self._contacts)):
            return
        self.beginRemoveRows(QModelIndex(), row, row)
        del self._contacts[row]
        self.endRemoveRows()

    def updateEmail(self, row: int, email: str):
        if not (0 <= row < len(self._contacts)):
            return
        self._contacts[row]["email"] = email
        index = self.index(row, 0)
        self.dataChanged.emit(index, index, [self.EmailRole])
```

In QML:

```qml
ListView {
    model: contactModel   // Python ContactModel instance
    delegate: ContactDelegate {
        required property string name
        required property string email
        required property string avatar
    }
}
```

Role names defined in `roleNames()` become accessible as named properties in delegates. The `b"name"` bytes are the QML property names.

### `QAbstractTableModel`

A two-dimensional model. Additionally implement `columnCount()`:

```python
class DataFrameModel(QAbstractTableModel):
    def __init__(self, df, parent=None):
        super().__init__(parent)
        self._df = df

    def rowCount(self, parent=QModelIndex()) -> int:
        return 0 if parent.isValid() else len(self._df)

    def columnCount(self, parent=QModelIndex()) -> int:
        return 0 if parent.isValid() else len(self._df.columns)

    def data(self, index: QModelIndex, role=Qt.DisplayRole):
        if not index.isValid():
            return None
        if role == Qt.DisplayRole:
            value = self._df.iat[index.row(), index.column()]
            return str(value)
        return None

    def headerData(self, section: int, orientation: Qt.Orientation, role=Qt.DisplayRole):
        if role != Qt.DisplayRole:
            return None
        if orientation == Qt.Horizontal:
            return str(self._df.columns[section])
        return str(section + 1)
```

This wraps a pandas `DataFrame` as a Qt table model. The `TableView` component in QML will query `rowCount`, `columnCount`, `data`, and `headerData` automatically.

### Batch Updates with `beginResetModel`

When the underlying data is completely replaced (e.g., a new query result), use `beginResetModel` / `endResetModel`:

```python
def loadData(self, new_data: list[dict]):
    self.beginResetModel()
    self._contacts = new_data
    self.endResetModel()
```

The view discards all cached delegates and rebuilds from scratch. This is appropriate for complete replacements but heavy for incremental changes — prefer `beginInsertRows`/`beginRemoveRows`/`dataChanged` for incremental mutations.

---

## Thread-Safe Model Mutation and `QMetaObject.invokeMethod`

### The Threading Constraint

`QAbstractItemModel` and all Qt Quick views run on the main thread. You must never call `beginInsertRows()`, `endInsertRows()`, `dataChanged.emit()`, or any other model method from a background thread. Doing so corrupts the view's internal state and causes crashes.

Background threads can safely:
- Read data (if the read is protected by a lock)
- Compute results
- Store results in a thread-safe queue

They must not:
- Call any model mutation method directly
- Access any `QObject` on the main thread

### Pattern 1: `QMetaObject.invokeMethod` with `QueuedConnection`

Post a method call to the main thread's event loop from a background thread:

```python
import threading
from PySide6.QtCore import QMetaObject, Qt, Q_ARG

class LiveDataModel(QAbstractListModel):
    ...

    def startStreaming(self):
        thread = threading.Thread(target=self._stream_worker, daemon=True)
        thread.start()

    def _stream_worker(self):
        for packet in data_source.stream():
            QMetaObject.invokeMethod(
                self,
                "_appendPacket",
                Qt.QueuedConnection,
                Q_ARG("QVariant", packet)
            )

    @Slot("QVariant")
    def _appendPacket(self, packet):
        # Now on the main thread
        self.beginInsertRows(QModelIndex(), len(self._data), len(self._data))
        self._data.append(packet)
        self.endInsertRows()
```

### Pattern 2: Signal from Worker Thread

Emit a signal from the worker thread connected with a `QueuedConnection`. Qt automatically marshals the signal emission to the receiver's thread:

```python
class DataWorker(QObject):
    newDataAvailable = Signal(list)

    def run(self):
        # In a QThread
        while True:
            batch = self._fetch_batch()
            self.newDataAvailable.emit(batch)

class LiveModel(QAbstractListModel):
    def __init__(self):
        super().__init__()
        self._worker = DataWorker()
        self._thread = QThread(self)
        self._worker.moveToThread(self._thread)
        self._worker.newDataAvailable.connect(
            self._onNewData, Qt.QueuedConnection
        )
        self._thread.start()
        QMetaObject.invokeMethod(self._worker, "run", Qt.QueuedConnection)

    @Slot(list)
    def _onNewData(self, batch: list):
        # On the main thread due to QueuedConnection
        self.beginInsertRows(QModelIndex(), len(self._data), len(self._data) + len(batch) - 1)
        self._data.extend(batch)
        self.endInsertRows()
```

`moveToThread()` changes the *thread affinity* of a `QObject`. Its slots are subsequently invoked on the target thread. This is the canonical Qt threading pattern.

---

## Async Data Loading: Integrating `asyncio` with the Qt Event Loop

Python's `asyncio` event loop and Qt's event loop are both single-threaded event loops, but they are different loops. Running them together requires bridging.

### `qasync`

The `qasync` library (installable via pip) integrates `asyncio` with Qt's event loop by running the asyncio loop as a Qt event source:

```python
import asyncio
import qasync
from PySide6.QtWidgets import QApplication

async def main():
    app = QApplication.instance()
    # ... setup engine, backend ...
    await asyncio.sleep(0)  # yield to Qt event loop
    # Application runs here via qasync

if __name__ == "__main__":
    app = QApplication(sys.argv)
    loop = qasync.QEventLoop(app)
    asyncio.set_event_loop(loop)

    with loop:
        loop.run_until_complete(main())
```

With `qasync`, Python async functions can await I/O without blocking the Qt event loop:

```python
class ApiClient(QObject):
    dataReady = Signal(list)

    async def fetch_items(self):
        async with aiohttp.ClientSession() as session:
            async with session.get("https://api.example.com/items") as resp:
                data = await resp.json()
        self.dataReady.emit(data)

    @Slot()
    def refreshData(self):
        asyncio.ensure_future(self.fetch_items())
```

### Using `QThreadPool` and `QRunnable`

For CPU-bound work, Python's asyncio gives no parallelism benefit (due to the GIL). Use Qt's thread pool instead:

```python
from PySide6.QtCore import QRunnable, QThreadPool, Slot, Signal, QObject

class WorkerSignals(QObject):
    finished = Signal(object)
    error = Signal(str)

class ComputeWorker(QRunnable):
    def __init__(self, fn, *args, **kwargs):
        super().__init__()
        self.fn = fn
        self.args = args
        self.kwargs = kwargs
        self.signals = WorkerSignals()

    @Slot()
    def run(self):
        try:
            result = self.fn(*self.args, **self.kwargs)
            self.signals.finished.emit(result)
        except Exception as e:
            self.signals.error.emit(str(e))

# Usage
def heavy_computation(data):
    # CPU-intensive work
    return process(data)

worker = ComputeWorker(heavy_computation, large_dataset)
worker.signals.finished.connect(model.loadData)
worker.signals.error.connect(errorHandler.showError)
QThreadPool.globalInstance().start(worker)
```

`QRunnable` is not a `QObject` (no signals), which is why `WorkerSignals` is a separate `QObject`. The `finished` signal fires on the main thread (via `QueuedConnection` default for cross-thread signals), making it safe to call model methods in the slot.

---

## Summary

`QAbstractListModel` and `QAbstractTableModel` are the contracts that Qt Quick views consume. Implementing them correctly — with `roleNames()` for QML property names, proper begin/end bracketing for mutations, and granular `dataChanged` emissions — gives views the information they need to update efficiently. Threading is the critical constraint: all model mutations must happen on the main thread. The `QMetaObject.invokeMethod` / `QueuedConnection` pattern and the `moveToThread` + signal pattern are the two standard ways to safely deliver background thread results to the main thread model. For async I/O, `qasync` bridges asyncio and Qt naturally; for CPU-bound work, `QThreadPool` + `QRunnable` bypasses the GIL limitation.
