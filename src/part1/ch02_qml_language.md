# Chapter 2: QML Language Deep Dive

## QML Elements and the Object Hierarchy

### The Object Hierarchy: A Structured Approach to UI

QML applications are built around an **object hierarchy** — a tree of elements nested within one another, forming a parent-child structure. This hierarchy is both:

- **Visual**: it defines what you see on screen — how elements are positioned relative to one another and which elements contain which others.
- **Logical**: it defines the ownership and lifetime of objects — when a parent is destroyed, its children are automatically destroyed; when you interact with an element, you navigate up or down the tree to access related elements.

At the top of the hierarchy is typically an `ApplicationWindow` or a `Window`. Nested inside are containers (like `Column`, `Row`, `Rectangle`) and interactive elements (like `Button`, `TextField`, `Text`). Each nested level corresponds to one level of the QML file's indentation, making the hierarchy immediately visible in the source code.

This structural approach is one of QML's core strengths: the UI's organization is explicit and easy to reason about. Properties and signals flow through this hierarchy, and the hierarchy itself determines visual stacking order, input delivery, and resource cleanup.

### What is a QML Element?

A QML element is an object instantiated from a type and described declaratively. Elements are the building blocks of every Qt Quick application — they are concrete: when you write `Rectangle { color: "red" }`, you are creating a `Rectangle` element that actually exists at runtime.

Elements form a tree: a parent element can contain child elements, and children are positioned relative to their parent's coordinate system. When a parent is destroyed, its children are automatically destroyed too. This ownership model eliminates manual memory management.

```qml
ApplicationWindow {
    visible: true
    width: 400; height: 300

    Column {
        anchors.fill: parent
        spacing: 10

        Text {
            text: "Hello, QML"
        }

        Rectangle {
            width: 100; height: 50
            color: "steelblue"
        }
    }
}
```

Here, `ApplicationWindow` contains a `Column`, which contains a `Text` and a `Rectangle`. When the window is destroyed, so are all its descendants.

### `Item`: The Root of the Visual Hierarchy

Every visual element in Qt Quick — `Rectangle`, `Text`, `Image`, `Button`, and so on — is either `Item` itself or a subclass of it. `Item` is invisible: it renders nothing. Its role is to:

- **Define a rectangular region** with position (`x`, `y`) and size (`width`, `height`)
- **Provide a coordinate origin** for child elements
- **Carry common visual properties**: `visible`, `opacity`, `z`, `enabled`, `clip`, `scale`, `rotation`
- **Be a container** — any element can have children

```qml
Item {
    width: 200; height: 200

    // This Rectangle is positioned at (10, 10) in Item's coordinate space
    Rectangle {
        x: 10; y: 10
        width: 50; height: 50
        color: "red"
    }
}
```

When you need a container that does not draw anything and simply holds other elements, use `Item`. Chapter 3 covers geometry, anchoring, and the coordinate system in depth.

#### Item's Properties

`Item` provides a rich set of properties that all visual elements inherit:

##### Geometry and Positioning

| Property | Type | Purpose |
| --- | --- | --- |
| `x`, `y` | `real` | Position relative to the parent's top-left corner (in logical pixels) |
| `width`, `height` | `real` | Item dimensions (in logical pixels) |
| `implicitWidth`, `implicitHeight` | `real` | Suggested size based on the item's content (often set by layout systems) |
| `anchors` | `Anchors` | Declarative positioning constraints relative to sibling or parent edges |
| `transform` | `list<Transform>` | Custom 2D/3D transformations (rotation, scale, matrix) |

##### Visual Appearance

| Property | Type | Purpose |
| --- | --- | --- |
| `visible` | `bool` | If `false`, the item and all children are hidden (but still exist and consume memory) |
| `opacity` | `real` | Transparency: `0.0` (fully transparent) to `1.0` (fully opaque); inherited by children |
| `z` | `real` | Stacking order among siblings; higher `z` appears on top |
| `scale` | `real` | Multiplier for item size; `1.0` is normal, `2.0` is twice as large |
| `rotation` | `real` | Rotation in degrees (clockwise); pivot is the item's center |
| `clip` | `bool` | If `true`, children and content outside the item's boundaries are not rendered |

##### Interaction and State

| Property | Type | Purpose |
| --- | --- | --- |
| `enabled` | `bool` | If `false`, the item does not receive input events (mouse, keyboard, touch); usually rendered with reduced opacity by controls |
| `focus` | `bool` | If `true`, the item has keyboard focus and receives key events; only one item in the window has focus at a time |
| `activeFocus` | `bool` | Read-only; `true` if this item has focus and is currently active (in focus chain) |
| `hoverEnabled` | `bool` | Enables the `HoverHandler` behavior; if `true`, the item can track mouse hover (MouseArea property only) |

##### Hierarchy and Structure

| Property | Type | Purpose |
| --- | --- | --- |
| `parent` | `Item` | The containing item, or `null` if this is a root item |
| `children` | `list<Item>` | Array of direct child items |
| `childrenRect` | `Rect` | Bounding rectangle of all children (useful for auto-sizing containers) |

##### Signals Provided by Item

`Item` also emits several signals:

| Signal | Purpose |
| --- | --- |
| `parentChanged()` | Emitted when the parent is reassigned |
| `childrenChanged()` | Emitted when children are added or removed |
| `visibleChanged()` | Emitted when `visible` is toggled |
| `focusChanged()` | Emitted when `focus` is gained or lost |
| `activeFocusChanged()` | Emitted when `activeFocus` changes |

Example: responding to visibility changes:

```qml
Item {
    onVisibleChanged: {
        if (visible) {
            console.log("Item became visible")
        } else {
            console.log("Item became hidden")
        }
    }
}
```

Most of these properties have corresponding *change signals* — for instance, `opacityChanged()` is emitted when `opacity` is modified — allowing you to react to property changes via signal handlers or bindings.

### Core Built-in Elements

Qt Quick provides a set of built-in visual elements — all inheriting from `Item` — for common UI tasks:

| Element | Module | Purpose |
| --- | --- | --- |
| `Rectangle` | `QtQuick` | Filled and/or bordered box with optional rounded corners |
| `Text` | `QtQuick` | Renders text using the system font engine |
| `Image` | `QtQuick` | Loads and displays raster (PNG, JPEG) or vector (SVG) images |
| `MouseArea` | `QtQuick` | Input region for mouse clicks, hover, and drag events |
| `Flickable` | `QtQuick` | Scrollable container with flick/momentum scrolling |
| `ListView` | `QtQuick` | Efficient list display, data-driven from a model |
| `GridView` | `QtQuick` | Grid layout, data-driven |
| `Repeater` | `QtQuick` | Creates multiple instances of a delegate for each model item |
| `Loader` | `QtQuick` | Defers loading and instantiation of a child component |
| `ApplicationWindow` | `QtQuick.Controls` | Top-level window with menu bar, tool bar, and status bar slots |
| `Button`, `TextField`, `CheckBox`, `Slider`, … | `QtQuick.Controls` | Styled interactive controls with platform conventions |

These form the vocabulary of UI construction. Each element has properties you can bind to, signals you can connect to, and behavior you can configure.

### Non-Visual Elements

Not all QML types are visual elements that inherit from `Item`. Qt Quick also provides utility and infrastructure objects that do not appear on screen but support the UI:

| Element | Module | Purpose |
| --- | --- | --- |
| `Component` | `QtQuick` | Wraps a subtree without instantiating it; acts as a reusable template |
| `Timer` | `QtQuick` | Fires a signal at regular intervals; useful for animations and periodic tasks |
| `Connections` | `QtQuick` | Connects to signals from other objects, often used when the target is not the parent |
| `QtObject` | `QtQml` | Base QObject without visual properties; useful for defining property-only containers |
| `Binding` | `QtQml` | Creates an explicit binding relationship; useful for restoring bindings programmatically |

These objects are instantiated like any other element and can own children or emit signals, but they do not participate in the visual tree and have no geometry, visibility, or rendering.

### `Component`: Defining Without Instantiating

`Component` wraps a QML subtree without creating it immediately. It acts as a reusable template:

```qml
Component {
    id: delegateTemplate
    Rectangle {
        width: 100; height: 30
        color: "lightgray"
        Text {
            anchors.centerIn: parent
            text: modelData
        }
    }
}

// Later: instantiate the component
Loader {
    sourceComponent: delegateTemplate
}

ListView {
    delegate: delegateTemplate
}
```

The component is not instantiated when the `Component` is created — only when you ask for it via `Loader`, `ListView.delegate`, `Repeater`, or by calling `createObject()` on the component reference. This allows deferred loading and reuse of the same template.

#### Best Practices: `.qml` Files vs. Inline `Component`

**Use inline `Component` (inside a `.qml` file) for one-off templates:**

- `ListView` delegates, `GridView` delegates, `Repeater` children
- Templates you only use in one place
- When you need to defer instantiation of a subtree

**Use `.qml` files for reusable custom types:**

The `.qml` file itself **is a component** — you don't need to wrap it in `Component`. When you create `MyButton.qml`, the file IS the template:

```qml
// MyButton.qml (correct)
Rectangle {
    property string label: "Click me"
    signal clicked()
    // ...
}

// Caller — instantiate directly
MyButton {
    label: "Greet"
    onClicked: doSomething()
}
```

**Don't make the root of a `.qml` file a `Component`:**

```qml
// MyButton.qml (incorrect — don't do this)
Component {
    Rectangle {
        property string label: "Click me"
        // ...
    }
}
```

This forces callers to write awkward code and defeats the purpose of `.qml` files as reusable types. The file itself is already the template.

**Summary:** Use `.qml` files for anything you want to reuse in multiple places or as a named type. Use inline `Component` for templates you define and use within a single file.

### Inheritance and Type Extension

Every `.qml` file you create defines a new QML type. The type's name is the filename (minus `.qml`). The type extends whatever element appears at the root of the file.

```qml
// MyButton.qml
Rectangle {
    id: root
    width: 100
    height: 40
    color: "steelblue"
    radius: 6

    property string label: "Click me"
    signal clicked()

    Text {
        anchors.centerIn: parent
        text: root.label
        color: "white"
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.clicked()
    }
}
```

Now `MyButton` is a reusable type that extends `Rectangle`. Callers can use it like any built-in element:

```qml
// MainWindow.qml
ApplicationWindow {
    MyButton {
        x: 20; y: 20
        label: "Greet"
        onClicked: console.log("Greeted!")
    }
}
```

The caller can set properties inherited from `Rectangle` (`x`, `y`, `width`, `height`, `color`, `radius`) as well as properties you added (`label`). They can also connect to signals you declared (`clicked`).

Each `.qml` file has its own **scope**: the `id` `root` inside `MyButton.qml` refers only to the root `Rectangle` in that file. If the caller has a separate `id root` in `MainWindow.qml`, they are entirely separate — no naming conflicts.

### The Element Tree at Runtime

At any time, an element has:

- **`parent`**: a reference to its containing element, or `null` if it has no parent
- **`children`**: an array of all direct child elements
- **`width`, `height`**: the element's size in logical pixels

When you add a child element to an element, the parent takes ownership. When the parent is deleted (destroyed), all its children are deleted too. This automatic cleanup prevents memory leaks and makes reasoning about lifetime straightforward.

The element tree is also the **visual tree**: rendering walks this tree from root to leaves, drawing each element (or delegating to a scene graph node) in order.

---

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

#### Modifiers: `readonly` and `required`

**`readonly` properties** are read-only from outside — they can only be assigned within the component that declares them:

```qml
Item {
    readonly property int itemCount: model.length
    readonly property bool isValid: title.length > 0 && age >= 0
    
    // These can be reassigned inside handlers / onCompleted
    Component.onCompleted: {
        // If itemCount were not readonly, this is where you'd re-assign it
        console.log("Count:", itemCount)
    }
}
```

Use `readonly` when:

- A property is **computed** (derived from other properties) and should not be reassigned from outside.
- You want to **prevent accidental mutation** from parent components or external code.
- A property's value is **managed internally** but should be readable to others (e.g., `isLoading`, `currentIndex`).

The binding on a `readonly` property is active and will update as its dependencies change — the only restriction is that external code cannot assign a new value.

**`required` properties** are the inverse: they **must be supplied** by the caller before the component can be used. The component will not instantiate without them:

```qml
// ProfileCard.qml
Item {
    required property string userId
    required property string displayName
    required property color highlightColor
    
    Text {
        text: displayName
        color: highlightColor
    }
}
```

```qml
// Caller — using a Loader
Loader {
    source: "ProfileCard.qml"
    onLoaded: {
        item.userId = currentUser.id
        item.displayName = currentUser.name
        item.highlightColor: "#6c3aec"
    }
}

// Or using setSource() to supply them at load time:
profileLoader.setSource("ProfileCard.qml", {
    userId: currentUser.id,
    displayName: currentUser.name,
    highlightColor: "#6c3aec"
})
```

If a `required property` is not supplied, the engine emits a compile-time or runtime error — making the missing dependency explicit rather than silently using a default value.

Use `required` when:

- A component **cannot function** without certain data from its caller.
- You want to **enforce a contract**: the caller must think about what to pass in.
- You are building a **reusable component** that will be used in multiple contexts.

#### Common Pattern: `required readonly`

In components meant to display read-only data, combine both modifiers:

```qml
// ContactCard.qml
Item {
    required property var contact  // must be supplied
    readonly property string displayName: contact.firstName + " " + contact.lastName
    readonly property url avatarUrl: "file:///avatars/" + contact.id + ".png"
}
```

The caller supplies `contact`; the component derives read-only display properties from it.

#### When to Use Each

| Situation | Choose |
| --- | --- |
| Component is a generic utility (button, label, input field) | No modifiers — normal mutable properties |
| Component displays data that should not be changed from outside | `readonly` for the computed properties |
| Component needs mandatory input to work (profile card, detail view) | `required` for those inputs |
| Data should be supplied once and not changed | `required` + `readonly` |
| Property is optional with a sensible default | Normal `property` with a default value |
| Internal state you track but want to expose read-only | `readonly` binding to internal state |

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
