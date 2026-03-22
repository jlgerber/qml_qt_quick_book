# Chapter 3: Qt Quick Core Primitives

## The Item Tree: Geometry, Anchoring, and the Coordinate System

### `Item`: The Universal Base

Every visual element in Qt Quick is an `Item` or a subclass of it. `Item` itself is invisible — it has no fill, no border, no text. Its role is to define a rectangular region in the scene, provide a coordinate origin for children, and carry common properties shared by all visual types: `x`, `y`, `width`, `height`, `opacity`, `visible`, `enabled`, `clip`, `z`, and `scale`.

The item tree is a parent-child hierarchy. Children are positioned in their parent's coordinate space. A child at `x: 10, y: 10` is 10 logical pixels from the parent's top-left corner, regardless of where the parent sits in the window.

```qml
Item {
    id: container
    x: 50; y: 50
    width: 200; height: 200

    Rectangle {
        // This is at window coordinates (60, 60), but declared at (10, 10)
        x: 10; y: 10
        width: 50; height: 50
        color: "steelblue"
    }
}
```

### Logical Pixels and DPI

Qt Quick works in *logical pixels*, not physical pixels. On a high-DPI display, one logical pixel corresponds to multiple physical pixels. The mapping is controlled by the device pixel ratio (`Screen.devicePixelRatio`). Qt handles scaling automatically for most cases — images loaded via `Image` are selected at the appropriate resolution if `@2x` variants are available.

For custom rendering code (scene graph nodes, `Canvas`), you must account for the device pixel ratio manually by multiplying by `Screen.devicePixelRatio` when specifying physical pixel dimensions.

### The Coordinate Transformation API

Converting coordinates between items is a frequent need:

```qml
// Map a point from item A's coordinate space to item B's
let pointInB = itemA.mapToItem(itemB, Qt.point(10, 10))

// Map to/from the scene (window) coordinate space
let scenePoint = myItem.mapToScene(Qt.point(0, 0))
let localPoint = myItem.mapFromScene(Qt.point(mouseX, mouseY))
```

These are essential when working with drag-and-drop, tooltips, or any feature where items at different levels of the hierarchy need to share coordinates.

### Anchoring

Anchors are a declarative constraint system built into `Item`. They express geometric relationships between items' edges and centers without explicit `x`/`y` values:

```qml
Rectangle {
    id: toolbar
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    height: 48
}

Rectangle {
    id: content
    anchors.top: toolbar.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
}
```

Anchor shortcuts reduce verbosity:

```qml
anchors.fill: parent          // fills parent completely
anchors.centerIn: parent      // centers in parent
anchors.horizontalCenter: parent.horizontalCenter
anchors.verticalCenter: parent.verticalCenter
```

Anchors have margins:

```qml
anchors.fill: parent
anchors.margins: 16       // uniform margin on all sides
anchors.topMargin: 8      // override individual sides
```

#### Anchor Constraints and Layout Conflicts

Anchors and explicit `x`/`y`/`width`/`height` values conflict. If an item has `anchors.left` and `anchors.right`, assigning `width` directly is meaningless — the width is determined by the anchors. Qt will emit a warning.

Anchors and `Layout` attached properties also conflict. Items inside a `RowLayout` or `GridLayout` must use `Layout.preferredWidth` etc., not anchors for the axis managed by the layout engine.

---

## Transforms, Opacity, and the Layer System

### Transforms

The `transform` property accepts a list of `Transform` subclasses applied in order:

```qml
Rectangle {
    width: 100; height: 100
    transform: [
        Translate { x: 50 },
        Rotation { angle: 45; origin.x: 50; origin.y: 50 },
        Scale { xScale: 1.5; yScale: 1.5; origin.x: 50; origin.y: 50 }
    ]
}
```

Convenience properties on `Item` cover the common cases:

```qml
Item {
    rotation: 45        // degrees, around transform origin
    scale: 1.5          // uniform scale around transform origin
    transformOrigin: Item.Center   // or TopLeft, BottomRight, etc.
}
```

These convenience properties are shortcuts to the `transform` list and can be animated directly.

### Opacity

`opacity` ranges from `0.0` (fully transparent) to `1.0` (fully opaque) and is inherited by the entire subtree. An item with `opacity: 0.5` makes all its children appear at half opacity, compounded with any opacity set on individual children.

Setting `visible: false` is more efficient than `opacity: 0` when the item does not need to be in the scene graph at all — invisible items are still traversed and their children are still rendered (into an offscreen buffer), just not composited.

### Layers

Applying `layer.enabled: true` to an item causes Qt Quick to render that item's subtree into an offscreen texture, then composite that texture into the scene. This enables several effects:

- **Correct opacity on overlapping children**: without a layer, each child composites independently, so overlapping semi-transparent children show through each other. With a layer, the whole subtree is flattened first.
- **`layer.effect`**: apply a `ShaderEffect` or `MultiEffect` to the layer texture.
- **Caching**: static content rendered once to a layer avoids re-rasterization each frame.

```qml
Rectangle {
    layer.enabled: true
    layer.effect: MultiEffect {
        blurEnabled: true
        blurMax: 32
        blur: 0.5
    }
}
```

Layers have a cost: they allocate GPU texture memory and require an additional render pass. Enable them only when the visual effect requires it.

---

## Input Handling: MouseArea, TapHandler, PointerHandler, and Multi-touch

### The Old Model: `MouseArea`

`MouseArea` is the original Qt Quick input handler. It covers a rectangular region and reports mouse button presses, releases, clicks, double-clicks, hover, and wheel events:

```qml
Rectangle {
    MouseArea {
        anchors.fill: parent
        onClicked: console.log("clicked at", mouseX, mouseY)
        onPressed: console.log("pressed, button:", pressedButtons)
        hoverEnabled: true
        onEntered: parent.color = "lightblue"
        onExited: parent.color = "white"
    }
}
```

`MouseArea` has a significant limitation: it participates in a press-grab model where the first `MouseArea` to accept a press grabs it exclusively. Composing multiple `MouseArea`s in a hierarchy — for example, a clickable item inside a `Flickable` — requires careful management of `propagateComposedEvents` and `preventStealing`.

### The New Model: Pointer Handlers

Qt Quick 2's pointer handler framework (`TapHandler`, `DragHandler`, `PinchHandler`, `WheelHandler`, `HoverHandler`) addresses `MouseArea`'s composition limitations. Multiple handlers on the same item or hierarchy can cooperate without stealing from each other.

**`TapHandler`**: Replaces `MouseArea` for click detection:

```qml
Rectangle {
    TapHandler {
        onTapped: console.log("tapped, point:", eventPoint.position)
        onDoubleTapped: console.log("double tap")
        onLongPressed: console.log("long press")
        acceptedButtons: Qt.LeftButton | Qt.RightButton
    }
}
```

**`DragHandler`**: Replaces manual drag logic:

```qml
Rectangle {
    id: draggable
    DragHandler {
        onActiveChanged: if (!active) snapToGrid()
    }
}
```

**`PinchHandler`**: Pinch-to-zoom and rotate:

```qml
Image {
    PinchHandler {
        minimumScale: 0.5
        maximumScale: 4.0
        minimumRotation: -45
        maximumRotation: 45
    }
}
```

**`HoverHandler`**: Hover detection without the full MouseArea overhead:

```qml
HoverHandler {
    id: hover
    cursorShape: Qt.PointingHandCursor
}
Text { color: hover.hovered ? "blue" : "black" }
```

**`WheelHandler`**: Mouse wheel and trackpad scroll:

```qml
WheelHandler {
    onWheel: (event) => zoomFactor += event.angleDelta.y / 1200
}
```

### Handler Grab and Exclusivity

Handlers use a grab model with three levels:

- **Passive grab**: The handler receives events but does not prevent others from receiving them.
- **Exclusive grab**: The handler takes sole control of the pointer point.
- **Cancel**: The handler relinquishes its grab.

By default, a handler that recognizes its gesture takes an exclusive grab. Use `grabPermissions` to tune this:

```qml
DragHandler {
    grabPermissions: PointerHandler.CanTakeOverFromItems |
                     PointerHandler.CanTakeOverFromHandlersOfDifferentType
}
```

### Multi-touch

Pointer handlers are inherently multi-touch aware. Each active touch point is an `eventPoint`. `PinchHandler` tracks two points; a custom handler can track more via `minimumPointCount` and `maximumPointCount`. Mouse input is treated as a single-point touch, so the same handlers work for both.

---

## Focus Management and Keyboard Input

### The Focus System

Qt Quick has two orthogonal focus systems that interact:

**Active focus** (`activeFocus`): The item currently receiving keyboard events. Only one item in the entire scene has active focus at a time.

**Focus scope** (`FocusScope`): An item subtype that creates an isolated focus domain. Within a focus scope, one item holds the scope's *internal* focus. When the scope gains active focus, it delegates to its internally-focused item.

```qml
FocusScope {
    // This scope manages focus for its children independently
    TextField { id: nameField; focus: true }
    TextField { id: emailField }
}
```

Setting `focus: true` requests focus within the item's containing focus scope. If no focus scope contains the item, it requests focus in the root scope (the window).

`forceActiveFocus()` unconditionally gives active focus to an item, bypassing the scope hierarchy. Use it to implement "click to focus" or "tab to focus" manually.

### Key Events

Items with active focus receive `Keys` attached property events:

```qml
Item {
    focus: true
    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Escape) {
            event.accepted = true
            closeDialog()
        }
    }
    Keys.onReturnPressed: submitForm()
}
```

Setting `event.accepted = true` prevents the event from propagating to the parent item. The propagation path goes from the focused item up to its ancestors, then to any `Keys.forwardTo` targets.

**`Keys.forwardTo`** allows routing key events to multiple targets:

```qml
Keys.forwardTo: [searchField, listView]
```

### `Shortcut`

For application-wide key bindings that work regardless of focus, use `Shortcut`:

```qml
Shortcut {
    sequence: StandardKey.Save
    onActivated: document.save()
}

Shortcut {
    sequence: "Ctrl+Shift+F"
    onActivated: searchBar.open()
}
```

`Shortcut` items are typically placed at the window root or in the application shell.

### `TextInput` and `TextEdit`

`TextInput` is a single-line input; `TextEdit` is multi-line. Both are low-level primitives — they have no visual decoration. Qt Quick Controls' `TextField` and `TextArea` wrap these with styling and accessibility support and should be preferred in production UIs.

Key properties for text input primitives:

```qml
TextInput {
    text: model.name
    onTextEdited: model.name = text  // fires only on user edits, not programmatic changes
    onEditingFinished: validate()    // fires on Return/Enter or focus loss
    validator: RegularExpressionValidator { regularExpression: /^\d+$/ }
    echoMode: TextInput.Password     // for password fields
}
```

---

## Summary

Qt Quick's item primitives form the foundation everything else is built on. The geometry system — logical pixels, the coordinate transformation API, and anchors — gives precise control over layout at the item level. Transforms and layers enable visual effects without leaving the retained scene graph model. The pointer handler framework supersedes `MouseArea` for composable, multi-touch-aware input. And the dual focus system — active focus plus focus scopes — gives principled keyboard routing across arbitrarily complex UI hierarchies. These are the tools you reach for when Qt Quick Controls' higher-level components are not sufficient, and understanding them deeply is essential for building custom components.
