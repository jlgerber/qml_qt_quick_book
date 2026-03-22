# Chapter 10: Exposing Python Objects to QML

## Registering Types: `qmlRegisterType` vs. the Decorator Approach

There are two API generations for registering Python types with the QML engine: the classic `qmlRegisterType` family of functions (ported from C++) and the modern decorator-based approach introduced in PySide6 6.3. Both are supported, but new code should use decorators.

### Classic Registration with `qmlRegisterType`

```python
from PySide6.QtQml import qmlRegisterType, qmlRegisterSingletonType

# Register a creatable type
qmlRegisterType(Counter, "com.example.backend", 1, 0, "Counter")

# Register a singleton
def create_settings(engine):
    return AppSettings(engine)

qmlRegisterSingletonType(AppSettings, "com.example.backend", 1, 0,
                         "AppSettings", create_settings)
```

The `qmlRegisterType` family requires explicit URI, major version, minor version, and QML type name. This separates registration from the class definition and can lead to registration calls scattered across the codebase.

### Decorator-Based Registration

```python
QML_IMPORT_NAME = "com.example.backend"
QML_IMPORT_MAJOR_VERSION = 1

@QmlElement
class Counter(QObject):
    ...
```

The module-level `QML_IMPORT_NAME` and `QML_IMPORT_MAJOR_VERSION` variables define the namespace. All `@QmlElement`-decorated classes in the module are registered under this URI. This is DRY, co-located with the class definition, and plays well with tooling like `qmlsc`.

### Choosing an Approach

Use decorators for all new code. Use `qmlRegisterType` only when:
- Integrating with older codebases that already use it
- The URI or version needs to differ per registration (unusual)
- The type is defined in a third-party library you cannot modify

---

## `Property`, `Signal`, and `Slot` with Proper Type Annotations

### `Signal`

PySide6 signals are class-level descriptors. They must be declared at the class level, not in `__init__`. Each signal instance carries its parameter type signature:

```python
from PySide6.QtCore import Signal

class DocumentModel(QObject):
    # Signals with typed parameters
    titleChanged = Signal(str)
    pageCountChanged = Signal(int)
    contentChanged = Signal()          # no parameters
    errorOccurred = Signal(str, int)   # message, error code

    # Overloaded signal (multiple signatures)
    dataReady = Signal([str], [bytes])
```

**Emit a signal**: call it like a function:

```python
self.titleChanged.emit("New Title")
self.errorOccurred.emit("File not found", 404)
```

**Signal with `name` override** (for signals whose Python-reserved name would conflict):

```python
destroyed_ = Signal(name="destroyed")  # avoid shadowing QObject.destroyed
```

### `Property`

`Property` creates a Qt property — a named value with a getter, optional setter, and optional notifier signal. QML binding expressions that read a property automatically subscribe to its `notify` signal:

```python
from PySide6.QtCore import Property, Signal

class UserProfile(QObject):
    nameChanged = Signal()
    ageChanged = Signal(int)

    def __init__(self, parent=None):
        super().__init__(parent)
        self._name = ""
        self._age = 0

    # Read-only property (no setter)
    @Property(str, notify=nameChanged)
    def name(self):
        return self._name

    @name.setter
    def name(self, value: str):
        if self._name != value:
            self._name = value
            self.nameChanged.emit()

    # Read-write property with typed notify signal
    @Property(int, notify=ageChanged)
    def age(self):
        return self._age

    @age.setter
    def age(self, value: int):
        if self._age != value:
            self._age = value
            self.ageChanged.emit(value)

    # Constant property (never changes — no notify needed)
    @Property(str, constant=True)
    def userId(self):
        return self._user_id
```

**Property types** map to QML types:

| Python type annotation | QML type |
|---|---|
| `str` | `string` |
| `int` | `int` |
| `float` | `real` |
| `bool` | `bool` |
| `list` | `var` |
| `QObject` subclass | object type |
| `QUrl` | `url` |
| `QColor` | `color` |

**The equality check before emitting** is important. Without it, a setter that assigns the same value still emits the notify signal, causing unnecessary binding re-evaluation throughout QML.

### `Slot`

`@Slot` marks a method as a Qt slot — callable from QML, connectable to signals, and visible to the meta-object system:

```python
from PySide6.QtCore import Slot

class FileManager(QObject):

    @Slot()
    def openFile(self):
        ...

    @Slot(str)
    def openFilePath(self, path: str):
        ...

    @Slot(str, result=bool)
    def fileExists(self, path: str) -> bool:
        return Path(path).exists()

    @Slot(int, int, result=float)
    def divide(self, a: int, b: int) -> float:
        return a / b if b != 0 else 0.0
```

The `result` keyword specifies the return type. Without `result`, the method returns nothing to QML (even if it returns a Python value). With `result`, QML can use the return value in expressions:

```qml
Button {
    onClicked: {
        if (fileManager.fileExists(pathField.text)) {
            fileManager.openFilePath(pathField.text)
        }
    }
}
```

**Slots without `@Slot`**: Python methods on `QObject` subclasses are still callable from QML through the meta-object dynamic invocation path, but they lack type information and may behave differently with overloads. Always use `@Slot` for methods intended for QML consumption.

### Overloaded Slots

Use multiple `@Slot` decorators (stacked) for overloaded methods:

```python
@Slot(str)
@Slot(str, int)
def search(self, query: str, maxResults: int = 20):
    ...
```

---

## Context Properties vs. Registered Singletons: Trade-offs and Best Practices

There are three primary ways to make a Python object available in QML:

1. **Context properties** (`QQmlContext.setContextProperty`)
2. **Registered singletons** (`@QmlElement` + `@QmlSingleton`)
3. **Constructor injection** (passing objects as initial property values)

### Context Properties

```python
engine = QQmlApplicationEngine()
settings = AppSettings()
engine.rootContext().setContextProperty("appSettings", settings)
engine.load("Main.qml")
```

In QML, `appSettings` is available as a global name (no import needed):

```qml
Text { text: appSettings.theme }
```

**Pros**: Simple to set up; works with any `QObject` instance; no registration required.

**Cons**:
- Global namespace pollution — every context property is a global name in every QML file
- No IDE autocompletion or type checking (the name is a string, the type unknown to tooling)
- Breaks `qmlsc` ahead-of-time compilation (context properties are dynamic)
- `setContextProperty` must be called before `load()` — ordering dependency

Context properties are appropriate for rapid prototyping. Avoid them in production code.

### Registered Singletons

```python
@QmlElement
@QmlSingleton
class AppSettings(QObject):
    ...
```

In QML (with an explicit import):

```qml
import com.example.backend

Text { text: AppSettings.theme }
```

**Pros**:
- Explicit import makes dependencies visible
- Full IDE support: type-aware autocompletion
- Compatible with `qmlsc`
- Singleton instance is lazily created by the engine on first use
- Accessible from any QML file that imports the module

**Cons**:
- Requires the module to be imported in every file that uses it
- The singleton instance must not require constructor arguments (the engine creates it)

Singletons are the recommended pattern for application-wide services: settings, authentication state, theme, feature flags.

### Constructor Injection

Pass objects as initial property values when loading the root component:

```python
engine.setInitialProperties({
    "documentModel": document_model,
    "userSession": session
})
engine.loadFromModule("MyApp", "Main")
```

In QML:

```qml
// Main.qml
ApplicationWindow {
    required property DocumentModel documentModel
    required property UserSession userSession
}
```

**Pros**:
- Explicit dependencies — the root component declares what it needs via `required property`
- Testable: different instances can be injected for testing
- No global state

**Cons**:
- Only works for the root component (children must receive values via property propagation)
- Slightly more boilerplate

Constructor injection is the cleanest pattern for the root object. Combine with singletons for truly global services.

### Propagating Objects Down the Tree

Once an object is available in the root component, pass it down via explicit property bindings:

```qml
// Main.qml
ApplicationWindow {
    required property DocumentModel documentModel

    StackView {
        initialItem: EditorScreen {
            model: documentModel   // passed down explicitly
        }
    }
}
```

Avoid reaching up the hierarchy with `parent.parent.model` — this creates invisible coupling. Explicit property passing makes the data flow visible and refactorable.

---

## Practical Patterns

### Two-Way Property Binding

When QML and Python both modify a property, implement change guards in both directions:

```python
class SyncedValue(QObject):
    valueChanged = Signal(float)

    def __init__(self):
        super().__init__()
        self._value = 0.0
        self._updating = False

    @Property(float, notify=valueChanged)
    def value(self):
        return self._value

    @value.setter
    def value(self, v):
        if abs(self._value - v) > 1e-9 and not self._updating:
            self._updating = True
            self._value = v
            self.valueChanged.emit(v)
            self._updating = False
```

### Returning Complex Objects from Slots

When a slot needs to return a complex object:

```python
@Slot(str, result=QObject)
def findUser(self, userId: str) -> Optional[UserProfile]:
    user = self._db.get_user(userId)
    if user is None:
        return None
    profile = UserProfile(user, parent=self)  # parent self to avoid GC
    return profile
```

The `parent=self` ensures the returned object lives at least as long as the backend object. QML's GC will not collect it prematurely.

### Invoking QML from Python

Occasionally Python needs to call back into QML logic. Use `QMetaObject.invokeMethod` for cross-thread safety:

```python
from PySide6.QtCore import QMetaObject, Qt

# Call a slot on the root QML object
QMetaObject.invokeMethod(
    engine.rootObjects()[0],
    "showNotification",
    Qt.QueuedConnection,
    Q_ARG(str, "Upload complete")
)
```

For simpler cases where you are already on the main thread, call methods directly on the root object:

```python
root = engine.rootObjects()[0]
root.showNotification("Upload complete")
```

---

## Summary

Exposing Python objects to QML requires understanding the interplay between Qt's meta-object system and PySide6's binding layer. `Property`, `Signal`, and `Slot` provide the vocabulary; equality guards in setters prevent notification storms; and `result` types in slots enable QML to use return values. For making objects available in QML, prefer registered singletons for global services and constructor injection for root component dependencies — avoiding context properties in production code. Explicit property propagation down the component tree keeps data flow visible and testable.
