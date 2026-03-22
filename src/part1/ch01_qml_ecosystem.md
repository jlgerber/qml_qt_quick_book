# Chapter 1: The QML Ecosystem: Architecture and Design Philosophy

## The Declarative Paradigm vs. Imperative UI

Qt Quick applications are built around a declarative model: you describe *what* the UI looks like in a given state, not *how* to get there. This is a significant departure from traditional widget-based toolkits where the developer drives widget construction, layout recalculation, and repaint calls explicitly.

In a widget-based system, a developer might write:

```cpp
// Imperative: tell the system every step
QLabel *label = new QLabel(parent);
label->setText("Hello");
label->setGeometry(10, 10, 200, 30);
label->setVisible(true);
```

In QML, the same thought is expressed as a self-contained description:

```qml
Text {
    x: 10; y: 10
    width: 200; height: 30
    text: "Hello"
}
```

The difference becomes profound when state changes. In the imperative model, the developer writes transition code explicitly — detecting the state change and issuing updates. In QML, *bindings* propagate changes automatically through the dependency graph. When a property that another property depends on changes, the engine re-evaluates and updates all downstream bindings without explicit wiring.

This reactive model is the foundation of everything Qt Quick does. Understanding it early prevents a common mistake: fighting the binding engine by manually assigning property values in JavaScript when a binding would serve better.

### When Declarative Breaks Down

Declarative UI excels at describing structure and steady-state appearance. It is less natural for expressing sequences of imperative operations: network calls, file I/O, complex algorithmic transformations. QML accommodates these through JavaScript handlers and by delegating to backend objects written in Python or C++. A well-architected Qt Quick application keeps QML as the pure presentation layer and pushes logic into the backend.

---

## Qt's Rendering Pipeline: Scene Graph and Graphics Backends

Qt Quick's rendering model is fundamentally different from Qt Widgets. Widgets use the QPainter abstraction, which ultimately issues 2D paint commands to a raster or platform surface. Qt Quick uses a *retained scene graph* — a tree of nodes that represents the visual output — rendered on a dedicated render thread using a GPU-accelerated backend.

### The Scene Graph

When QML items are instantiated, the Qt Quick runtime builds a scene graph: a tree of `QSGNode` subclasses that carry geometry, materials, transforms, and clipping information. This graph is traversed each frame to produce GPU draw calls.

Key node types:

| Node type | Purpose |
|---|---|
| `QSGGeometryNode` | Carries vertex data and a material, represents drawable geometry |
| `QSGTransformNode` | Applies a matrix transform to its subtree |
| `QSGClipNode` | Clips its subtree to a stencil region |
| `QSGOpacityNode` | Applies opacity to its subtree |
| `QSGRootNode` | The root of the graph, owned by the `QQuickWindow` |

The scene graph is not synchronized with the main thread on every property change. Instead, Qt Quick batches changes and synchronizes the scene graph with the UI state at the beginning of each frame, during the *sync phase*. This is why Qt Quick can maintain smooth rendering even when the main thread is busy.

### The Render Thread

By default, Qt Quick renders on a dedicated render thread, keeping rendering decoupled from main-thread activity. The pipeline per frame is:

1. **Main thread**: Advance animations, evaluate bindings, run JavaScript
2. **Sync phase** (main thread blocked briefly): Copy UI state into scene graph nodes
3. **Render thread**: Traverse the scene graph, issue GPU commands
4. **Swap**: Present the rendered frame

This threading model means you must never touch scene graph nodes from the main thread outside the sync phase. Custom `QQuickItem` subclasses in C++ implement `updatePaintNode()` to safely write scene graph data during the sync phase.

### Graphics Backends

Qt 6 supports multiple graphics backends through the *Qt Rendering Hardware Interface (RHI)*:

| Backend | Platforms |
|---|---|
| Vulkan | Linux, Android, Windows |
| Metal | macOS, iOS |
| Direct3D 11/12 | Windows |
| OpenGL / OpenGL ES | All platforms (compatibility) |
| Software rasterizer | Fallback, no GPU required |

RHI abstracts the differences between these APIs so that most Qt Quick code is backend-agnostic. You can select the backend at runtime via the `QSG_RHI_BACKEND` environment variable or programmatically via `QQuickWindow::setGraphicsApi()`. This is relevant when integrating external rendering code or when targeting platforms with constrained GPU support.

---

## QML Engine Internals, the JS Runtime, and Object Lifecycle

### The QML Engine

The `QQmlEngine` is the root of all QML activity. It owns:

- The **type registry**: the mapping of QML type names to C++ or QML-defined types
- The **import system**: resolution of `import` statements to directories or plugins
- The **JavaScript engine**: a V4 engine (SpiderMonkey-derived) embedded in Qt
- The **component cache**: parsed and compiled QML components for reuse
- The **network access manager**: used for remote QML and image loading

An application typically has one engine. Multiple engines are possible but they share nothing — types registered in one are not visible in another, and objects created by one cannot be parented to objects in another.

```cpp
// C++ main.cpp
QQmlApplicationEngine engine;
engine.loadFromModule("MyApp", "Main");
```

```python
# Python main.py
from PySide6.QtQml import QQmlApplicationEngine
engine = QQmlApplicationEngine()
engine.loadFromModule("MyApp", "Main")
```

### Components and Instantiation

A QML *component* is a compiled description of an object tree. Every `.qml` file defines a component. Components are instantiated to produce object trees. The `Component` type in QML gives you explicit control over this:

```qml
Component {
    id: dialogComponent
    MyDialog { }
}

// Instantiate on demand
onClicked: {
    let obj = dialogComponent.createObject(root, { title: "Alert" })
}
```

`createObject()` creates a new instance with the given parent and initial property values. This is the primary mechanism for dynamic UI creation.

### Object Ownership and Memory

QML objects participate in two ownership systems that interact in non-obvious ways:

**QML engine ownership**: Objects created by the QML engine — via component instantiation, `createObject()`, or `Qt.createQmlObject()` — are owned by the engine's garbage collector. When the last reference (in QML or JS) to an object is dropped, the GC is free to collect it.

**C++ / Qt ownership**: Objects that have a QObject parent are kept alive by their parent. When the parent is destroyed, all children are destroyed with it. If you pass a C++ object to QML and that object is parented, the parent's lifetime governs it.

**The conflict**: If a C++ object with no parent is returned to QML, the engine may take ownership and destroy it. To prevent this, either parent the object to a long-lived C++ owner, or set `QQmlEngine::setObjectOwnership(obj, QQmlEngine::CppOwnership)` explicitly.

A common mistake:

```cpp
// Bug: engine may garbage-collect this
QObject* MyBackend::createThing() {
    return new Thing(); // No parent, no explicit ownership set
}
```

Fix:

```cpp
QObject* MyBackend::createThing() {
    Thing *t = new Thing(this); // Parented — C++ owns it
    return t;
}
```

### The V4 JavaScript Engine

QML's JavaScript runtime is V4, a JIT-compiling engine embedded in Qt. It executes JavaScript written in QML signal handlers, property binding expressions, and `.js` files imported by QML.

V4 integrates with the QObject meta-object system through an automatic bridge: accessing a QObject property from JS triggers the meta-object `read()` accessor; assigning triggers `write()`; connecting a signal passes through the meta-object signal machinery.

This bridge has a cost. Each property access from JS that crosses the C++/JS boundary involves a lookup and type conversion. Tight inner loops in JS that repeatedly access C++ properties are a known performance hazard. The mitigation is to cache values in local JS variables:

```js
// Slow: meta-object lookup on each iteration
for (let i = 0; i < model.count; i++) { ... }

// Faster: cache the value
const count = model.count
for (let i = 0; i < count; i++) { ... }
```

For the most performance-critical logic, move the computation to C++ and expose only the result to QML.

---

## Summary

Qt Quick's architecture is purpose-built for GPU-accelerated, reactive UI at scale. The key ideas to carry forward:

- The binding engine propagates state automatically; work *with* it rather than around it.
- The scene graph decouples rendering from main-thread activity, enabling smooth frame rates.
- RHI makes Qt Quick portable across Vulkan, Metal, Direct3D, and OpenGL without backend-specific code.
- The QML engine owns the JS runtime and object lifecycle; understand ownership rules before mixing C++/Python and QML objects.

These foundations underpin every other concept in the book.
