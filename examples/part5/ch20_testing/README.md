# Chapter 20 — Testing Qt Quick, C++ Models, and PySide6

Three independent test suites that cover the main testing surfaces in a
Qt application:

- **QML behavioural tests** — using `TestCase` and `SignalSpy` from
  `QtTest` (no C++ required).
- **C++ model unit tests** — using `QTest`, `QSignalSpy`, and
  `QAbstractItemModelTester`.
- **Python / PySide6 unit tests** — using `pytest` and `pytest-qt`.

All three suites are self-contained: the types under test are defined inside
the test files so the examples run without external dependencies beyond Qt
and the standard Python toolchain.

---

## qml_tests/tst_counter.qml

### What it tests

A `Counter` QtObject component (defined inline via `Component {}`) with:

| Member | Description |
|--------|-------------|
| `property int value` | Read-only alias to internal state |
| `signal valueChanged(int)` | Emitted on every mutation |
| `function increment()` | Adds 1 |
| `function decrement()` | Subtracts 1, clamps at 0 |
| `function reset()` | Sets value back to 0 |

### Test cases

| Test | What it checks |
|------|---------------|
| `test_initialValue` | Counter starts at 0 |
| `test_increment` | Each call adds exactly 1 |
| `test_decrement` | Each call subtracts exactly 1 |
| `test_reset` | Restores value to 0 from any state |
| `test_valueChanged_signal` | `SignalSpy` counts one emission per mutation |
| `test_minimum_clamp` | `decrement()` never takes value below 0 |
| `test_incrementDecrementSymmetry` | n increments + n decrements returns to 0 |

### How to run

```bash
# From the qml_tests directory
qmltestrunner -input tst_counter.qml
```

`qmltestrunner` is bundled with Qt and is usually on `PATH` when Qt is
installed. On Linux it may be at:

```bash
$(python -c "import PySide6; print(PySide6.__path__[0])")/qmltestrunner
```

---

## cpp_tests/tst_taskmodel.cpp

### What it tests

A `TaskModel : QAbstractListModel` (defined inline in the `.cpp` file) with:

| Role | Description |
|------|-------------|
| `IdRole` | UUID string — `"taskId"` role name |
| `TitleRole` | Task title string |
| `DoneRole` | bool completion flag |

| Method | Description |
|--------|-------------|
| `addTask(title)` | Appends a new task, returns its UUID |
| `removeTask(id)` | Removes by UUID, returns success |
| `setDone(id, bool)` | Toggles done flag, emits `dataChanged` |

### Test cases

| Test | What it checks |
|------|---------------|
| `test_initiallyEmpty` | `rowCount()` is 0 after construction |
| `test_addTask` | Row count and role data correct after insert |
| `test_removeTask` | Row count and remaining data correct after remove; false for unknown id |
| `test_setDone` | `done` role toggles correctly; false for unknown id |
| `test_dataChanged_roles` | `QSignalSpy` on `dataChanged` verifies only `DoneRole` emitted |
| `test_addTask_rowsInserted_signal` | `rowsInserted` carries correct first/last indices |
| `test_removeTask_rowsRemoved_signal` | `rowsRemoved` carries correct indices |
| `test_modelIntegrity` | `QAbstractItemModelTester` monitors all mutations for invariant violations |

### How to build and run

```bash
cd examples/part5/ch20_testing/cpp_tests

# Configure (set CMAKE_PREFIX_PATH if Qt is not on the system path)
cmake -S . -B build -DCMAKE_PREFIX_PATH=/path/to/Qt/6.x.x/gcc_64

# Build
cmake --build build

# Run directly
./build/tst_taskmodel

# Or via CTest (shows pass/fail summary)
ctest --test-dir build --output-on-failure
```

---

## python_tests/

### What it tests

The same `TaskModel` logic as the C++ suite, re-implemented as a PySide6
`QAbstractListModel` in `task_model.py`.

| Role / method | Description |
|---------------|-------------|
| `IdRole` | UUID string — `"taskId"` role name |
| `TitleRole` | Task title string |
| `DoneRole` | bool completion flag |
| `addTask(title)` | Appends a new task; returns its UUID string |
| `removeTask(id)` | Removes by UUID; returns `True` if found |
| `setDone(id, done)` | Sets done flag, emits `dataChanged`; returns `True` if found |

### Test cases

| Test | What it checks |
|------|----------------|
| `test_initially_empty` | `rowCount()` is 0 after construction |
| `test_add_task` | Row count and role data correct after insert |
| `test_add_multiple_tasks` | Insertion order preserved across multiple adds |
| `test_remove_task` | Row count and remaining data correct after remove; `False` for unknown id |
| `test_set_done` | `done` role toggles correctly |
| `test_set_done_unknown_id_returns_false` | Unknown id leaves model unchanged |
| `test_add_task_rows_inserted_signal` | `qtbot.waitSignal` captures correct first/last indices |
| `test_remove_task_rows_removed_signal` | `rowsRemoved` carries correct indices |
| `test_data_changed_emits_done_role` | Only `DoneRole` present in the changed-roles list |
| `test_model_integrity` | `QAbstractItemModelTester` monitors all mutations for invariant violations |

### How to run

```bash
cd examples/part5/ch20_testing/python_tests

# Install dependencies (once)
pip install pytest pytest-qt

# Run all tests
pytest -v
```

---

## Design notes

### Why inline component definitions?

Both test files define the type under test inside the test file itself. This
means:

- Zero external build dependencies — no installed module, no shared library.
- The tests are portable and work immediately after a fresh checkout.
- The technique mirrors how you would test a component before extracting it
  into a reusable module.

In a real project you would import the actual production type instead.

### QAbstractItemModelTester

`QAbstractItemModelTester` (available since Qt 5.11) attaches to the model
and calls a comprehensive suite of checks after every mutation — it verifies
things like `beginInsertRows`/`endInsertRows` symmetry, valid index ranges,
and correct `parent()` return values. It is the recommended first tool when
writing a new `QAbstractItemModel` subclass.
