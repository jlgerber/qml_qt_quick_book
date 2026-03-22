# Chapter 7: Navigation Patterns and Application Shell

## `StackView`, `SwipeView`, `TabBar`, and `Drawer`

Qt Quick Controls provides several high-level navigation components that implement established UX patterns out of the box. Each is appropriate for different contexts; using the wrong one leads to non-idiomatic UIs that users find confusing.

### `StackView`

`StackView` implements a navigation stack — the model behind back/forward navigation in mobile apps and wizard-style desktop dialogs. Pages are pushed onto the stack and popped from it; the view animates transitions between pages.

```qml
StackView {
    id: stack
    anchors.fill: parent
    initialItem: HomeScreen { }
}

// Elsewhere: push a new page
stack.push(Qt.resolvedUrl("DetailScreen.qml"), { itemId: model.id })

// Go back
stack.pop()

// Replace the current top (no back navigation)
stack.replace(Qt.resolvedUrl("SettingsScreen.qml"))
```

`push()` accepts:
- A URL string or `Qt.resolvedUrl()` result — the QML file is loaded on demand
- A `Component` — instantiated immediately
- An already-created `Item` — placed on the stack directly
- A `{properties}` map as the second argument — merged into the pushed item

The stack maintains page instances by default, allowing them to preserve their state when navigated back to. To release memory, use `StackView.ForceLoad` or manage instances explicitly.

**Custom transitions**: override `pushEnter`, `pushExit`, `popEnter`, `popExit` to define custom animations:

```qml
StackView {
    pushEnter: Transition {
        PropertyAnimation { property: "opacity"; from: 0; to: 1; duration: 200 }
    }
    pushExit: Transition {
        PropertyAnimation { property: "opacity"; from: 1; to: 0; duration: 200 }
    }
}
```

**Depth and back navigation**: `stack.depth` gives the number of items. The current item is `stack.currentItem`. Connecting the hardware back button (Android, etc.) to `stack.pop()` when `stack.depth > 1` implements standard back behavior:

```qml
ApplicationWindow {
    onClosing: (close) => {
        if (stack.depth > 1) {
            close.accepted = false
            stack.pop()
        }
    }
}
```

### `SwipeView`

`SwipeView` presents pages that the user swipes through horizontally (or vertically). All pages are logically accessible; there is no concept of a stack — swiping moves through a flat index sequence.

```qml
SwipeView {
    id: swipeView
    anchors.fill: parent
    currentIndex: tabBar.currentIndex

    OnboardingPage1 { }
    OnboardingPage2 { }
    OnboardingPage3 { }
}

PageIndicator {
    anchors.bottom: swipeView.bottom
    anchors.horizontalCenter: parent.horizontalCenter
    count: swipeView.count
    currentIndex: swipeView.currentIndex
}
```

Bind `SwipeView.currentIndex` to a `TabBar` or `PageIndicator` for synchronized navigation. The binding is bidirectional via index synchronization:

```qml
TabBar {
    id: tabBar
    currentIndex: swipeView.currentIndex

    TabButton { text: "Home" }
    TabButton { text: "Feed" }
    TabButton { text: "Profile" }
}
```

`SwipeView` lazily instantiates pages as they are approached — only the current page and its immediate neighbors are active. Pages further away are unloaded if `SwipeView.isCurrentItem` / `SwipeView.isPreviousItem` / `SwipeView.isNextItem` is used as an `active` condition on a `Loader`.

### `TabBar` and `TabButton`

`TabBar` is a navigation control that pairs with `SwipeView` or any indexed content container. It does not contain the content — it only manages selection:

```qml
ColumnLayout {
    TabBar {
        id: bar
        Layout.fillWidth: true

        TabButton { text: "Documents" }
        TabButton { text: "Recents" }
        TabButton { text: "Shared" }
    }

    StackLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        currentIndex: bar.currentIndex

        DocumentsPane { }
        RecentsPane { }
        SharedPane { }
    }
}
```

`StackLayout` is a lightweight alternative to `SwipeView` for tab-driven content switching when swipe gestures are not desired. It does not animate transitions and keeps all children instantiated (unlike `SwipeView`'s lazy loading).

### `Drawer`

`Drawer` implements a panel that slides in from the edge of the window. It is used for side navigation menus (the "hamburger menu" pattern) on smaller screens.

```qml
Drawer {
    id: drawer
    width: Math.min(parent.width * 0.8, 300)
    height: parent.height
    edge: Qt.LeftEdge    // or RightEdge, TopEdge, BottomEdge

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // App header inside drawer
        DrawerHeader {
            Layout.fillWidth: true
        }

        // Navigation items
        Repeater {
            model: navItems
            delegate: NavigationItem {
                Layout.fillWidth: true
                onClicked: {
                    drawer.close()
                    stack.push(model.page)
                }
            }
        }

        Item { Layout.fillHeight: true }   // spacer

        // Footer items
        NavigationItem {
            Layout.fillWidth: true
            text: "Settings"
        }
    }
}
```

`Drawer` can be *modal* (blocks interaction with the rest of the UI while open) or *non-modal*. A non-modal drawer can be permanently visible on wider screens as a sidebar:

```qml
Drawer {
    modal: root.isCompact    // modal on small screens, non-modal on large
    interactive: root.isCompact   // disable swipe gesture on large screens
    position: root.isCompact ? 0.0 : 1.0   // always open on large screens
}
```

---

## Application-Wide Navigation State Machines

### The Problem with Ad-hoc Navigation

As applications grow, ad-hoc navigation calls (`stack.push(...)`, `drawer.close()`) scattered through event handlers become difficult to reason about. Navigation logic entangles with presentation logic. Deep links, programmatic navigation, and back-stack management become error-prone.

The solution is to centralize navigation state in an explicit state machine or a navigation controller object.

### A Navigation Controller Singleton

A QML singleton acting as a navigation controller provides a single API for all navigation actions:

```qml
// NavigationController.qml (registered as singleton)
pragma Singleton
import QtQuick

QtObject {
    id: controller

    // Signals that the shell responds to
    signal navigateTo(string page, var args)
    signal navigateBack()
    signal drawerOpen()
    signal drawerClose()

    // Public navigation API
    function goHome() { navigateTo("Home", {}) }
    function goToDetail(itemId) { navigateTo("Detail", { id: itemId }) }
    function goToSettings() { navigateTo("Settings", {}) }
    function back() { navigateBack() }
}
```

The application shell connects to these signals and performs the actual navigation:

```qml
// ApplicationShell.qml
StackView {
    id: stack
    initialItem: homePage

    Connections {
        target: NavigationController
        function onNavigateTo(page, args) {
            stack.push(Qt.resolvedUrl(page + "Screen.qml"), args)
        }
        function onNavigateBack() {
            if (stack.depth > 1) stack.pop()
        }
    }
}
```

Individual screens call the controller, not the stack directly:

```qml
// DetailScreen.qml
Button {
    text: "Back"
    onClicked: NavigationController.back()
}
```

This decouples screens from the navigation implementation. The same controller API works whether the shell uses `StackView`, `SwipeView`, or a web-based router when targeting WebAssembly.

### State Machine Navigation

For applications with complex conditional navigation rules — authentication flows, onboarding, feature flags — model navigation as a state machine using `StateGroup`:

```qml
QtObject {
    id: appState

    property string current: "splash"
    readonly property bool isAuthenticated: authService.isLoggedIn
    readonly property bool hasCompletedOnboarding: settings.onboardingDone

    StateGroup {
        states: [
            State {
                name: "splash"
                when: appState.current === "splash"
            },
            State {
                name: "auth"
                when: !appState.isAuthenticated
            },
            State {
                name: "onboarding"
                when: appState.isAuthenticated && !appState.hasCompletedOnboarding
            },
            State {
                name: "main"
                when: appState.isAuthenticated && appState.hasCompletedOnboarding
            }
        ]
    }
}
```

The shell's `Loader` or `StackView` binds to `appState.current`:

```qml
Loader {
    source: {
        switch (appState.current) {
            case "splash": return "SplashScreen.qml"
            case "auth": return "AuthFlow.qml"
            case "onboarding": return "OnboardingFlow.qml"
            case "main": return "MainShell.qml"
        }
    }
}
```

---

## Multi-Window and Multi-Screen Applications

### Opening Additional Windows

Additional windows are created by instantiating `Window` or `ApplicationWindow`:

```qml
Window {
    id: secondWindow
    title: "Inspector"
    width: 400; height: 600
    visible: false
}

Button {
    text: "Open Inspector"
    onClicked: secondWindow.show()
}
```

Or dynamically:

```qml
Component {
    id: windowComponent
    Window {
        property var data
        title: "Detail: " + data.name
        onClosing: destroy()
    }
}

function openDetailWindow(item) {
    let w = windowComponent.createObject(null, { data: item })
    w.show()
}
```

### Multi-Screen Awareness

`Screen.virtualX` and `Screen.virtualY` give a window's position in the virtual desktop coordinate space. To open a window on a specific screen:

```qml
Window {
    x: targetScreen.virtualX + (targetScreen.width - width) / 2
    y: targetScreen.virtualY + (targetScreen.height - height) / 2
}
```

`Qt.application.screens` lists all available screens as a model:

```qml
Repeater {
    model: Qt.application.screens
    delegate: Text {
        text: modelData.name + ": " + modelData.width + "×" + modelData.height
    }
}
```

### Sharing Data Between Windows

QML objects in different windows belong to the same QML engine and can reference each other directly if they share a common ancestor or are registered as singletons. The most robust pattern is a shared singleton model:

```qml
// SharedState singleton
pragma Singleton
QtObject {
    property var selectedItem: null
    signal selectionChanged()
}
```

Both windows bind to `SharedState.selectedItem`, and changes propagate automatically through the binding engine regardless of which window made the change.

---

## Summary

Navigation in Qt Quick has well-established patterns for each use case: `StackView` for hierarchical navigation with back traversal, `SwipeView` + `TabBar` for flat peer navigation, `Drawer` for hidden navigation panels. As complexity grows, centralizing navigation in a controller object or state machine prevents the spaghetti that emerges from scattered imperative navigation calls. Multi-window applications are straightforward — Qt's single-engine model means all windows share the same type registry, binding engine, and can reference shared singleton state naturally.
