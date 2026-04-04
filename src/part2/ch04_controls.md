# Chapter 4: Qt Quick Controls 2: Internals and Customization

## Core Controls Overview

Qt Quick Controls provides a comprehensive library of interactive and presentational components for building modern UIs. All controls inherit from `Control` (which inherits from `Item`) and share the architecture described below. This section surveys the main control categories; Chapter 5 covers layouts and responsive design patterns.

### Buttons

Buttons and button-like controls respond to user interaction and trigger actions:

| Control | Purpose |
| --- | --- |
| `Button` | Standard push button; emits `clicked` signal |
| `CheckBox` | Two-state toggle with visual indicator |
| `RadioButton` | Mutually exclusive option within a group |
| `Switch` | Toggle switch for on/off states |
| `DelayButton` | Button that requires a long press to confirm |

```qml
// buttons.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    visible: true
    width: 300
    height: 200
    title: "Button Controls"

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 12

        Button {
            text: "Submit"
            onClicked: resultText.text = "Form submitted!"
        }

        CheckBox {
            text: "Remember me"
            checked: true
        }

        RowLayout {
            RadioButton {
                text: "Option A"
                checked: true
            }
            RadioButton {
                text: "Option B"
            }
        }

        Text {
            id: resultText
            text: "Click Submit"
        }
    }
}
```

### Inputs

Input controls allow users to enter or adjust values:

| Control | Purpose |
| --- | --- |
| `TextField` | Single-line text input with optional placeholder |
| `TextArea` | Multi-line text input with scrolling |
| `ComboBox` | Drop-down selection from a list |
| `Slider` | Continuous value selection along a track |
| `SpinBox` | Discrete integer input with increment/decrement buttons |
| `Dial` | Circular slider for angular values |

```qml
// inputs.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    visible: true
    width: 320
    height: 300
    title: "Input Controls"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        TextField {
            id: nameField
            placeholderText: "Enter your name"
            Layout.fillWidth: true
        }

        Text {
            text: "Volume: " + Math.round(volumeSlider.value) + "%"
        }

        Slider {
            id: volumeSlider
            from: 0
            to: 100
            stepSize: 5
            value: 50
            Layout.fillWidth: true
        }

        Text {
            text: "Size: " + sizeCombo.currentText
        }

        ComboBox {
            id: sizeCombo
            model: ["Small", "Medium", "Large"]
            Layout.fillWidth: true
        }

        Text {
            text: nameField.text ? ("Hello, " + nameField.text + "!") : "Enter your name above"
            color: "#666"
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }
    }
}
```

### Containers and Navigation

Containers hold other elements; navigation controls organize content across multiple screens:

| Control | Purpose |
| --- | --- |
| `ApplicationWindow` | Top-level window with menu bar, toolbars, header, footer |
| `StackView` | Stack-based navigation (push/pop screens) |
| `SwipeView` | Swipe-able pages; typically used with `PageIndicator` |
| `Drawer` | Slide-out side panel for menus or secondary content |
| `TabBar` | Tabbed navigation; typically paired with `StackLayout` |

```qml
// containers.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    visible: true
    width: 400
    height: 500
    title: "Navigation Example"

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        TabBar {
            id: tabBar
            Layout.fillWidth: true

            TabButton {
                text: "Home"
            }
            TabButton {
                text: "Settings"
            }
            TabButton {
                text: "About"
            }
        }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: tabBar.currentIndex

            // Home tab
            Rectangle {
                color: "#f0f0f0"
                Text {
                    anchors.centerIn: parent
                    text: "Welcome to Home"
                    font.pixelSize: 18
                }
            }

            // Settings tab
            Rectangle {
                color: "#e8f4f8"
                Text {
                    anchors.centerIn: parent
                    text: "Settings go here"
                    font.pixelSize: 18
                }
            }

            // About tab
            Rectangle {
                color: "#f4e8e8"
                Text {
                    anchors.centerIn: parent
                    text: "About this app"
                    font.pixelSize: 18
                }
            }
        }
    }
}
```

### Indicators

Indicators display progress, activity, or discrete states without direct user interaction:

| Control | Purpose |
| --- | --- |
| `ProgressBar` | Linear progress visualization; typically used during long operations |
| `BusyIndicator` | Rotating animation indicating an ongoing operation |
| `PageIndicator` | Dots showing which page/section is currently active |

```qml
// indicators.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    visible: true
    width: 320
    height: 280
    title: "Indicators Example"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 20

        Text {
            text: "Progress Bar"
            font.bold: true
        }

        ProgressBar {
            Layout.fillWidth: true
            from: 0
            to: 100
            value: progressTimer.elapsed % 101
        }

        Text {
            text: "Busy Indicator"
            font.bold: true
        }

        BusyIndicator {
            running: true
            width: 50
            height: 50
        }

        Text {
            text: "Page Indicator"
            font.bold: true
        }

        PageIndicator {
            count: 5
            currentIndex: Math.floor(progressTimer.elapsed / 500) % 5
        }
    }

    Timer {
        id: progressTimer
        running: true
        repeat: true
        interval: 50
        property int elapsed: 0
        onTriggered: elapsed += interval
    }
}
```

### Menus and Popups

Menus and popups provide contextual options and modal dialogs:

| Control | Purpose |
| --- | --- |
| `Menu` | Vertical menu with actions (used standalone or in `MenuBar`) |
| `MenuBar` | Horizontal menu bar; typically in `ApplicationWindow.menuBar` |
| `ToolTip` | Small label appearing on hover or focus |
| `Dialog` | Modal dialog box with user prompt and action buttons |

```qml
// menus.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    visible: true
    width: 350
    height: 300
    title: "Menus and Popups"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        Button {
            id: menuButton
            text: "Open Menu"

            onClicked: contextMenu.popup()
        }

        Menu {
            id: contextMenu

            MenuItem {
                text: "New"
                onTriggered: statusText.text = "New selected"
            }
            MenuItem {
                text: "Open"
                onTriggered: statusText.text = "Open selected"
            }
            MenuSeparator { }
            MenuItem {
                text: "Exit"
                onTriggered: Qt.quit()
            }
        }

        Button {
            id: dialogButton
            text: "Show Dialog"

            onClicked: confirmDialog.open()
        }

        Dialog {
            id: confirmDialog
            title: "Confirm Action"
            standardButtons: Dialog.Ok | Dialog.Cancel
            width: 250

            Text {
                text: "Are you sure?"
            }

            onAccepted: statusText.text = "Confirmed!"
            onRejected: statusText.text = "Cancelled"
        }

        Rectangle {
            color: "#f0f0f0"
            Layout.fillWidth: true
            Layout.preferredHeight: 60
            radius: 4

            Text {
                id: statusText
                anchors.centerIn: parent
                text: "Select a menu item or open dialog"
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true

                ToolTip {
                    visible: parent.containsMouse
                    text: "Hover for tooltip"
                    delay: 500
                }
            }
        }
    }
}
```

---

## Control Architecture: `background`, `contentItem`, `overlay`, and Delegates

Qt Quick Controls 2 (the `QtQuick.Controls` module) is not a thin wrapper around platform widgets. It is a fully custom, GPU-rendered control library that achieves platform-appropriate appearance through interchangeable *styles*, not through native widget APIs. This architecture gives complete rendering control at the cost of requiring explicit style implementations.

### The Control Anatomy

Every control in the library derives from `Control`, which defines a three-layer compositing model:

```text
┌─────────────────────────┐
│         overlay          │  z-order above everything
│  ┌───────────────────┐  │
│  │    contentItem     │  │  the control's primary content
│  └───────────────────┘  │
│       background         │  z-order below contentItem
└─────────────────────────┘
```

**`background`**: An arbitrary `Item` that renders behind the control's content. Typically a `Rectangle` with styling. The control resizes it to match its own dimensions.

**`contentItem`**: The primary visual content. For `Button`, it is a `Text` (the label). For `Slider`, it is the track and handle assembly. For `TextField`, it is the `TextInput`. The control positions `contentItem` inside its padding area.

**`overlay`**: Available on `Popup` and its subclasses. A fullscreen `Item` that sits above everything else in the window, used for modal backdrops.

Accessing these in a control subclass:

```qml
Button {
    id: btn

    background: Rectangle {
        color: btn.pressed ? "#1a6e9a" : btn.hovered ? "#2196a6" : "#3daee9"
        radius: 4
        border.color: btn.visualFocus ? "#f3b730" : "transparent"
        border.width: 2
    }

    contentItem: Text {
        text: btn.text
        font: btn.font
        color: "white"
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
}
```

### Padding and Insets

`Control` has two sizing systems that experienced developers often conflate:

**Padding** (`topPadding`, `bottomPadding`, `leftPadding`, `rightPadding`): Controls the space between the control's bounding box and the `contentItem`. The `contentItem` is sized and positioned within the padded area.

**Insets** (`topInset`, `bottomInset`, `leftInset`, `rightInset`): Controls the space between the control's bounding box and the `background`. Positive insets shrink the background relative to the control bounds; negative insets extend it beyond the bounds (useful for drop shadows that extend outside the control's layout area).

```qml
Button {
    topInset: -4; bottomInset: -4
    background: Rectangle {
        // Extends 4px above and below the button's layout rect
        radius: height / 2
        layer.enabled: true
        layer.effect: DropShadow { ... }
    }
}
```

### Delegates

Controls that render lists of items — `ComboBox`, `SpinBox`, menus, etc. — expose a `delegate` property for the item template. The delegate is instantiated for each item in the model, and the control manages positioning. This is the same delegate pattern as `ListView`.

```qml
ComboBox {
    model: ["Alpha", "Beta", "Gamma"]

    delegate: ItemDelegate {
        width: control.width
        text: modelData
        highlighted: control.highlightedIndex === index
        font.bold: control.currentIndex === index
    }
}
```

---

## The `QStyle`-less Approach and Platform Abstraction

Qt Widgets relies on `QStyle` — a C++ virtual interface with platform-specific implementations that paint widget chrome using QPainter. Qt Quick Controls 2 has no equivalent mechanism. Instead, it uses *QML-based styles*: a set of QML files that provide the `background`, `contentItem`, and other visual pieces for each control type.

### Available Styles

Qt ships several built-in styles:

| Style | Character |
| --- | --- |
| `Basic` | Minimal, no platform pretense, suitable as a base for custom styles |
| `Fusion` | Cross-platform desktop look, closer to Qt Widgets' Fusion |
| `Material` | Google Material Design 2 |
| `Universal` | Microsoft Fluent Design |
| `iOS` | Platform-appropriate for Apple mobile |
| `macOS` | Uses native-looking controls via QML |
| `Windows` | Platform-appropriate for Windows |
| `Imagine` | Image-asset-driven styling (nine-patch images) |

Select the style at startup:

```cpp
// C++
QQuickStyle::setStyle("Material");
```

```python
# Python
from PySide6.QtQuickControls2 import QQuickStyle
QQuickStyle.setStyle("Material")
```

Or via environment variable: `QT_QUICK_CONTROLS_STYLE=Material`.

### Style Fallback Chain

Qt Quick Controls uses a *fallback style* mechanism. If a control is not defined in the active style, the engine falls back to the `Basic` style implementation. This means custom styles only need to define the controls they want to customize — undefined controls get `Basic` defaults automatically.

---

## Building and Distributing a Custom Style from Scratch

A custom style is a directory of QML files, one per control type, following a specific naming and structure convention.

### Directory Layout

```
MyStyle/
├── MyStyle.conf          (optional: configure fallback style)
├── Button.qml
├── TextField.qml
├── CheckBox.qml
├── ...
└── qmldir
```

The `qmldir` registers the style's QML module:

```
module MyStyle
Button 2.15 Button.qml
TextField 2.15 TextField.qml
```

### A Minimal `Button.qml`

```qml
// MyStyle/Button.qml
import QtQuick
import QtQuick.Controls.impl    // for IconLabel, etc.
import QtQuick.Templates as T   // for T.Button base

T.Button {
    id: control

    implicitWidth: Math.max(
        implicitBackgroundWidth + leftInset + rightInset,
        implicitContentWidth + leftPadding + rightPadding
    )
    implicitHeight: Math.max(
        implicitBackgroundHeight + topInset + bottomInset,
        implicitContentHeight + topPadding + bottomPadding
    )

    padding: 12
    horizontalPadding: 16
    spacing: 8

    icon.width: 20
    icon.height: 20
    icon.color: control.enabled ? "#ffffff" : "#80ffffff"

    background: Rectangle {
        implicitWidth: 80
        implicitHeight: 36
        radius: 4
        color: control.pressed ? Qt.darker("#3daee9", 1.2)
             : control.hovered ? Qt.lighter("#3daee9", 1.1)
             : "#3daee9"
        opacity: control.enabled ? 1 : 0.6

        Behavior on color { ColorAnimation { duration: 80 } }
    }

    contentItem: IconLabel {
        spacing: control.spacing
        mirrored: control.mirrored
        display: control.display

        icon: control.icon
        text: control.text
        font: control.font
        color: control.enabled ? "#ffffff" : "#80ffffff"
    }
}
```

Note the use of `T.Button` from `QtQuick.Templates` — this is the non-visual base that provides all button logic (press detection, toggle behavior, checked state) without any visual opinion. Your `Button.qml` adds the visuals on top.

### Registering the Style

Register your style module in `CMakeLists.txt`:

```cmake
qt_add_qml_module(myapp
    URI MyApp
    QML_FILES Main.qml
)

qt_add_qml_module(mystyle
    URI MyStyle
    QML_FILES
        MyStyle/Button.qml
        MyStyle/TextField.qml
        # ...
)
```

Or in Python using `qmldir` and `QQmlEngine.addImportPath()`.

### Style Configuration File

`MyStyle.conf` (an INI file) sets the fallback style and custom palette/font defaults:

```ini
[Controls]
Style=MyStyle

[MyStyle]
Variant=Normal

[Palette]
Window=#1e1e2e
WindowText=#cdd6f4
Base=#313244
```

### Distributing as a Plugin

For sharing a style across applications, compile it as a QML plugin (`qt_add_plugin` with `PLUGIN_TYPE qmltypes` in CMake). The resulting `.so`/`.dll` is placed in the Qt Quick Controls style search path.

---

## Common Customization Patterns

### Overriding a Single Control Without a Full Style

For one-off customizations within a specific component, override the `background` or `contentItem` inline:

```qml
TextField {
    background: Rectangle {
        color: "transparent"
        border.color: parent.activeFocus ? "#3daee9" : "#555"
        border.width: parent.activeFocus ? 2 : 1
        radius: 4

        Behavior on border.color { ColorAnimation { duration: 100 } }
    }
}
```

### Palette Integration

All controls read colors from their `palette` property, which propagates down the item hierarchy. Set a palette at the `ApplicationWindow` level to theme the entire application:

```qml
ApplicationWindow {
    palette.button: "#3daee9"
    palette.buttonText: "#ffffff"
    palette.highlight: "#27ae60"
    palette.highlightedText: "#ffffff"
    // ...
}
```

Custom styles that use `palette.button` etc. in their `background` color expressions will respond automatically.

### Font Propagation

Like `palette`, `font` propagates down the hierarchy. Set `font.family` and `font.pixelSize` at the root and all controls inherit it.

---

## Summary

Qt Quick Controls 2 gives complete rendering flexibility through its background/contentItem/overlay architecture and QML-based styles. The `QStyle`-less approach means there is no platform style engine to fight — what you write in QML is exactly what renders. For serious applications, a custom style provides consistent branding across all controls without per-instance overrides. Understanding the `T.*` template types from `QtQuick.Templates` is essential: they are where all the control logic lives, and your visual implementations build on them.
