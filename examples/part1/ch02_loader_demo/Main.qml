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

        // ── GroupBox + Loader dynamic sizing — problem and solution ──────────
        //
        // PROBLEM (three interacting issues):
        //
        // 1. GroupBox.implicitHeight is derived from contentItem.implicitHeight.
        //    The default contentItem is a plain Item whose implicitHeight is
        //    always 0, so a GroupBox with only plain children collapses to its
        //    title-bar height.
        //
        // 2. Even when a ColumnLayout is set as the contentItem, GroupBox also
        //    writes contentItem.height = availableHeight (derived from the
        //    GroupBox's own height).  This creates a feedback loop: on expand
        //    the layout grows correctly, but on collapse the explicit height
        //    assignment keeps the layout stuck at the old (expanded) size.
        //
        // 3. Loader.implicitHeight tracks item.implicitHeight, not item.height.
        //    Loaded components that declare 'height: N' leave
        //    Loader.implicitHeight at 0; the ColumnLayout sees no height to
        //    allocate, so nothing appears.
        //
        // SOLUTION:
        //
        // • Loaded components (DetailPane, HeavyComponent) use implicitHeight
        //   so Loader.implicitHeight propagates correctly.
        //
        // • Each GroupBox overrides implicitHeight directly:
        //     implicitHeight: topPadding + bottomPadding + layout.implicitHeight
        //   topPadding already includes the title label, so this formula gives
        //   the correct total height and avoids the contentItem feedback loop.
        //
        // • The Loader uses Layout.preferredHeight (not implicitHeight) to drive
        //   its layout slot.  This survives the GroupBox height-assignment, so
        //   the slot — and therefore the GroupBox — actually collapses to zero
        //   when the item is hidden.  A Behavior animates the transition.

        // ── Section 1: toggle Loader.active ──────────────────────────────────
        GroupBox {
            Layout.fillWidth: true
            title: "1 · Loader.active — show / hide on demand"
            implicitHeight: topPadding + bottomPadding + section1Layout.implicitHeight

            ColumnLayout {
                id: section1Layout
                width: parent.availableWidth
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

                // Layout.preferredHeight drives the layout slot; it animates to 0
                // on hide so the GroupBox actually shrinks.  clip prevents the
                // fading content from bleeding outside the collapsing rect.
                Loader {
                    id: detailLoader
                    Layout.fillWidth: true
                    Layout.preferredHeight: status === Loader.Ready ? implicitHeight : 0
                    clip: true
                    active: false

                    onActiveChanged: {
                        if (active) {
                            setSource("DetailPane.qml", {
                                title: "Order Details — Invoice #4892"
                            })
                        }
                    }

                    Behavior on Layout.preferredHeight { NumberAnimation { duration: 180 } }
                    Behavior on opacity                { NumberAnimation { duration: 180 } }
                    opacity: status === Loader.Ready ? 1.0 : 0.0
                }
            }
        }

        // ── Section 2: asynchronous Loader ───────────────────────────────────
        GroupBox {
            Layout.fillWidth: true
            title: "2 · Loader.asynchronous — non-blocking load with BusyIndicator"

            implicitHeight: topPadding + bottomPadding + section2Layout.implicitHeight

            ColumnLayout {
                id: section2Layout
                width: parent.availableWidth
                spacing: 10

                RowLayout {
                    spacing: 10
                    Button {
                        text: "Load Heavy Component"
                        enabled: asyncLoader.status !== Loader.Loading
                               && asyncLoader.status !== Loader.Ready
                        onClicked: asyncLoader.active = true
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

                BusyIndicator {
                    running: asyncLoader.status === Loader.Loading
                    visible: running
                    Layout.alignment: Qt.AlignHCenter
                }

                Loader {
                    id: asyncLoader
                    Layout.fillWidth: true
                    Layout.preferredHeight: status === Loader.Ready ? implicitHeight : 0
                    clip: true
                    active: false
                    asynchronous: true
                    // NOTE: do NOT also set 'source' here — setSource() below
                    // supplies the required 'itemCount' property atomically.
                    // Having both 'source' and setSource() races: the 'source'
                    // binding fires first without the required property, causing
                    // a Status:Error before setSource() can correct it.
                    onActiveChanged: {
                        if (active)
                            setSource("HeavyComponent.qml", { itemCount: 250 })
                    }

                    onLoaded: {
                        console.log("HeavyComponent finished loading — giving focus")
                        item.forceActiveFocus()
                    }

                    Behavior on Layout.preferredHeight { NumberAnimation { duration: 220 } }
                    Behavior on opacity                { NumberAnimation { duration: 220 } }
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
