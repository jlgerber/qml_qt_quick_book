# Chapter 18 — Performance: Batched Model Updates and Coarse-Grained Signals

## What this example demonstrates

`SensorModel` simulates a 1 kHz data source (one new reading every 1 ms) but
only notifies the QML `ListView` ~60 times per second by decoupling the data
producer from the view update using a second, lower-frequency flush timer.

| Concept | File |
|---|---|
| Decoupling producer rate from view update rate | `sensormodel.h/.cpp` |
| `pendingBuffer` accumulation pattern | `sensormodel.cpp` (slot `onNewReading`) |
| Single `beginInsertRows` / `endInsertRows` for a whole batch | `sensormodel.cpp` (slot `flushUpdates`) |
| Trimming a rolling window with `beginRemoveRows` | `sensormodel.cpp` |
| One coarse `dataChanged` for the entire visible range | `sensormodel.cpp` |
| `Qt::PreciseTimer` vs `Qt::CoarseTimer` | `sensormodel.cpp` |
| Diagnostic properties (`updateCount`, `pendingCount`) | `sensormodel.h` |
| Bar-chart delegate with colour encoding | `qml/Main.qml` |
| `ListView.positionViewAtEnd()` on `onCountChanged` | `qml/Main.qml` |

Without batching, 1000 `dataChanged` signals per second would reach the QML
engine and cause 1000 delegate re-evaluations per second.  With batching,
the view processes at most ~60 notifications per second, keeping the UI
thread free for smooth rendering.

## Project layout

```
ch18_performance/
├── CMakeLists.txt
├── main.cpp
├── sensormodel.h
├── sensormodel.cpp
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
./build/performanceapp
```

## Things to try

- Click **Start** and watch the "Pending readings" counter fluctuate between
  ~10 and ~20 (roughly 16 ms * 1 reading/ms) — never large because the flush
  timer empties the buffer every frame.
- Change `k_flushIntervalMs` to 500 ms and observe pending counts of ~500
  between bursts; the bars all update at once.
- Change `k_flushIntervalMs` to 1 ms (matching the source) — the bar chart
  becomes choppy because each flush updates only one row at a time and the
  `dataChanged` overhead dominates.
- Replace the bar-chart delegate with a simple `Text { text: model.value.toFixed(3) }`
  to isolate the model-notification cost from rendering cost.
