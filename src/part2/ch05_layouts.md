# Chapter 5: Layouts, Positioners, and Responsive Design

## `RowLayout`, `ColumnLayout`, `GridLayout`: Sizing Policies and Attached Properties

Qt Quick provides two distinct mechanisms for arranging multiple items: *positioners* and *layouts*. They look similar in QML but operate on fundamentally different principles. Positioners (`Row`, `Column`, `Grid`, `Flow`) arrange items based on their *natural* (implicit) size and do not negotiate size with children. Layouts (`RowLayout`, `ColumnLayout`, `GridLayout`) participate in a constraint-solving pass that distributes available space among children according to sizing policies.

For any UI that needs to fill space, respond to window resizing, or align items across rows, layouts are the correct choice.

### The Layout Engine

Qt Quick Layouts uses a two-pass algorithm per axis:

1. **Minimum / preferred / maximum size collection**: Each child's `Layout.minimumWidth`, `Layout.preferredWidth`, and `Layout.maximumWidth` (and height equivalents) are collected.
2. **Space distribution**: Available space is distributed. First, all items get their preferred size. If there is extra space, items with `Layout.fillWidth: true` share it proportionally via `Layout.horizontalStretchFactor`. If there is insufficient space, items are shrunk toward their minimum.

This mirrors the box model in CSS flexbox and Qt Widgets' `QSizePolicy`.

### Attached Layout Properties

Children communicate their sizing preferences to the layout through *attached properties* on the `Layout` type:

```qml
RowLayout {
    spacing: 8

    TextField {
        Layout.fillWidth: true          // take all available horizontal space
        Layout.minimumWidth: 100
        Layout.preferredWidth: 200
    }

    Button {
        text: "Search"
        Layout.preferredWidth: 80
        Layout.fillWidth: false         // fixed size
    }
}
```

Full set of attached properties:

| Property | Effect |
|---|---|
| `Layout.fillWidth` / `Layout.fillHeight` | Expand to fill available space on that axis |
| `Layout.minimumWidth` / `Layout.minimumHeight` | Hard lower bound |
| `Layout.preferredWidth` / `Layout.preferredHeight` | Target size when space allows |
| `Layout.maximumWidth` / `Layout.maximumHeight` | Hard upper bound |
| `Layout.horizontalStretchFactor` / `Layout.verticalStretchFactor` | Relative weight when distributing surplus space among filling items |
| `Layout.alignment` | Alignment within the cell (`Qt.AlignLeft`, `Qt.AlignVCenter`, etc.) |
| `Layout.margins` | Per-item margins (additive with `spacing`) |
| `Layout.columnSpan` / `Layout.rowSpan` | Span multiple cells in `GridLayout` |
| `Layout.column` / `Layout.row` | Explicit cell placement in `GridLayout` |

### Implicit Size Propagation

Layouts compute their own `implicitWidth` and `implicitHeight` from the children's preferred sizes plus spacing. This propagates up the item tree, allowing a layout inside a container to size the container correctly without hardcoded dimensions:

```qml
Dialog {
    // Dialog sizes itself to its contentItem's implicit size
    contentItem: ColumnLayout {
        spacing: 12
        // Each item's implicit size drives the column's implicit size
        Label { text: "Username" }
        TextField { Layout.preferredWidth: 240 }
        Label { text: "Password" }
        TextField { echoMode: TextInput.Password; Layout.preferredWidth: 240 }
    }
}
```

### `RowLayout`

Items arranged horizontally. `spacing` sets the gap between items (not at the edges). By default, items are sized to their `implicitWidth` and aligned to the top of the layout's height.

```qml
RowLayout {
    anchors.fill: parent
    spacing: 4

    ToolButton { icon.source: "back.svg" }
    Label {
        text: currentPage.title
        Layout.fillWidth: true
        elide: Text.ElideRight
    }
    ToolButton { icon.source: "menu.svg" }
}
```

### `ColumnLayout`

Items arranged vertically. The same principles apply on the vertical axis.

```qml
ColumnLayout {
    anchors.fill: parent
    spacing: 0

    HeaderBar { Layout.fillWidth: true }
    ScrollView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        contentItem: DocumentView { }
    }
    StatusBar { Layout.fillWidth: true }
}
```

### `GridLayout`

Items arranged in a two-dimensional grid. Column count is set via `columns` (or equivalently `rows` for row-dominant flow):

```qml
GridLayout {
    columns: 2
    rowSpacing: 8
    columnSpacing: 16

    Label { text: "First name" }
    TextField { Layout.fillWidth: true }

    Label { text: "Last name" }
    TextField { Layout.fillWidth: true }

    Label { text: "Email" }
    TextField {
        Layout.fillWidth: true
        Layout.columnSpan: 1
    }
}
```

Explicit placement via `Layout.row` and `Layout.column` is useful when items appear in a non-sequential or sparse grid:

```qml
GridLayout {
    columns: 3

    Label { text: "A"; Layout.row: 0; Layout.column: 0 }
    Label { text: "B"; Layout.row: 0; Layout.column: 2 }  // skip column 1
    Label { text: "C"; Layout.row: 1; Layout.column: 0; Layout.columnSpan: 3 }
}
```

---

## Anchors vs. Layouts: Performance Trade-offs and When to Choose Each

### When to Use Anchors

Anchors are evaluated by the binding engine — each anchor is a binding that updates when the referenced item's geometry changes. They are optimal for:

- **Two-item relationships**: "this item's right edge aligns with that item's left edge"
- **Filling a parent**: `anchors.fill: parent` is the fastest way to make an item fill its container
- **Centering**: `anchors.centerIn: parent`
- **Items not in a list or grid**: toolbars, overlays, decorations

```qml
// Correct use of anchors: simple parent-relative positioning
Rectangle {
    anchors.fill: parent
    anchors.margins: 16
}
```

### When to Use Layouts

Layouts are evaluated by the Qt Quick Layouts engine, which runs a separate constraint-solving pass. They are optimal for:

- **Variable numbers of items**: adding or removing items from a layout is automatic
- **Space distribution**: items that share available space proportionally
- **Form layouts**: label-field pairs with aligned columns
- **Any sequence of items whose total size must fill the container**

### The Mixing Problem

Do not mix anchors and layout attached properties on the same item. An item inside a layout should not have `anchors.left`, `anchors.right` etc. — the layout manages its position. Use `Layout.alignment` for alignment within a layout cell.

The combination that is valid and common: use anchors to fit a layout into its parent, then use layout properties inside:

```qml
ColumnLayout {
    anchors.fill: parent   // anchor the layout itself into its parent
    spacing: 8

    TextField { Layout.fillWidth: true }   // layout properties on children
    Button { text: "Submit" }
}
```

### Performance Comparison

For simple cases (2–10 items, static structure), the difference is negligible. At scale:

- **Anchors**: O(n) binding evaluations per layout pass, each potentially triggering further bindings. Complex anchor webs can create cascading binding updates.
- **Layouts**: A single constraint pass runs once per layout invalidation, resolving all items in one sweep. More efficient for large, dynamic item sets.

For items inside `ListView` delegates, prefer neither anchors nor layouts for the few outermost items — instead use explicit `x`/`y`/`width`/`height` where possible, since delegates are instantiated in the thousands.

---

## Adaptive UIs: `Screen`, `Window` Geometry, and Multi-DPI Handling

### The `Screen` Attached Type

The `Screen` attached type provides information about the physical display:

```qml
Item {
    property real dpr: Screen.devicePixelRatio
    property bool isHighDPI: Screen.devicePixelRatio > 1.5
    property bool isLandscape: Screen.width > Screen.height
    property int screenWidth: Screen.width      // logical pixels
    property int screenHeight: Screen.height
    property real screenDPI: Screen.pixelDensity * 25.4  // ppi
}
```

Attach `Screen` to any `Item` to read the screen hosting that item — relevant in multi-monitor setups where different windows may be on screens with different DPRs.

### Responsive Layout Strategies

Qt Quick does not have a built-in breakpoint system like CSS media queries, but one is straightforward to build:

```qml
ApplicationWindow {
    id: root

    // Breakpoints
    readonly property bool isCompact: width < 600
    readonly property bool isMedium: width >= 600 && width < 1200
    readonly property bool isExpanded: width >= 1200

    RowLayout {
        anchors.fill: parent

        // Navigation: sidebar on expanded, drawer on compact
        NavigationDrawer {
            visible: root.isExpanded
            Layout.preferredWidth: 256
            Layout.fillHeight: true
        }

        StackView {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }

    Drawer {
        visible: !root.isExpanded
        // Shown as overlay on compact screens
    }
}
```

Binding visual structure to `width` ranges reacts smoothly as the user resizes the window, which is appropriate for desktop. For mobile, where the screen size is fixed at launch, you can check once in `Component.onCompleted` and set a mode property.

### Multi-DPI Image Handling

Qt automatically selects high-resolution image assets when they follow the `@2x`/`@3x` naming convention:

```
images/
├── icon.png          (1x — 32×32)
├── icon@2x.png       (2x — 64×64)
└── icon@3x.png       (3x — 96×96)
```

```qml
Image {
    source: "images/icon.png"  // Qt selects @2x or @3x automatically
    width: 32; height: 32      // logical size; physical size varies with DPR
}
```

For SVG assets, DPI scaling is automatic — SVGs are rasterized at the physical pixel size and always appear sharp.

### Window Sizing and Constraints

```qml
ApplicationWindow {
    minimumWidth: 480
    minimumHeight: 320
    width: 1024
    height: 768

    // Save and restore window geometry
    Component.onCompleted: {
        if (settings.windowWidth > 0) {
            width = settings.windowWidth
            height = settings.windowHeight
            x = settings.windowX
            y = settings.windowY
        }
    }

    onClosing: {
        settings.windowWidth = width
        settings.windowHeight = height
        settings.windowX = x
        settings.windowY = y
    }
}
```

`Settings` from `Qt.labs.settings` persists values across sessions automatically.

### `FontMetrics` and Density-Independent Sizing

Avoid hardcoding pixel values where the intent is to track text size. Use `FontMetrics` to size containers relative to font metrics:

```qml
FontMetrics {
    id: fm
    font: myFont
}

Rectangle {
    height: fm.height * 2    // two line heights, scales with font size
}
```

This is essential for accessibility: users who increase system font sizes expect UI elements to accommodate the larger text.

---

## Positioners: `Row`, `Column`, `Grid`, `Flow`

For completeness — positioners are appropriate when:
- Item sizes are fixed and known
- No space-filling is needed
- You want to avoid the overhead of the layout engine

```qml
// Flow wraps items like word-wrap text
Flow {
    width: parent.width
    spacing: 8

    Repeater {
        model: tags
        delegate: Chip { text: modelData }
    }
}
```

`Flow` is the positioner with no layout equivalent — it wraps items to the next line when horizontal space is exhausted, useful for tag clouds and chip groups.

---

## Summary

The layouts system in Qt Quick is a full constraint-solving engine that distributes space, enforces minimums and maximums, and propagates implicit sizes up the hierarchy. Understanding the difference between anchors (binding-based, two-item relationships) and layouts (constraint-based, multi-item space distribution) determines which to reach for in any given situation. Combining them correctly — anchor layouts into parents, use layout attached properties inside — produces clean, maintainable geometry code. Layer responsive breakpoints on top of this to handle the full range of screen sizes and densities.
