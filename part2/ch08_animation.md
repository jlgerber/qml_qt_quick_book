# Chapter 8: Animation and State Machines

## The Animation Framework: `Transition`, `Behavior`, `SequentialAnimation`

Qt Quick's animation framework is declarative: animations are described as properties of items or as standalone objects, not as procedural code that runs step by step. The framework integrates with the binding engine and the scene graph's frame clock so animations run at display refresh rate with smooth interpolation.

### Property Animations

`PropertyAnimation` is the fundamental animation type. It interpolates a single property between two numeric values:

```qml
PropertyAnimation {
    id: fadeOut
    target: myRect
    property: "opacity"
    from: 1.0; to: 0.0
    duration: 300
    easing.type: Easing.InOutQuad
}

Button {
    text: "Fade"
    onClicked: fadeOut.start()
}
```

Specialized subclasses are preferred when the type is known:

| Type | Interpolates |
|---|---|
| `NumberAnimation` | Numeric properties |
| `ColorAnimation` | `color` properties (interpolates in RGBA space) |
| `RotationAnimation` | Rotation angle with direction awareness (clockwise, shortest, counterclockwise) |
| `Vector3dAnimation` | 3D vector properties |
| `AnchorAnimation` | Anchor changes within a state transition |
| `PathAnimation` | Moves an item along a `Path` |
| `SmoothedAnimation` | Tracks a value continuously, with velocity limits |
| `SpringAnimation` | Physics-based spring tracking |

### `Behavior`

A `Behavior` automatically animates every change to a property, regardless of what caused the change:

```qml
Rectangle {
    color: highlighted ? "#3daee9" : "#2d2d2d"

    Behavior on color {
        ColorAnimation { duration: 150; easing.type: Easing.OutCubic }
    }
}
```

Now every assignment to `color` — from bindings, JavaScript, state changes — is intercepted and animated. This is the most declarative form of animation: you specify what to animate, not when.

Behaviors can be disabled temporarily:

```qml
Behavior on x {
    enabled: !instantMove
    NumberAnimation { duration: 300; easing.type: Easing.OutBack }
}
```

### Composite Animations

**`SequentialAnimation`**: runs animations one after another:

```qml
SequentialAnimation {
    id: bounceIn

    NumberAnimation {
        target: item; property: "scale"
        from: 0; to: 1.1; duration: 200
        easing.type: Easing.OutCubic
    }
    NumberAnimation {
        target: item; property: "scale"
        from: 1.1; to: 1.0; duration: 100
        easing.type: Easing.InCubic
    }
}
```

**`ParallelAnimation`**: runs animations simultaneously:

```qml
ParallelAnimation {
    NumberAnimation { target: item; property: "opacity"; to: 1; duration: 300 }
    NumberAnimation { target: item; property: "scale"; from: 0.8; to: 1; duration: 300 }
}
```

**`PauseAnimation`**: introduces a delay within a sequence:

```qml
SequentialAnimation {
    NumberAnimation { target: item; property: "opacity"; to: 0; duration: 200 }
    PauseAnimation { duration: 100 }
    NumberAnimation { target: item; property: "opacity"; to: 1; duration: 200 }
}
```

**`ScriptAction`**: runs JavaScript at a specific point in a sequence:

```qml
SequentialAnimation {
    NumberAnimation { target: flyout; property: "y"; to: -flyout.height; duration: 250 }
    ScriptAction { script: flyout.visible = false }
}
```

### Easing Functions

The easing curve shapes the interpolation between start and end values. Qt provides the full set of Robert Penner's easing functions plus bezier curves:

```qml
easing.type: Easing.OutElastic
easing.amplitude: 1.0     // for elastic easings
easing.period: 0.3        // for elastic easings
easing.overshoot: 1.70158 // for back easings

// Custom bezier
easing.type: Easing.BezierSpline
easing.bezierCurve: [0.25, 0.1, 0.25, 1.0]  // control points
```

### `Transition`

A `Transition` defines animations that run when an item changes state (see the `State` section below). It is the bridge between the state machine and the animation framework:

```qml
transitions: [
    Transition {
        from: "normal"; to: "expanded"
        NumberAnimation {
            properties: "width,height"
            duration: 300
            easing.type: Easing.OutCubic
        }
        ColorAnimation { duration: 300 }
    },
    Transition {
        from: "expanded"; to: "normal"
        NumberAnimation {
            properties: "width,height"
            duration: 200
        }
    }
]
```

Omitting `from` and `to` makes the transition run on any state change.

### `SmoothedAnimation` and `SpringAnimation`

These are special animations that track a *changing target value* rather than animating to a fixed endpoint:

**`SmoothedAnimation`**: provides velocity-limited smooth tracking:

```qml
Rectangle {
    x: targetX   // targetX changes externally

    Behavior on x {
        SmoothedAnimation {
            velocity: 200   // max pixels per second
            easing.type: Easing.InOutQuad
        }
    }
}
```

**`SpringAnimation`**: simulates a spring-mass system:

```qml
Behavior on x {
    SpringAnimation {
        spring: 3
        damping: 0.2
        epsilon: 0.25
    }
}
```

These are ideal for following cursor position, tracking list scroll positions, or animating data-driven visualizations where the endpoint is continuously updated.

---

## `State` and `StateGroup`: Modeling UI State Declaratively

### `State`

A `State` represents a named configuration of property values that an item can be in. The `state` property of any `Item` holds the name of the current state:

```qml
Rectangle {
    id: panel
    width: 200; height: 48
    color: "#2d2d2d"

    property bool expanded: false
    state: expanded ? "expanded" : "normal"

    states: [
        State {
            name: "normal"
            PropertyChanges { target: panel; height: 48; color: "#2d2d2d" }
            PropertyChanges { target: content; opacity: 0; visible: false }
        },
        State {
            name: "expanded"
            PropertyChanges { target: panel; height: 240; color: "#1e1e1e" }
            PropertyChanges { target: content; opacity: 1; visible: true }
        }
    ]

    transitions: [
        Transition {
            NumberAnimation { properties: "height"; duration: 250; easing.type: Easing.OutCubic }
            ColorAnimation { duration: 250 }
            NumberAnimation { target: content; property: "opacity"; duration: 200 }
        }
    ]
}
```

When `expanded` changes, the `state` binding re-evaluates, the new state's `PropertyChanges` are applied, and the matching `Transition` animates the change.

### `PropertyChanges`

`PropertyChanges` records which properties to set when entering a state, and restores them when leaving (unless `restoreEntryValues: false` is set):

```qml
State {
    name: "selected"
    PropertyChanges { target: item; scale: 1.05; z: 10 }
    PropertyChanges { target: item.background; color: "#3daee9" }
    PropertyChanges { target: shadowLayer; visible: true }
}
```

`PropertyChanges` can also change signal handler implementations, effectively switching behavior by state:

```qml
State {
    name: "editMode"
    PropertyChanges {
        target: tapHandler
        onTapped: openEditor()
    }
}
```

### `StateGroup`

`StateGroup` allows multiple independent state machines on one item:

```qml
Item {
    StateGroup {
        id: visibilityStates
        states: [
            State { name: "hidden"; PropertyChanges { target: root; opacity: 0 } },
            State { name: "visible"; PropertyChanges { target: root; opacity: 1 } }
        ]
    }

    StateGroup {
        id: selectionStates
        states: [
            State { name: "unselected" },
            State { name: "selected"; PropertyChanges { target: highlight; visible: true } }
        ]
    }
}
```

Each `StateGroup` has its own `state` property and `transitions`. This avoids combinatorial explosion: two independent axes of state with 2 values each would require 4 combined states in a single state machine; two `StateGroup`s require only 2 + 2.

---

## `AnimatedSprite`, `PathAnimation`, and Canvas-Based Effects

### `AnimatedSprite`

`AnimatedSprite` plays a spritesheet animation — a sequence of frames laid out on a single image:

```qml
AnimatedSprite {
    id: character
    width: 64; height: 64
    source: "character.png"

    frameCount: 8
    frameWidth: 64
    frameHeight: 64
    frameRate: 12          // frames per second

    loops: Animation.Infinite
    running: true
}
```

For complex sprite state machines (idle → walk → run → jump), use `SpriteSequence` with named `Sprite` states and transitions between them:

```qml
SpriteSequence {
    sprites: [
        Sprite {
            name: "idle"
            source: "character.png"; frameCount: 4; frameX: 0
            frameDuration: 200
            to: { "walk": 1 }   // can transition to "walk"
        },
        Sprite {
            name: "walk"
            source: "character.png"; frameCount: 8; frameX: 256
            frameDuration: 80
            to: { "idle": 0.3, "run": 0.7 }
        }
    ]
}
```

Trigger transitions with `SpriteSequence.jumpTo("walk")`.

### `PathAnimation`

`PathAnimation` moves an item along a `Path`:

```qml
Path {
    id: trackPath
    startX: 0; startY: 100
    PathCubic {
        x: 400; y: 100
        control1X: 100; control1Y: 0
        control2X: 300; control2Y: 200
    }
}

PathAnimation {
    id: moveAlong
    target: carIcon
    path: trackPath
    duration: 2000
    orientToPath: true      // rotate item to follow path tangent
    loops: Animation.Infinite
}
```

`orientToPath: true` automatically rotates the target item to face the direction of travel — essential for vehicles, arrows, and any directional element.

### Canvas-Based Effects

`Canvas` provides a 2D drawing API equivalent to the HTML5 Canvas. It is the escape hatch for custom rendering that the scene graph primitives cannot express:

```qml
Canvas {
    width: 300; height: 300
    onPaint: {
        let ctx = getContext("2d")
        ctx.clearRect(0, 0, width, height)

        // Draw a filled arc (pie chart segment)
        ctx.beginPath()
        ctx.moveTo(width / 2, height / 2)
        ctx.arc(width / 2, height / 2, 120, 0, Math.PI * 2 * progress)
        ctx.closePath()
        ctx.fillStyle = "#3daee9"
        ctx.fill()
    }

    property real progress: 0.65
    onProgressChanged: requestPaint()
}
```

`requestPaint()` schedules a repaint on the next frame. `Canvas` renders on the main thread and uploads its result to a GPU texture, making it less efficient than scene graph nodes for high-frequency updates. For frequently-updated custom rendering, prefer a C++ `QQuickItem` with a custom scene graph node (Chapter 17).

For static or infrequently-updated effects, `Canvas` is entirely appropriate and avoids the complexity of C++.

---

## Animation Performance Considerations

### Animating on the Render Thread

The Qt Quick render thread can run animations independently of the main thread for a subset of property animations. `NumberAnimation` on `x`, `y`, `width`, `height`, `opacity`, `rotation`, and `scale` can be promoted to render-thread animation when:

1. The property is on a scene graph node directly
2. No JavaScript runs in the animation
3. The item's `layer.enabled` is false

In practice, most simple `Behavior`-driven animations run smoothly even on the main thread because they are driven by the scene graph's frame clock and Qt Quick processes them before scene sync.

The sign of main-thread animation bottleneck is jank during concurrent JavaScript execution. The mitigation is to keep JS handlers brief and move computation to C++.

### Transform vs. Position Animation

Animating `rotation` and `scale` (transforms) is cheaper than animating `width` and `height` (geometry), because transforms only update a matrix node in the scene graph. Geometry changes may cause layout recalculation and child repositioning. When implementing a "zoom in" effect, prefer `scale` animation over `width`/`height` animation.

---

## Summary

Qt Quick's animation framework covers the full spectrum from simple property interpolation to physics-based tracking to complex coordinated sequences. The `Behavior` type provides the most declarative form — automatic animation of all property changes — while `Transition` bridges state machines and animations. States and `StateGroup` give a principled way to model multi-axis UI state without combinatorial explosion. `AnimatedSprite` and `PathAnimation` address game-adjacent use cases. `Canvas` serves as a flexible 2D drawing escape hatch. Together, these tools make it possible to implement sophisticated, fluid UIs entirely in QML.
