# Ch03 — Input Handlers

## What it demonstrates

Qt Quick's pointer-handler types provide a composable, non-exclusive alternative
to the older `MouseArea`.  Each handler attaches directly to its parent item and
can coexist with other handlers on the same item.

### Section 1 — `DragHandler`
- A rectangle is dragged freely across a bounded canvas.
- Its live `x`/`y` position and the handler's `active` flag are shown in a label.

### Section 2 — `TapHandler`
- Each click/tap increments a counter via `onTapped`.
- A long press (hold for ~800 ms) triggers `onLongPressed`, which randomises the
  rectangle's base colour.

### Section 3 — `HoverHandler`
- The `HoverHandler` sets `cursorShape: Qt.PointingHandCursor` so the OS cursor
  changes when entering the rectangle.
- The rectangle's colour and border animate when `hovered` changes.
- The hover point coordinates are displayed in real time.

### Section 4 — `PinchHandler`
- Two-finger pinch gesture on a touch screen (or simulated with the right
  platform plugin) scales the rectangle between 0.3× and 4×.
- Rotation is accumulated from `onRotationChanged(delta)`.
- Separate `Scale` and `Rotation` transforms are applied so origin points stay
  centred.

### Section 5 — `DraggableBox` reusable component
- Three instances of `DraggableBox.qml` sit on the same canvas.
- Each has its own independent `DragHandler` and `TapHandler`.
- Required properties (`boxColor`, `label`) are passed by the caller.

## Files

| File | Purpose |
|---|---|
| `Main.qml` | ApplicationWindow with five demo sections |
| `DraggableBox.qml` | Reusable rectangle with `DragHandler` + `TapHandler` |

## Key API

| Handler | Key properties / signals |
|---|---|
| `DragHandler` | `active`, `xAxis`, `yAxis` |
| `TapHandler` | `onTapped`, `onLongPressed`, `pressed`, `tapCount` |
| `HoverHandler` | `hovered`, `cursorShape`, `point.position` |
| `PinchHandler` | `onScaleChanged(delta)`, `onRotationChanged(delta)`, `minimumScale`, `maximumScale` |

## How to run

```bash
qml Main.qml
```

Requires Qt 6.2 or later.  Touch/pinch gestures on Section 4 require a touch
screen or a platform plugin that supports simulated multi-touch (e.g.,
`QT_QUICK_BACKEND=software` with touch injection).
