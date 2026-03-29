# Chapter 5 — Responsive Layout

## What it demonstrates

- **Breakpoint properties** (`isCompact`, `isExpanded`) computed from
  `ApplicationWindow.width` — the idiomatic QML approach to responsive design.
- Swapping between a `ColumnLayout` (compact, < 600 px) and a `GridLayout`
  (normal / expanded, ≥ 600 px) using a `Loader` and `sourceComponent`
  bindings.
- An **animated sidebar** that slides in/out with `Behavior on width` +
  `NumberAnimation` when the window crosses the 1000 px breakpoint.
- A reusable `MetricCard` inline component built with `GridLayout` for its
  two-column form layout.
- A live breakpoint indicator badge in the toolbar, useful while prototyping.

## How to run

```bash
cd examples/part2/ch05_responsive_layout
qml Main.qml
```

Drag the window edges to see the layout adapt between compact, normal, and
expanded modes.
