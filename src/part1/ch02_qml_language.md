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

---

## Deferred Loading of QML Files

Deferred loading is the practice of delaying the parsing, compilation, and
instantiation of a QML component until it is actually needed, rather than at
application startup. It is one of the most impactful techniques for reducing
time-to-first-frame and keeping memory usage proportional to what is visible.

Qt Quick provides three mechanisms at different levels of control:

| Mechanism | When to use |
|---|---|
| `Loader` | Declarative, condition-driven show/hide of a sub-tree |
| `Component.incubateObject()` | Non-blocking instantiation with progress callbacks |
| `QQmlComponent` (C++) | Full control from C++; custom incubation strategies |

### `Loader`: The Idiomatic QML Approach

`Loader` is an invisible item that manages a single child component. It handles
the full lifecycle: parsing the source file, instantiating the component,
sizing itself to the loaded item, and destroying the item when it is no longer
needed.

#### `source` vs `sourceComponent`

`source` takes a URL (string or `Qt.resolvedUrl()`); the engine fetches and
parses the file on demand:

```qml
Loader {
    id: detailLoader
    source: "DetailPane.qml"
}
```

`sourceComponent` takes an already-parsed `Component` object. Use this when
you have an inline `Component` and want `Loader` to manage instantiation:

```qml
Component {
    id: heavyComp
    HeavyWidget { }
}

Loader {
    sourceComponent: showWidget ? heavyComp : null
}
```

Assigning `null` to either property destroys the loaded item and releases the
memory. This is the primary memory-management tool for optional UI regions.

#### Conditional Loading with `active`

`active` is the clean way to gate loading on a condition without constantly
reassigning `source`:

```qml
Loader {
    active: userIsLoggedIn
    source: "UserDashboard.qml"
}
```

When `active` becomes `false`, the loaded item is destroyed. When it becomes
`true` again, the item is re-created from scratch. If you want the item to
persist in memory while hidden, use `visible: false` on the `Loader` instead
of `active: false`.

#### Asynchronous Loading

By default, `Loader` blocks the main thread while it compiles and instantiates
the component. For large or complex components this causes a visible frame
drop. Setting `asynchronous: true` moves compilation off the main thread:

```qml
Loader {
    id: editorLoader
    source: "RichTextEditor.qml"
    asynchronous: true

    // Show a placeholder until the real component is ready
    Rectangle {
        anchors.fill: parent
        visible: editorLoader.status === Loader.Loading
        color: "#1e1e2e"

        BusyIndicator { anchors.centerIn: parent; running: true }
    }

    onLoaded: editorLoader.item.forceActiveFocus()
}
```

Asynchronous loading uses Qt's thread pool for compilation. Instantiation still
happens on the main thread (because the item tree must be built there), but it
is interleaved with the event loop rather than blocking it — each instantiation
step yields between frames.

> **Component cache interaction**: Once a QML file has been compiled, its
> bytecode is cached. A second `Loader` pointing at the same URL re-uses the
> cache and instantiates synchronously even with `asynchronous: true`, because
> there is no compilation work left to defer.

#### `status` and `progress`

`Loader.status` tracks the loading lifecycle:

| Value | Meaning |
|---|---|
| `Loader.Null` | No source assigned |
| `Loader.Loading` | Fetch or compilation in progress |
| `Loader.Ready` | Item instantiated and available via `item` |
| `Loader.Error` | Load failed; check `Loader.sourceUrl` for diagnostics |

`Loader.progress` is a `real` in `[0.0, 1.0]` — useful for remote URLs where
the file must be fetched over the network before compilation:

```qml
Loader {
    id: remoteLoader
    source: "https://internal.example.com/ui/Dashboard.qml"
    asynchronous: true

    ProgressBar {
        anchors.fill: parent
        visible: remoteLoader.status === Loader.Loading
        value: remoteLoader.progress
    }
}
```

#### Accessing the Loaded Item

`Loader.item` is the instantiated root object of the loaded component. It is
`null` while `status !== Loader.Ready`:

```qml
Button {
    text: "Focus editor"
    enabled: editorLoader.status === Loader.Ready
    onClicked: editorLoader.item.forceActiveFocus()
}
```

Bind to properties on the loaded item via `item`:

```qml
Text {
    text: editorLoader.item ? editorLoader.item.wordCount.toString() : "—"
}
```

#### Passing Data Into a Loaded Item

**With `setSource()`**: Pass initial property values atomically before the
component is fully instantiated, preventing a frame where properties are at
their default values:

```qml
Loader {
    id: profileLoader
}

function openProfile(userId) {
    profileLoader.setSource("ProfileView.qml", { userId: userId })
}
```

`setSource()` is equivalent to assigning `source` then setting properties, but
atomic — the component sees the correct values from its first binding
evaluation.

**With `required property`**: The cleanest contract. Declare properties on the
loaded component as `required`; the `Loader` must supply them:

```qml
// ProfileView.qml
Item {
    required property string userId
    required property string displayName
    // ...
}
```

```qml
// Caller
Loader {
    source: "ProfileView.qml"
    onLoaded: {
        item.userId = currentUser.id
        item.displayName = currentUser.name
    }
}
```

Or using `setSource()` to supply them at load time:

```qml
profileLoader.setSource("ProfileView.qml", {
    userId: currentUser.id,
    displayName: currentUser.name
})
```

If a `required property` is not supplied, the engine emits a runtime error —
making the missing dependency explicit rather than silently producing a default
value.

**Sending data back out**: Connect to signals on `item` after loading:

```qml
Loader {
    source: "EditDialog.qml"
    onLoaded: {
        item.accepted.connect((result) => applyEdit(result))
        item.rejected.connect(() => loader.active = false)
    }
}
```

---

### `Component` Status Lifecycle

`Component` itself has a `status` property that mirrors `Loader.status`. This
is relevant when you hold a `Component` object and instantiate it manually, or
when a `Loader`'s `sourceComponent` is a dynamically created component:

```qml
Component {
    id: myComp
    // status is Component.Ready immediately for inline components
}
```

For components loaded from a URL via `Qt.createComponent()`:

```qml
Component.onCompleted: {
    let comp = Qt.createComponent("HeavyWidget.qml")
    if (comp.status === Component.Ready) {
        comp.createObject(root)
    } else if (comp.status === Component.Loading) {
        comp.statusChanged.connect(finishCreation)
    } else {
        console.error("Error:", comp.errorString())
    }
}

function finishCreation() {
    let comp = sender()   // not available directly — use a closure
    if (comp.status === Component.Ready)
        comp.createObject(root)
    else
        console.error(comp.errorString())
}
```

A cleaner pattern avoids the `statusChanged` dance entirely by always using
`asynchronous: true` on a `Loader`, which handles the status polling
internally. Reserve `Qt.createComponent()` for cases where you need a
`Component` reference independently of a `Loader`.

| `Component.status` value | Meaning |
|---|---|
| `Component.Null` | No source |
| `Component.Loading` | File fetch or compilation in progress |
| `Component.Ready` | Safe to call `createObject()` or `incubateObject()` |
| `Component.Error` | Failed; `errorString()` contains details |

---

### Non-Blocking Instantiation with `incubateObject()`

`Component.createObject()` is synchronous — it blocks the main thread until
the entire object tree is built. For components with very deep item hierarchies
or expensive `Component.onCompleted` handlers, this can still cause a frame
drop even when the *compilation* was asynchronous.

`incubateObject()` spreads instantiation across multiple event loop
iterations, yielding between frames:

```qml
Component {
    id: dashboardComp
    Dashboard { }
}

function loadDashboard() {
    let incubator = dashboardComp.incubateObject(root, { userId: session.userId })

    if (incubator.status === Component.Ready) {
        // Already done (cached, trivial component)
        onDashboardReady(incubator.object)
        return
    }

    incubator.onStatusChanged = function(status) {
        if (status === Component.Ready)
            onDashboardReady(incubator.object)
        else if (status === Component.Error)
            console.error(incubator.errorString())
    }
}

function onDashboardReady(dashboard) {
    // dashboard is fully instantiated
    mainStack.push(dashboard)
}
```

`incubateObject()` accepts the same arguments as `createObject()`. The
returned *incubator* object has `status`, `object` (the item, once ready),
and `onStatusChanged`. The incubator can also be given a custom completion
callback as a third argument:

```qml
dashboardComp.incubateObject(root, { userId: session.userId }, Component.Asynchronous)
```

The third argument sets the incubation mode:

| Mode | Behaviour |
|---|---|
| `Component.PreferSynchronous` | Synchronous if cached, async otherwise (default) |
| `Component.Asynchronous` | Always spread across event loop iterations |

---

### Patterns

#### Progressive Application Startup

Load the application shell immediately; defer feature areas until after the
first frame:

```qml
ApplicationWindow {
    id: root
    visible: true

    AppShell {
        id: shell
        anchors.fill: parent
    }

    // Load the heavy initial screen after the window is shown
    Loader {
        id: initialScreen
        anchors.fill: parent
        asynchronous: true

        // Defer until the window has painted its first frame
        Timer {
            id: startupTimer
            interval: 0   // fires after the current event loop iteration
            running: true
            onTriggered: initialScreen.source = "HomeScreen.qml"
        }
    }
}
```

An `interval: 0` timer fires as soon as the event loop is idle — after the
first frame has been rendered — giving the user an immediate window before any
heavy loading begins.

#### Lazy Tab Content

Pages in a `TabBar` + `StackLayout` arrangement are all instantiated at
startup by default. Replace each page with a `Loader`:

```qml
StackLayout {
    currentIndex: tabBar.currentIndex

    // Tab 0 — loaded immediately (default landing page)
    HomeScreen { }

    // Tab 1 — loaded only when first selected
    Loader {
        active: tabBar.currentIndex >= 1
        source: "AnalyticsScreen.qml"
        asynchronous: true
    }

    // Tab 2 — same pattern
    Loader {
        active: tabBar.currentIndex >= 2
        source: "SettingsScreen.qml"
        asynchronous: true
    }
}
```

Once loaded, pages remain in memory (because `active` stays `true` after first
activation). To aggressively reclaim memory, reset `active` to `false` when
the tab is no longer selected — at the cost of re-instantiation on re-visit.

#### Error Handling

Always handle the `Loader.Error` state in production code:

```qml
Loader {
    id: pageLoader
    source: currentPage.source
    asynchronous: true

    states: [
        State {
            name: "error"
            when: pageLoader.status === Loader.Error
            PropertyChanges { target: errorOverlay; visible: true }
        }
    ]
}

Rectangle {
    id: errorOverlay
    visible: false
    anchors.fill: parent
    color: "#cc000000"

    Column {
        anchors.centerIn: parent
        spacing: 12
        Text { text: "Failed to load page"; color: "white"; font.pixelSize: 18 }
        Button {
            text: "Retry"
            onClicked: {
                pageLoader.source = ""
                pageLoader.source = currentPage.source
            }
        }
    }
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

QML's language design is intentionally minimal on the declarative side and pragmatic on the JavaScript side. Its power lies in the binding engine, which makes reactive UI natural. The signal system gives clean inter-component communication without tight coupling. Deferred loading — through `Loader`, `incubateObject()`, and the component status lifecycle — is essential for keeping startup fast and memory proportional to what is actually on screen; `required property` declarations make the data contract between a caller and a loaded component explicit and enforced. JavaScript fills in the remaining gaps but should be kept thin — the more logic lives in QML JS, the harder the application is to test, profile, and maintain.
