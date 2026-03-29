# Chapter 20 — Testing Qt Quick and C++ Models

Two independent test suites that cover the two main testing surfaces in a
Qt application:

- **QML behavioural tests** — using `TestCase` and `SignalSpy` from
  `QtTest` (no C++ required).
- **C++ model unit tests** — using `QTest`, `QSignalSpy`, and
  `QAbstractItemModelTester`.

Both suites are self-contained: the types under test are defined inline so
the examples build and run without any external dependencies beyond Qt itself.

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
