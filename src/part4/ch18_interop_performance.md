# Chapter 18: C++/QML Interop Patterns and Performance

## Minimizing the C++/JS Boundary: Batch Updates and Coarse-Grained Signals

The C++/JavaScript boundary in Qt Quick is a significant performance boundary. Every property access from QML that crosses into C++ involves:

1. A `QMetaObject` lookup (name → property index)
2. A virtual call to the property's `READ` function
3. Type conversion from C++ type to `QVariant` to JS value
4. The reverse on property writes

For a single access this is negligible. In a tight loop, or for properties accessed in a delegate with thousands of items, it compounds.

### Measure Before Optimizing

Use Qt Creator's QML Profiler before making any change. The profiler shows:
- Time spent in QML binding evaluation
- Time spent in C++ property accessors
- Number of signal emissions and binding re-evaluations
- Per-frame breakdown of time in JavaScript vs. scene graph vs. rendering

Without profiler data, optimization is guesswork.

### Coarse-Grained Signal Strategy

Each signal emission triggers re-evaluation of all bindings that depend on the associated property. A model that emits `dataChanged` for individual cell changes on a 1,000-row table may trigger thousands of binding updates per second.

**Anti-pattern**:

```cpp
// Emitted for every incoming sensor reading — 1000/sec
void SensorModel::onNewReading(int sensorId, double value) {
    m_data[sensorId] = value;
    const QModelIndex idx = index(sensorId);
    emit dataChanged(idx, idx, {ValueRole});   // fires 1000 times/sec
}
```

**Better**: buffer updates and apply them on a timer:

```cpp
void SensorModel::onNewReading(int sensorId, double value) {
    m_pendingUpdates[sensorId] = value;   // just write to the buffer
}

void SensorModel::flushUpdates() {  // called by a 60Hz QTimer
    if (m_pendingUpdates.empty())
        return;

    int minRow = INT_MAX, maxRow = 0;
    QList<int> changedRoles = {ValueRole};

    for (auto [id, value] : m_pendingUpdates) {
        m_data[id] = value;
        minRow = std::min(minRow, id);
        maxRow = std::max(maxRow, id);
    }
    m_pendingUpdates.clear();

    // One dataChanged for the entire dirty range
    emit dataChanged(index(minRow), index(maxRow), changedRoles);
}
```

One `dataChanged` per frame instead of 1,000 — a dramatic reduction in binding evaluations.

### Batch Property Updates

When multiple properties change together conceptually, avoid emitting their notify signals individually if QML bindings read all of them together:

```cpp
// Instead of separate setters that each emit:
void DocumentViewModel::loadDocument(const Document &doc) {
    // Suppress individual notifications
    const QSignalBlocker blocker(this);
    setTitle(doc.title);
    setAuthor(doc.author);
    setPageCount(doc.pageCount);
    setWordCount(doc.wordCount);
    // Re-enable and emit one comprehensive signal
    emit documentLoaded();
}
```

In QML, connect to `documentLoaded` to refresh the entire view rather than four separate property bindings.

### Reduce Cross-Boundary Property Accesses

In JavaScript that runs frequently (e.g., inside a delegate's `Component.onCompleted` or a frequently-triggered signal handler), cache property reads in local variables:

```js
// Slow: C++ property read on each comparison
function isValidRange(start, end) {
    return end - start >= model.minimumRange &&
           end - start <= model.maximumRange
}

// Fast: read once, use multiple times
function isValidRange(start, end) {
    const min = model.minimumRange   // one C++ read
    const max = model.maximumRange   // one C++ read
    const range = end - start
    return range >= min && range <= max
}
```

### Large Lists: `roleNames` and Role Access Cost

In `ListView` delegates, each property access by role name involves a hash lookup in `roleNames()`. For large lists with many roles, use role integers directly via `model.display` (Qt::DisplayRole) or consolidate multiple fields into a single structured role:

```cpp
// Instead of 10 separate roles, return a structured object
case DataPacketRole:
    return QVariant::fromValue(m_items[index.row()]);  // entire struct as QVariant
```

In the delegate, access fields via the struct's properties rather than 10 separate model roles.

---

## Profiling with Qt Creator's QML Profiler and Scene Graph Debugger

### QML Profiler

The QML Profiler (accessible via **Analyze → QML Profiler** in Qt Creator) instruments the application at runtime and records:

- **Binding evaluations**: which bindings ran, how long they took, how often they ran
- **Signal emissions**: which signals fired and from where
- **JavaScript execution**: time spent in JS functions, handlers, and imported `.js` files
- **Component creation**: time to instantiate each component type
- **Rendering frames**: scene graph preparation and GPU submission times

Typical profiling workflow:

1. Start the application from Qt Creator's Analyze menu
2. Exercise the feature or interaction you want to profile
3. Click "Stop" in the profiler UI
4. Examine the timeline view for long bindings, excessive signal emission, or slow JS

Key findings to look for:
- Binding that re-evaluates more than once per frame → signal emitting too frequently
- `QObject::~QObject` calls during scrolling → delegates being destroyed instead of pooled
- Long JavaScript calls during animation → blocking the animation frame

### Scene Graph Debugger

Enable scene graph visualization with environment variables:

```bash
# Show overdraw (areas drawn multiple times per frame)
QSG_VISUALIZE=overdraw ./myapp

# Show batching (items grouped into single draw calls)
QSG_VISUALIZE=batches ./myapp

# Show clipping regions
QSG_VISUALIZE=clip ./myapp

# Show change tracking (which nodes updated each frame)
QSG_VISUALIZE=changes ./myapp
```

**Overdraw visualization**: Bright red areas are drawn many times per frame. Stack opacity at 100 layers all painting the same region. Common culprits: deeply nested transparent items, incorrectly placed opaque backgrounds, z-ordered items that are all visible simultaneously.

**Batch visualization**: Items in the same batch are rendered in a single GPU draw call. Green items are batched; red items are not. Unbatched items that could be batched indicate missed optimization opportunities — typically caused by:
- Non-uniform z-values among sibling items
- `clip: true` on intermediate items (creates new batch boundaries)
- Interleaved `layer.enabled` items
- Non-trivial custom materials in the same subtree

### Logging Scene Graph Activity

Enable scene graph logging for detailed diagnostics:

```bash
QT_LOGGING_RULES="qt.scenegraph.time.renderloop=true" ./myapp
```

Available categories:

| Category | Shows |
|---|---|
| `qt.scenegraph.time.renderloop` | Frame timing breakdown |
| `qt.scenegraph.time.texture` | Texture upload timing |
| `qt.scenegraph.time.compilation` | Shader compilation |
| `qt.qml.binding.removal` | Binding-breaking assignments |

### `QML_IMPORT_TRACE=1`

Trace QML import resolution to diagnose slow startup:

```bash
QML_IMPORT_TRACE=1 ./myapp 2>&1 | head -50
```

Shows each import statement and the paths searched, identifying modules that take long to find.

---

## Memory Ownership Contracts: `QQmlEngine::ObjectOwnership` and Avoiding Leaks

### The Two Ownership Modes

`QQmlEngine::ObjectOwnership` has two values:

**`CppOwnership`**: C++ code owns the object. The QML garbage collector will never delete it. The developer is responsible for ensuring the object outlives any QML references to it.

**`JavaScriptOwnership`**: The QML engine's garbage collector owns the object. It will be deleted when no more QML/JS references to it exist. This is the default for objects created by `QQmlComponent::create()` and `Qt.createQmlObject()`.

### Common Ownership Mistakes

**Mistake 1: C++ factory function returns an unparented object**

```cpp
// Bug: engine may GC this
Q_INVOKABLE QObject *createItem() {
    return new MyItem();   // no parent, no explicit ownership
}
```

QML receives the pointer, the engine assumes `JavaScriptOwnership`, and may GC the object if no QML variable holds a strong reference.

Fix:

```cpp
Q_INVOKABLE QObject *createItem() {
    auto *item = new MyItem(this);   // parent = this (C++ owns it)
    QQmlEngine::setObjectOwnership(item, QQmlEngine::CppOwnership);
    return item;
}
```

**Mistake 2: Storing a QML-owned object in a C++ data structure**

```cpp
void MyModel::registerItem(QObject *item) {
    m_items.push_back(item);  // C++ holds a raw pointer
    // If QML drops all references, item is GC'd
    // m_items now holds a dangling pointer
}
```

Fix: either parent the item to `this` (takes C++ ownership), or use `QPointer<QObject>` for nullable weak references, or explicitly set `CppOwnership`.

**Mistake 3: `QPointer` as a substitute for ownership**

```cpp
QPointer<QObject> m_weakRef = receivedItem;
// m_weakRef becoming null means the object was deleted — safe
if (m_weakRef)
    m_weakRef->doSomething();
```

`QPointer` is a weak reference — it becomes null when the object is deleted. Use it to *observe* an object's lifetime without owning it.

### Ownership in Practice: The Patterns

**Pattern A: Factory with C++ ownership**

```cpp
// Object lives as long as backend lives
Q_INVOKABLE SearchController *createSearch(const QString &query) {
    auto *ctrl = new SearchController(query, this);   // parent = this
    QQmlEngine::setObjectOwnership(ctrl, QQmlEngine::CppOwnership);
    return ctrl;
}
```

**Pattern B: QML-managed temporary objects**

For objects created in QML that are short-lived (dialogs, notifications):

```qml
Button {
    onClicked: {
        let dialog = dialogComponent.createObject(root, { message: "Confirm?" })
        dialog.accepted.connect(() => {
            doAction()
            dialog.destroy()   // explicit destruction
        })
        dialog.rejected.connect(() => dialog.destroy())
    }
}
```

`dialog.destroy()` schedules deletion at end of the current event loop iteration. This is correct — do not `delete` QML objects from C++.

**Pattern C: Model-managed child objects**

A list model that creates sub-objects parents them all:

```cpp
void ContactModel::loadContacts(const QList<ContactData> &data) {
    // Delete old children
    for (auto *child : findChildren<Contact*>())
        child->deleteLater();

    beginResetModel();
    m_contacts.clear();
    for (const auto &d : data) {
        auto *c = new Contact(d, this);   // parented to model
        QQmlEngine::setObjectOwnership(c, QQmlEngine::CppOwnership);
        m_contacts.push_back(c);
    }
    endResetModel();
}
```

The model owns all `Contact` objects. When the model is deleted, all contacts are deleted via Qt's parent-child mechanism.

---

## Avoiding Binding Loop Warnings

Binding loops occur when property A's binding reads property B, and property B's binding reads property A, creating a cycle:

```qml
// Binding loop!
Rectangle {
    width: height * 2
    height: width / 2   // depends on width, which depends on height...
}
```

Qt detects these and emits a runtime warning, then breaks the loop by returning the property's last stable value.

To avoid loops:
- Use `id`-qualified access: `root.width` instead of `width` in a child that also affects `root.width`
- Use intermediate properties to break cycles
- For two-way synchronization between C++ and QML (e.g., a slider and a text input both setting the same value), guard against re-entrant updates with a flag

```qml
// Safe two-way sync
Slider {
    value: model.value   // binding from model to slider
    onMoved: model.value = value   // only fires on user interaction, not binding updates
}
```

`onMoved` (vs. `onValueChanged`) fires only when the user moves the slider, not when `value` is set programmatically — preventing the loop.

---

## Summary

Performance at the C++/QML boundary is dominated by signal emission frequency, cross-boundary property access patterns, and scene graph batching. Batch updates with timers or `QSignalBlocker` to reduce signal chatter. Cache C++ property reads in local JS variables in hot paths. The QML Profiler is indispensable for identifying the actual bottlenecks before optimizing. Memory ownership is the most error-prone interop aspect: always set `QQmlEngine::CppOwnership` on objects returned from C++ factories, and use `QPointer` for weak C++ references to QML-owned objects. Binding loops are a correctness concern, not a performance concern — but the fixes (explicit `id` qualification, `onMoved` vs. `onValueChanged`) are worth internalizing.
