# Chapter 2: QML Language Deep Dive

## Type System, Property Bindings, and the Binding Engine

### The QML Type System

QML is a statically-typed language at the property level, even though JavaScript — a dynamically-typed language — is embedded within it. Every property in QML has a declared type. The engine enforces type compatibility at binding evaluation time and, in Qt 6 with `qmlsc` enabled, at compile time.

Primitive property types map directly to C++ equivalents:

| QML type | C++ type | Notes |
|---|---|---|
| `int` | `int` | |
| `real` | `double` | Also accepts `float` |
| `bool` | `bool` | |
| `string` | `QString` | |
| `url` | `QUrl` | |
| `color` | `QColor` | Accepts `"#rrggbb"`, `"name"`, `Qt.rgba()` |
| `date` | `QDateTime` | |
| `var` | `QVariant` | Escape hatch — avoid where possible |
| `list<T>` | `QQmlListProperty<T>` | Typed list of QObject subclass |

Value types (structs without QObject identity) such as `point`, `size`, `rect`, `font`, `vector2d`, `matrix4x4`, and `quaternion` are passed by value and do not participate in the QObject ownership model.

Object types — anything that derives from `QObject` — are reference types in QML. Assigning one to a property copies the reference, not the object.

### Property Declarations

In QML components you define, you declare properties with `property`:

```qml
// In MyItem.qml
Item {
    property int count: 0
    property string label: "unnamed"
    property color accent: "#3daee9"
    property var payload   // untyped — use sparingly
    property list<Rectangle> boxes
}
```

Properties can have default values (the expression after the colon). That expression is itself a binding if it references other properties.

### The Binding Engine

A binding is an expression — evaluated by the JavaScript engine — whose result is assigned to a property. What makes bindings special is that the QML engine tracks which other properties the expression *reads* during evaluation. Those properties become *dependencies* of the binding. When any dependency changes, the engine marks the binding as dirty and schedules re-evaluation.

```qml
Rectangle {
    width: parent.width * 0.5   // depends on parent.width
    height: width                // depends on this.width
    color: highlighted ? "steelblue" : "transparent"  // depends on highlighted
}
```

Change `parent.width`, and `width` re-evaluates. Change `width`, and `height` re-evaluates. Change `highlighted`, and `color` re-evaluates. None of this requires explicit wiring.

#### Binding Breakage

Bindings are broken — permanently — when a property is assigned a plain value in JavaScript:

```qml
Rectangle {
    width: parent.width * 0.5  // binding active

    MouseArea {
        anchors.fill: parent
        onClicked: parent.width = 200  // BREAKS the binding
    }
}
```

After the click, `width` is `200` and will never again react to `parent.width`. To restore a binding programmatically, use `Qt.binding()`:

```qml
onClicked: parent.width = Qt.binding(() => parent.width * 0.5)
```

This is a common source of subtle bugs. The rule: in JavaScript handlers, think carefully before assigning to a property that has or should have a binding.

#### Lazy vs. Eager Evaluation

The binding engine evaluates bindings *lazily* by default: a dirty binding is not re-evaluated until its value is read. If nothing reads the value (because the item is off-screen, or the property is not currently used), no re-evaluation occurs. This makes Qt Quick efficient for large item trees where only visible parts are active.

---

## Signals, Signal Handlers, and the Event Loop

### Signals

Every QML property implicitly has a *change signal* named `on<PropertyName>Changed`. You can also declare custom signals:

```qml
Item {
    property int count: 0
    signal thresholdReached(int value)
    signal resetRequested()
}
```

Signals are emitted with call syntax:

```qml
onClicked: {
    count++
    if (count >= 10) thresholdReached(count)
}
```

### Signal Handlers

A signal handler is a special property whose name is `on<SignalName>` with the signal name capitalized. Its value is a JavaScript function body (or a function reference):

```qml
Button {
    text: "Reset"
    onClicked: root.resetRequested()
}
```

Handlers can also be attached with `Connections`, which is necessary when connecting to signals from an object that is not the handler's parent:

```qml
Connections {
    target: someModel
    function onDataChanged() {
        listView.positionViewAtBeginning()
    }
}
```

`Connections` also supports ignoring signals when a condition is false via the `enabled` property — useful for temporarily suspending reactions without disconnecting.

### Connecting Signals to Slots Programmatically

QML objects expose a `.connect()` method on each signal, mirroring Qt's signal-slot connect syntax:

```qml
Component.onCompleted: {
    someObject.someSignal.connect(myHandler)
}

function myHandler(value) {
    console.log("Received:", value)
}
```

Disconnect with `.disconnect()`. Managing these connections carefully is important — connecting the same handler twice creates duplicate invocations, and forgetting to disconnect from destroyed objects causes crashes.

### The Event Loop

Qt Quick operates on Qt's event loop (`QCoreApplication::exec()`). All QML JavaScript and signal processing happens on the main thread within the event loop. Qt Quick's animations and timers post events to the event loop, which the scene graph processes to drive frame rendering.

The event loop processes one event at a time. Long-running synchronous JavaScript will block the loop, causing dropped frames and an unresponsive UI. Any operation that may take more than a few milliseconds — network I/O, file parsing, heavy computation — must be pushed to a background thread or handled asynchronously. The `WorkerScript` element provides a lightweight way to run JavaScript on a worker thread:

```qml
WorkerScript {
    id: worker
    source: "worker.js"

    onMessage: function(msg) {
        // msg.result contains the worker's reply
        processResult(msg.result)
    }
}

onClicked: worker.sendMessage({ action: "compute", input: largeDataSet })
```

For heavier work, delegate to C++ threads or Python async patterns (covered in later chapters).

---

## Component Instantiation, Dynamic Object Creation, and Ownership Semantics

### Static Instantiation

The most common form: a child element declared inside a parent's body is created when the parent is created and destroyed when the parent is destroyed.

```qml
Window {
    Rectangle {
        id: box
        // Created with Window, destroyed with Window
    }
}
```

### Dynamic Instantiation via `Component`

`Component` wraps a subtree that is not immediately instantiated. Call `createObject()` to instantiate it at will:

```qml
Component {
    id: popupComp
    Popup {
        property string message
        // ...
    }
}

function showPopup(msg) {
    let p = popupComp.createObject(root, { message: msg })
    p.closed.connect(() => p.destroy())
}
```

`createObject(parent, properties)` returns the new instance. Pass `null` as parent for an engine-owned object — but be aware that without a parent, the GC manages lifetime and it may be collected sooner than expected.

`p.destroy()` schedules the object for deletion at the end of the current event loop iteration (not immediately). This is intentional: it prevents destroying an object that still has pending signal emissions.

### `Qt.createQmlObject()`

For fully dynamic QML string creation — useful in prototyping but avoid in production:

```qml
let obj = Qt.createQmlObject(
    'import QtQuick; Rectangle { color: "red"; width: 50; height: 50 }',
    parent,
    "dynamic_rect"
)
```

The third argument is a source URL used in error messages. This bypasses the component cache and should not be used in hot paths.

### `Loader`

`Loader` is the idiomatic QML mechanism for deferred and conditional component loading. It instantiates its source component lazily, replaces it when the source changes, and cleanly manages the lifetime of the loaded object:

```qml
Loader {
    id: loader
    active: showDetails
    source: "DetailsPane.qml"
}
```

When `showDetails` becomes false, `active: showDetails` can be used in combination with `asynchronous: true` to load components without blocking the main thread:

```qml
Loader {
    source: "HeavyComponent.qml"
    asynchronous: true
    onLoaded: console.log("Ready")
}
```

---

## JavaScript Integration: Scope, Closures, and When to Avoid JS

### Scope in QML

QML defines several nested scopes that JavaScript expressions can access:

1. **Component scope**: Properties and IDs of items defined in the same `.qml` file
2. **Import scope**: Types and singletons brought in via `import` statements
3. **JS file scope**: Functions and variables defined in imported `.js` files

IDs in QML are effectively global within the component scope. They are not variables — they are compile-time names resolved by the QML engine to object references.

```qml
Item {
    id: root

    Rectangle {
        id: box
        width: 100
    }

    Text {
        text: box.width.toString()  // 'box' resolved at compile time
    }
}
```

### Closures and Memory Leaks

JavaScript closures in QML can create memory leaks by capturing references to QML objects, preventing garbage collection:

```qml
// Potential leak: closure captures 'heavyObject'
Component.onCompleted: {
    let heavyObject = someExpensiveModel
    timer.triggered.connect(() => {
        heavyObject.doSomething()  // heavyObject captured
    })
}
```

If `timer` outlives the intended scope of `heavyObject`, the closure keeps it alive. Prefer using `Connections` with a `target` and `enabled` property instead of manually connecting closures.

### JavaScript Libraries

QML can import `.js` files as modules:

```qml
import "utils.js" as Utils

Text {
    text: Utils.formatDate(model.timestamp)
}
```

The `.js` file uses standard ECMAScript module-style exports (in Qt 6, `.mjs` files for ES modules are also supported). This is the right place for pure utility functions: date formatting, string manipulation, data transformation. Keep these functions stateless where possible.

### When to Avoid JavaScript

JavaScript in QML is convenient but carries costs:

- **Binding overhead**: Complex binding expressions in JavaScript are slower than equivalent C++ property computations.
- **JIT cold starts**: The V4 JIT warms up over time; code executed rarely stays in interpreter mode.
- **Debugging difficulty**: JS errors in QML report file and line numbers but lack the stack-trace richness of C++ or Python.
- **Type safety gaps**: `var`-typed properties and untyped JS defeat the QML type system and prevent `qmlsc` optimization.

The guideline: use JavaScript in QML for UI logic only — reacting to input, driving animations, coordinating component state. Move computation, data transformation, and I/O to Python or C++ backends.

---

## Summary

QML's language design is intentionally minimal on the declarative side and pragmatic on the JavaScript side. Its power lies in the binding engine, which makes reactive UI natural. The signal system gives clean inter-component communication without tight coupling. Dynamic instantiation and `Loader` support sophisticated lazy-loading patterns. JavaScript fills in the gaps but should be kept thin — the more logic lives in QML JS, the harder the application is to test, profile, and maintain.
