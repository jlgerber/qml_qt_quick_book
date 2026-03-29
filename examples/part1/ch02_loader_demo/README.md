# Ch02 — Loader

## What it demonstrates

### Section 1 — `Loader.active` toggle
- A `Button` flips `detailLoader.active` between `true` and `false`.
- When activated, `setSource()` passes a `required property string title` as an
  initial property; the loaded item is destroyed automatically on deactivation.
- An opacity `Behavior` provides a smooth fade in/out.

### Section 2 — `Loader.asynchronous`
- `HeavyComponent.qml` simulates expensive initialisation with a `Timer`.
- Setting `asynchronous: true` on the `Loader` keeps the UI thread responsive
  during parsing and object construction.
- A `BusyIndicator` is visible while `status === Loader.Loading`.
- The `onLoaded` signal handler calls `item.forceActiveFocus()` once the
  component is ready.

### Status bar
- A persistent footer row mirrors `Loader.status` for both loaders using a
  helper function that maps the integer enum to a readable string.

## Files

| File | Purpose |
|---|---|
| `Main.qml` | ApplicationWindow, two Loader sections, status bar |
| `DetailPane.qml` | Simple detail view; `required property string title` |
| `HeavyComponent.qml` | Simulated heavy component; `required property int itemCount` |

## Key API

| API | Demonstrated in |
|---|---|
| `Loader.active` | Section 1 toggle button |
| `Loader.setSource(url, properties)` | Passing initial properties |
| `Loader.asynchronous` | Section 2 async load |
| `Loader.status` (Null/Loading/Ready/Error) | Status bar labels |
| `Loader.onLoaded` | Giving focus after async load |

## How to run

```bash
qml Main.qml
```

Requires Qt 6.2 or later with `QtQuick.Controls`.
