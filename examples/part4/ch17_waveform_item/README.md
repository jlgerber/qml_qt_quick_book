# Chapter 17 — Custom QQuickItem with the Qt Quick Scene Graph

## What this example demonstrates

`WaveformItem` is a custom `QQuickItem` that renders an animated line-strip
waveform entirely through the Qt Quick scene graph API — no `QPainter`,
no `Canvas`, no `ShaderEffect`.

| Concept | File |
|---|---|
| `QQuickItem` subclass with `QML_ELEMENT` | `waveformitem.h` |
| `setFlag(ItemHasContents)` — required to receive `updatePaintNode` | `waveformitem.cpp` |
| `QSGGeometryNode` + `QSGGeometry` | `waveformitem.cpp` |
| `QSGGeometry::defaultAttributes_Point2D()` | `waveformitem.cpp` |
| `DrawLineStrip` drawing mode | `waveformitem.cpp` |
| `QSGFlatColorMaterial` | `waveformitem.cpp` |
| Node/material ownership flags (`OwnsGeometry`, `OwnsMaterial`) | `waveformitem.cpp` |
| `markDirty(DirtyGeometry | DirtyMaterial)` | `waveformitem.cpp` |
| `geometryChange()` to respond to resize | `waveformitem.cpp` |
| Driving animation from QML via `Timer` + property assignment | `qml/Main.qml` |

## Project layout

```
ch17_waveform_item/
├── CMakeLists.txt
├── main.cpp
├── waveformitem.h
├── waveformitem.cpp
└── qml/
    └── Main.qml
```

## Prerequisites

- Qt 6.6 or later
- CMake 3.27 or later
- C++20 compiler
- A platform with an OpenGL / Metal / Vulkan / Direct3D backend
  (the scene graph requires a hardware-accelerated renderer)

## Build instructions

```bash
cmake -B build -DCMAKE_PREFIX_PATH=/path/to/Qt6
cmake --build build
./build/waveformapp
```

## Things to try

- Drag the "Line width" slider — the change propagates to the render thread
  via `m_dirty` and `update()` without any mutex because Qt guarantees that
  `updatePaintNode` is only called between GUI-thread sync points.
- Click the colour swatches and observe the material colour change without
  rebuilding the geometry.
- Increase the point count to 512 and watch the waveform remain smooth.
- Resize the window and verify the waveform fills the item correctly because
  `geometryChange()` sets `m_dirty = true`.
- Replace `QSGFlatColorMaterial` with `QSGVertexColorMaterial` to render a
  gradient waveform (advanced exercise).
