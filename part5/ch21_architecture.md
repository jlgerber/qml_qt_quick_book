# Chapter 21: Architecture Patterns for Large Applications

## MVVM in QML: Practical Boundaries Between Model, ViewModel, and View

Model-View-ViewModel (MVVM) maps cleanly onto Qt Quick's architecture because QML's binding engine naturally implements the ViewModel-to-View data flow that MVVM prescribes. The discipline is maintaining clean boundaries as the application grows.

### Layer Responsibilities

**Model** (no Qt dependency, pure data and business logic):
- Domain entities as plain Python dataclasses or C++ structs
- Repository interfaces for data access (database, network, file system)
- Business rules and validation
- Independently unit-testable

**ViewModel** (Qt-aware, no visual opinion):
- `QObject` subclasses with `Q_PROPERTY` / `@Property` exposing view-ready data
- `QAbstractItemModel` subclasses for collections
- Transforms raw model data into display-ready form
- Exposes commands (`Q_INVOKABLE` / `@Slot`) for user actions
- Manages async operations (loading states, error states)
- Independently testable with `QTest` / `QSignalSpy`

**View** (QML only, no business logic):
- Binds to ViewModel properties
- Delegates user input to ViewModel commands
- Handles navigation, animation, and visual feedback
- Tested with `TestCase` / Squish

### ViewModel Design Principles

**1. Expose view-ready data, not raw domain data**

```python
# Bad: expose raw datetime — QML must format it
@Property(str, notify=timestampChanged)
def timestamp(self):
    return self._event.timestamp.isoformat()

# Good: expose formatted string — view just displays it
@Property(str, notify=timestampChanged)
def formattedTimestamp(self):
    return self._event.timestamp.strftime("%B %d, %Y at %I:%M %p")
```

**2. Expose loading, empty, and error states explicitly**

```python
class ContactListViewModel(QObject):
    loadingChanged = Signal()
    errorChanged = Signal()
    emptyChanged = Signal()

    @Property(bool, notify=loadingChanged)
    def loading(self): return self._loading

    @Property(str, notify=errorChanged)
    def errorMessage(self): return self._error

    @Property(bool, notify=emptyChanged)
    def isEmpty(self): return len(self._contacts) == 0
```

In QML, these states drive which content to show:

```qml
StackLayout {
    currentIndex: {
        if (vm.loading) return 0
        if (vm.errorMessage) return 1
        if (vm.isEmpty) return 2
        return 3
    }

    LoadingSpinner { }
    ErrorView { message: vm.errorMessage }
    EmptyState { text: "No contacts yet" }
    ContactListView { model: vm.contacts }
}
```

**3. ViewModels do not know about QML**

A ViewModel should never import `QtQuick` or reference QML items. It is a pure data/logic adapter. The QML file imports and instantiates the ViewModel, not the reverse.

**4. One ViewModel per screen**

Each screen (or major feature area) has a dedicated ViewModel. Avoid monolithic application-level ViewModels that accumulate unrelated properties.

---

## Plugin-Based Architectures with `QQmlExtensionPlugin`

For large applications that need to be divided into independently-built and independently-loadable modules, `QQmlExtensionPlugin` provides the mechanism.

### What `QQmlExtensionPlugin` Solves

- **Separate compilation**: each plugin compiles independently; changes to one plugin do not require rebuilding others
- **Optional features**: plugins can be loaded conditionally at runtime
- **Third-party extension**: application developers can publish a plugin API; users (or other teams) extend the application by writing plugins
- **Team boundaries**: each team owns and ships a plugin; integration is through the published QML API

### Creating a Plugin

```cpp
// myplugin.h
#include <QQmlExtensionPlugin>

class MyPlugin : public QQmlExtensionPlugin
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID QQmlExtensionInterface_iid)

public:
    void registerTypes(const char *uri) override;
};
```

```cpp
// myplugin.cpp
#include "myplugin.h"
#include "mytype.h"
#include <qqml.h>

void MyPlugin::registerTypes(const char *uri) {
    // Types registered here using the legacy API
    // OR use QML_ELEMENT macros — the plugin just initializes the module
    qmlRegisterModule(uri, 1, 0);
}

// With modern CMake (Qt 6.6+), QML_ELEMENT macros handle registration
// and the plugin class only needs to exist for dynamic loading
```

```cmake
# CMakeLists.txt for the plugin
qt_add_library(myplugin SHARED)

qt_add_qml_module(myplugin
    URI "com.example.myplugin"
    VERSION 1.0
    PLUGIN_TARGET myplugin
    SOURCES
        myplugin.h myplugin.cpp
        mytype.h mytype.cpp
    QML_FILES
        MyView.qml
)
```

### Plugin Discovery

Qt discovers plugins by searching `importPath` directories for `qmldir` files. The engine's default search paths include:
- The application's executable directory
- Paths added via `QQmlEngine::addImportPath()`
- `QT_QML_IMPORT_PATH` environment variable

```cpp
// At application startup
engine.addImportPath("/opt/myapp/plugins");
```

QML then imports the plugin normally:

```qml
import com.example.myplugin

MyView { }
```

### Runtime Plugin Loading

For truly dynamic plugin discovery (plugins not known at compile time):

```cpp
QString pluginDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation)
                    + "/plugins";
engine.addImportPath(pluginDir);

// Scan the directory and list available plugins
QDir dir(pluginDir);
for (const QString &entry : dir.entryList(QDir::Dirs | QDir::NoDotAndDotDot)) {
    QFileInfo qmldir(pluginDir + "/" + entry + "/qmldir");
    if (qmldir.exists()) {
        // Plugin is available — the engine will load it on first import
        availablePlugins.append(entry);
    }
}
```

---

## Structuring Mono-repos with Multiple QML Modules

Large-team Qt projects frequently use a mono-repo with multiple QML modules organized by domain or feature. The key challenge is managing dependencies between modules while maintaining buildability and testability in isolation.

### Recommended Directory Structure

```
myapp/
├── CMakeLists.txt               (root build)
├── apps/
│   ├── desktop/                 (desktop application entry point)
│   └── mobile/                  (mobile application entry point)
├── modules/
│   ├── core/                    (shared utilities, base types)
│   │   ├── CMakeLists.txt
│   │   ├── qml/                 (QML: URI = com.example.core)
│   │   └── src/                 (C++/Python backend)
│   ├── contacts/                (contacts feature)
│   │   ├── CMakeLists.txt
│   │   ├── qml/                 (QML: URI = com.example.contacts)
│   │   └── src/
│   ├── messaging/               (messaging feature)
│   │   ├── CMakeLists.txt
│   │   ├── qml/                 (QML: URI = com.example.messaging)
│   │   └── src/
│   └── settings/                (settings feature)
│       ├── CMakeLists.txt
│       ├── qml/                 (QML: URI = com.example.settings)
│       └── src/
└── tests/
    ├── unit/
    └── integration/
```

### Dependency Rules

Enforce a one-way dependency graph between modules:

```
apps/desktop   depends on   modules/*
modules/*      depend on    modules/core
modules/core   depends on   Qt only
```

Never have `core` depend on a feature module. Never have two feature modules depend on each other (if they share code, extract it to `core`).

Enforce this in CMake with explicit target_link_libraries dependencies and optional use of CMake's `FORBIDDEN_TARGETS` or custom lint checks.

### Shared Component Library

The `core` module typically contains a shared component library of generic UI components (buttons, form fields, dialogs, cards) that all feature modules use:

```
modules/core/qml/
├── Button.qml              (custom styled button)
├── Card.qml                (surface card container)
├── Dialog.qml              (modal dialog base)
├── FormField.qml           (label + input group)
├── LoadingSpinner.qml
├── EmptyState.qml
└── ErrorView.qml
```

Feature modules import from `com.example.core` and combine core components with feature-specific logic:

```qml
// In com.example.contacts module
import com.example.core   // shared components

Card {
    FormField {
        label: "Name"
        textField.text: vm.name
        textField.onTextChanged: vm.name = textField.text
    }
}
```

### Build-Time Module Isolation

Each module should build and test independently. Structure `CMakeLists.txt` so each module can be built with a `cmake --build . --target <module_name>` command:

```cmake
# modules/contacts/CMakeLists.txt

# Backend library (C++ or Python bridge)
qt_add_library(contacts_backend STATIC
    src/contactmodel.cpp
    src/contactrepository.cpp
)
qt_add_qml_module(contacts_backend
    URI "com.example.contacts.backend"
    VERSION 1.0
    SOURCES src/contactmodel.h src/contactrepository.h
)
target_link_libraries(contacts_backend PUBLIC
    core_backend   # shared backend utilities
    Qt6::Quick Qt6::Sql
)

# QML module
qt_add_library(contacts_qml STATIC)
qt_add_qml_module(contacts_qml
    URI "com.example.contacts"
    VERSION 1.0
    QML_FILES
        qml/ContactListScreen.qml
        qml/ContactDetailScreen.qml
        qml/ContactEditDialog.qml
)
target_link_libraries(contacts_qml PUBLIC
    contacts_backend
    core_qml       # shared QML components
)
```

### Versioning Across Modules

Each QML module has a version (`VERSION 1.0` in `qt_add_qml_module`). When a module's public API changes in a backward-incompatible way, increment the major version. Consumers import a specific version:

```qml
import com.example.contacts 2.0  // explicit version
```

For minor additions (new types, new properties), increment the minor version. Consumers that import `1.0` continue to work when `1.3` is installed, because Qt's import system treats minor version increments as backward-compatible.

### Inter-Module Communication

Feature modules should not call each other directly. They communicate through:

**Shared singleton state in `core`**:

```qml
// com.example.core — NavigationState singleton
pragma Singleton
QtObject {
    signal navigateRequested(string module, string screen, var args)
}
```

```qml
// In contacts module
Button {
    onClicked: NavigationState.navigateRequested("messaging", "NewMessage",
                                                  { recipientId: contact.id })
}
```

The application shell (in `apps/desktop`) connects to `NavigationState.navigateRequested` and performs the actual navigation.

**Shared data models in `core`**:

Types that cross feature boundaries live in `core`. The `UserSession` singleton (authentication state) belongs in `core`, not in the `settings` module.

---

## Feature Flags and Module Activation

Large applications often need to enable/disable features at runtime (A/B testing, beta features, licensing tiers):

```qml
// FeatureFlags.qml — singleton in core
pragma Singleton
QtObject {
    property bool advancedSearch: false
    property bool darkMode: true
    property bool betaFeatures: false
}
```

Feature modules check flags before showing their content:

```qml
Loader {
    active: FeatureFlags.advancedSearch
    source: "AdvancedSearchPanel.qml"
}
```

On the C++ side, feature flags can be loaded from a remote configuration service, a license file, or a local settings file. Changing a flag property propagates through all QML bindings immediately.

---

## Summary

MVVM in QML is not an aspirational pattern — it is the natural shape of a well-structured PySide6 or C++/QML application. The binding engine implements the ViewModel-to-View data flow; the discipline is keeping business logic out of QML and visual logic out of the backend. Plugin-based architecture via `QQmlExtensionPlugin` enables independently compiled and optionally loadable feature modules, suitable for platform extension and team isolation. Mono-repo structures with multiple QML modules — each with its own URI, version, and `qt_add_qml_module` target — scale to large teams by enforcing module boundaries, one-way dependency graphs, and independent buildability. Inter-module communication through shared singletons and navigation signals avoids the tight coupling that would otherwise accumulate as features grow.
