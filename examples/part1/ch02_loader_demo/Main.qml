import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Ch02 — Loader
// Demonstrates:
//   • Loader.active toggle (show / hide on demand)
//   • Loader.asynchronous with BusyIndicator
//   • Loader.setSource() with initial properties
//   • Loader.status (Null / Loading / Ready / Error)
//   • onLoaded signal to give focus after async load
ApplicationWindow {
    id: root
    title: "Ch02 – Loader Demo"
    width: 720
    height: 640
    visible: true

    // Helper: human-readable status string
    function statusText(loader) {
        switch (loader.status) {
        case Loader.Null:    return "Null (inactive)"
        case Loader.Loading: return "Loading…"
        case Loader.Ready:   return "Ready"
        case Loader.Error:   return "Error"
        default:             return "Unknown"
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        // ── Section 1: toggle Loader.active ──────────────────────────────────
        GroupBox {
            Layout.fillWidth: true
            title: "1 · Loader.active — show / hide on demand"

            ColumnLayout {
                anchors.fill: parent
                spacing: 10

                RowLayout {
                    spacing: 10
                    Button {
                        id: toggleButton
                        text: detailLoader.active ? "Hide Details" : "Show Details"
                        onClicked: detailLoader.active = !detailLoader.active
                    }
                    Label {
                        text: "Status: " + root.statusText(detailLoader)
                        font.italic: true
                        color: detailLoader.status === Loader.Ready ? "#27ae60" : "#7f8c8d"
                    }
                }

                // The Loader itself — uses setSource() so we can pass initial props.
                Loader {
                    id: detailLoader
                    Layout.fillWidth: true
                    active: false

                    // setSource is called each time active flips to true.
                    onActiveChanged: {
                        if (active) {
                            // Pass a required property as an initial property map.
                            setSource("DetailPane.qml", {
                                title: "Order Details — Invoice #4892"
                            })
                        }
                    }

                    // Animate the appearance / disappearance.
                    Behavior on opacity { NumberAnimation { duration: 180 } }
                    opacity: status === Loader.Ready ? 1.0 : 0.0
                }
            }
        }

        // ── Section 2: asynchronous Loader ───────────────────────────────────
        GroupBox {
            Layout.fillWidth: true
            title: "2 · Loader.asynchronous — non-blocking load with BusyIndicator"

            ColumnLayout {
                anchors.fill: parent
                spacing: 10

                RowLayout {
                    spacing: 10
                    Button {
                        text: "Load Heavy Component"
                        enabled: asyncLoader.status !== Loader.Loading
                               && asyncLoader.status !== Loader.Ready
                        onClicked: {
                            asyncLoader.active = true
                        }
                    }
                    Button {
                        text: "Unload"
                        enabled: asyncLoader.status === Loader.Ready
                        onClicked: asyncLoader.active = false
                    }
                    Label {
                        text: "Status: " + root.statusText(asyncLoader)
                        font.italic: true
                        color: {
                            switch (asyncLoader.status) {
                            case Loader.Loading: return "#e67e22"
                            case Loader.Ready:   return "#27ae60"
                            case Loader.Error:   return "#e74c3c"
                            default:             return "#7f8c8d"
                            }
                        }
                    }
                }

                // BusyIndicator shown only while the Loader is working.
                BusyIndicator {
                    running: asyncLoader.status === Loader.Loading
                    visible: running
                    Layout.alignment: Qt.AlignHCenter
                }

                Loader {
                    id: asyncLoader
                    Layout.fillWidth: true
                    active: false
                    asynchronous: true
                    source: active ? "HeavyComponent.qml" : ""

                    // Pass initial properties for the required property.
                    // NOTE: for asynchronous loaders use the Binding + item pattern
                    // or setSource().  Here we use setSource via onActiveChanged.
                    onActiveChanged: {
                        if (active) {
                            setSource("HeavyComponent.qml", { itemCount: 250 })
                        }
                    }

                    // Give keyboard focus to the loaded item once it is ready.
                    onLoaded: {
                        console.log("HeavyComponent finished loading — giving focus")
                        item.forceActiveFocus()
                    }

                    Behavior on opacity { NumberAnimation { duration: 220 } }
                    opacity: status === Loader.Ready ? 1.0 : 0.0
                }
            }
        }

        // ── Section 3: status bar ────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 32
            color: "#2c3e50"
            radius: 4

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10

                Label {
                    text: "DetailPane: " + root.statusText(detailLoader)
                    color: "#ecf0f1"
                    font.pixelSize: 12
                }
                Item { Layout.fillWidth: true }
                Label {
                    text: "HeavyComponent: " + root.statusText(asyncLoader)
                    color: "#ecf0f1"
                    font.pixelSize: 12
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}
