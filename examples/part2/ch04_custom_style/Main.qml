// Main.qml — ch04_custom_style
// Demonstrates a minimal custom Qt Quick Controls style (MyStyle).
// Run with:
//   qml -I . Main.qml
// The -I . flag adds the current directory to the QML import path so that
// the MyStyle module (./MyStyle/qmldir) is found.

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Tell Qt Quick Controls to use our custom style at startup.
// In a real project you would set QT_QUICK_CONTROLS_STYLE=MyStyle or call
// QQuickStyle::setStyle("MyStyle") from C++.  When running with `qml` we
// use the pragma here for convenience.
pragma ComponentBehavior: Bound

ApplicationWindow {
    id:      root
    title:   "Chapter 4 – Custom Style"
    width:   640
    height:  480
    visible: true

    // Apply the custom style programmatically (Qt 6.5+).
    // Alternatively set QT_QUICK_CONTROLS_STYLE=MyStyle in the environment.
    Component.onCompleted: {
        // Style is resolved by the import path; nothing extra needed at runtime
        // when -I . is passed to qml and MyStyle/qmldir is present.
    }

    background: Rectangle {
        color: "#f5f4ff"
    }

    // ── main layout ───────────────────────────────────────────────────────
    ColumnLayout {
        anchors {
            fill:    parent
            margins: 32
        }
        spacing: 28

        // Section label helper
        component SectionLabel: Text {
            required property string label
            text:  label
            font { pixelSize: 12; weight: Font.Medium; letterSpacing: 1.2 }
            color: "#6c6c8a"
        }

        // ── Buttons ───────────────────────────────────────────────────────
        SectionLabel { label: "BUTTONS" }

        RowLayout {
            spacing: 12
            Layout.fillWidth: true

            Button {
                text: "Primary"
            }

            Button {
                text: "With Icon"
                icon.name: "go-next"      // uses system icon; falls back gracefully
            }

            Button {
                text: "Disabled"
                enabled: false
            }

            Button {
                text: "Flat"
                flat: true
            }

            Item { Layout.fillWidth: true }  // spacer
        }

        // ── TextFields ────────────────────────────────────────────────────
        SectionLabel { label: "TEXT FIELDS" }

        GridLayout {
            columns:     2
            columnSpacing: 20
            rowSpacing:  20
            Layout.fillWidth: true

            TextField {
                placeholderText: "First name"
                Layout.fillWidth: true
            }

            TextField {
                placeholderText: "Last name"
                Layout.fillWidth: true
            }

            TextField {
                placeholderText: "Email address"
                Layout.columnSpan: 2
                Layout.fillWidth: true
            }

            TextField {
                placeholderText: "Disabled field"
                enabled: false
                Layout.fillWidth: true
            }

            TextField {
                text:             "Pre-filled value"
                placeholderText:  "Label"
                Layout.fillWidth: true
            }
        }

        // ── submit row ────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Item { Layout.fillWidth: true }

            Button {
                text: "Cancel"
                flat: true
            }

            Button {
                text: "Submit"
            }
        }

        Item { Layout.fillHeight: true }  // bottom spacer
    }
}
