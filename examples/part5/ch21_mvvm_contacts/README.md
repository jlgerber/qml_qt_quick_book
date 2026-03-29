# Chapter 21 — MVVM Contacts Application

A full, layered MVVM application in PySide6 that demonstrates the architecture
patterns discussed in Chapter 21: clean separation between the **Service**,
**ViewModel**, and **View** layers, with a `QAbstractListModel` bridging Python
data to QML.

---

## Architecture overview

```
┌──────────────────────────────────────────────────────────┐
│  View (QML)                                              │
│  Main.qml · ContactListView.qml · AddContactDialog.qml  │
│  Read properties / call slots on ContactListViewModel    │
└────────────────────┬─────────────────────────────────────┘
                     │ QObject properties, signals, slots
┌────────────────────▼─────────────────────────────────────┐
│  ViewModel (Python + Qt)                                 │
│  viewmodels/contact_list_viewmodel.py                    │
│  ContactListViewModel(QObject) + ContactModel            │
│  Owns a QThreadPool worker for async refresh             │
└────────────────────┬─────────────────────────────────────┘
                     │ pure Python API
┌────────────────────▼─────────────────────────────────────┐
│  Service (pure Python, no Qt)                            │
│  services/contact_service.py                             │
│  In-memory store · get_all · search · add · remove       │
└──────────────────────────────────────────────────────────┘
```

### Layer responsibilities

| Layer | Files | Qt dependency |
|-------|-------|---------------|
| Service | `services/contact_service.py` | None — plain Python dataclasses |
| ViewModel | `viewmodels/contact_list_viewmodel.py` | `QObject`, `QAbstractListModel`, `QThreadPool` |
| View | `qml/*.qml` | QML / Qt Quick Controls |

The service layer has **no Qt imports**, which means it can be unit-tested with
plain `pytest` without starting a `QApplication`.

---

## File reference

### Python

| File | Description |
|------|-------------|
| `main.py` | Creates `ContactService` and `ContactListViewModel`, injects the viewmodel via `engine.setInitialProperties`. |
| `services/contact_service.py` | `Contact` dataclass + `ContactService` with six pre-seeded contacts. |
| `viewmodels/contact_list_viewmodel.py` | `ContactListViewModel(@QmlElement)` + inner `ContactModel(QAbstractListModel)`. Exposes `contacts`, `searchQuery`, `loading`, `isEmpty`. Slots: `addContact`, `removeContact`, `refresh`. |

### QML

| File | Description |
|------|-------------|
| `qml/Main.qml` | Root `ApplicationWindow`. Hosts the search bar, `StackLayout` state machine, and the FAB. |
| `qml/ContactListView.qml` | `ListView` with section headers, avatar circles, name/email rows, and swipe-to-delete. |
| `qml/AddContactDialog.qml` | Modal `Dialog` with name (required), email, phone fields. OK disabled until name is non-empty. |
| `qml/qmldir` | Declares the `com.example.contacts` module. |

---

## Key patterns demonstrated

### Injecting the ViewModel

```python
# main.py
engine.setInitialProperties({"vm": viewmodel})
```

```qml
// Main.qml — receives the injected property
required property var vm
```

Using `required property` instead of a bare context property gives the QML
engine a compile-time guarantee that `vm` will always be present.

### SearchQuery with reactive re-filter

```python
@searchQuery.setter
def searchQuery(self, value: str) -> None:
    self._search_query = value
    self.searchQueryChanged.emit()
    self.refresh()          # triggers async reload from service
```

Typing in the search field automatically updates `vm.searchQuery`, which
triggers `refresh()`, which schedules a `_RefreshWorker` on the thread pool.
When the worker finishes it calls `_on_contacts_loaded`, which calls
`ContactModel.reset_contacts()`.

### StackLayout state machine

```qml
StackLayout {
    currentIndex: vm.loading ? 0 : vm.isEmpty ? 1 : 2
}
```

Three mutually exclusive states — loading spinner, empty state, contact list —
driven entirely by two boolean properties.

### Swipe-to-delete

```qml
SwipeDelegate {
    swipe.right: Rectangle {
        MouseArea {
            onClicked: root.viewModel.removeContact(delegate.contactId)
        }
    }
}
```

---

## How to run

### Prerequisites

- Python 3.11+
- PySide6 6.6+ with Qt Quick Controls 2

```bash
pip install PySide6
```

### Start the application

```bash
cd examples/part5/ch21_mvvm_contacts
python main.py
```

The application opens with six pre-seeded contacts. You can:

- **Search** by typing in the search bar (filters across name, email, phone).
- **Add** a contact with the purple `+` FAB.
- **Delete** a contact by swiping a row to the left.

### Run service-layer unit tests (no Qt required)

```bash
pip install pytest
pytest services/  # or: python -m pytest services/contact_service.py
```

---

## Extending the example

- **Persistence:** swap the in-memory dict in `ContactService` for an SQLite
  backend using the `sqlite3` standard library — the ViewModel and View layers
  require no changes.
- **Edit contact:** add an `UpdateContactDialog` mirroring `AddContactDialog`,
  and a `updateContact(id, name, email, phone)` slot on the ViewModel that
  calls `ContactService.update()`.
- **Sorting:** expose a `sortOrder` property on the ViewModel and pass it to
  `ContactService.get_all()` (which already sorts by name).
- **Network backend:** replace `ContactService` with an async HTTP client
  (e.g. `httpx`) — the ViewModel's `QThreadPool` worker already isolates
  I/O from the GUI thread.
