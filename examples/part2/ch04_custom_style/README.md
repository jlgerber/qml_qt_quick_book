# Chapter 4 — Custom Qt Quick Controls Style

## What it demonstrates

- How to create a minimal **custom Qt Quick Controls 2 style** by placing QML
  files inside a named module directory (`MyStyle/`).
- Overriding `Button` and `TextField` using `QtQuick.Templates` base types so
  that all Controls logic (enabled, hovered, pressed, focus, accessibility) is
  inherited without any default-style visuals.
- **Behavior on color** (`ColorAnimation`) for smooth hover/press transitions.
- An animated bottom border (`NumberAnimation` on `height`) for the focused
  TextField — a common Material-style pattern.
- Registering the style via a `qmldir` module file.

## File layout

```
ch04_custom_style/
├── Main.qml              # Demo window (ApplicationWindow)
└── MyStyle/
    ├── qmldir            # Module declaration
    ├── Button.qml        # Custom Button control
    └── TextField.qml     # Custom TextField control
```

## How to run

```bash
cd examples/part2/ch04_custom_style
qml -I . Main.qml
```

The `-I .` flag adds the current directory to the QML import path so that
`import MyStyle` resolves to the `MyStyle/` subdirectory.

Alternatively, set the environment variable before running:

```bash
QT_QUICK_CONTROLS_STYLE=MyStyle qml -I . Main.qml
```
