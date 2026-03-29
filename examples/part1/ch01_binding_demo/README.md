# Ch01 — The Binding Engine

## What it demonstrates

- **Live property bindings**: two child rectangles whose widths are always a
  fixed percentage of a parent rectangle; the parent's width is driven by a
  `Slider`.
- **Binding breakage**: clicking "Break binding" assigns a plain JavaScript
  value to a property, which silently destroys the binding and freezes the
  width.
- **`Qt.binding()` restoration**: clicking "Restore with Qt.binding()" installs
  a new binding expression at runtime, re-linking the property to the slider.
- **Text binding**: a `Label` whose `text` property re-evaluates automatically
  whenever the master width changes.

## Key concepts

| Concept | Where in the file |
|---|---|
| Binding to a parent property | `leftChild.width: parentRect.width * 0.40` |
| Binding breakage by assignment | `breakableRect.width = breakableRect.width` |
| Runtime binding restoration | `Qt.binding(function() { return root.masterWidth })` |
| Derived text binding | `text: root.masterWidth.toFixed(0) + " px"` |

## How to run

```bash
qml Main.qml
```

Requires Qt 6.2 or later with the `QtQuick.Controls` module.
