import QtQuick
import QtQuick.Controls

// DraggableBox — reusable component combining DragHandler + TapHandler.
// Required properties are supplied by the caller.
Rectangle {
    id: root

    required property color boxColor
    required property string label

    // Expose tap count so callers can observe it if needed.
    readonly property int tapCount: tapHandler.tapCount

    width: 120
    height: 60
    color: tapHandler.pressed ? Qt.darker(root.boxColor, 1.3) : root.boxColor
    radius: 8
    border.color: Qt.lighter(root.boxColor, 1.6)
    border.width: 2

    // Smooth color transition on press/release.
    Behavior on color { ColorAnimation { duration: 80 } }

    // ── Drag ─────────────────────────────────────────────────────────────────
    DragHandler {
        id: dragHandler
        // Constrain to the parent item's bounds (if it has one).
        // Set xAxis / yAxis to restrict movement direction if desired.
    }

    // ── Tap / long-press ─────────────────────────────────────────────────────
    TapHandler {
        id: tapHandler

        property int tapCount: 0

        onTapped: {
            tapCount++
            console.log(root.label, "tapped — total taps:", tapCount)
        }
        onLongPressed: {
            root.color = Qt.rgba(Math.random(), Math.random(), Math.random(), 1)
            console.log(root.label, "long-pressed — color randomised")
        }
    }

    // ── Labels ───────────────────────────────────────────────────────────────
    Column {
        anchors.centerIn: parent
        spacing: 2

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.label
            color: "white"
            font.pixelSize: 13
            font.bold: true
        }
        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "taps: " + tapHandler.tapCount
            color: "#dfe6e9"
            font.pixelSize: 11
        }
        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: dragHandler.active ? "dragging" : "idle"
            color: dragHandler.active ? "#fdcb6e" : "#b2bec3"
            font.pixelSize: 10
        }
    }
}
