import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// HeavyComponent — simulates an expensive component by deferring its
// initialisation work inside a Timer.  Loaded asynchronously by the
// second Loader in Main.qml.
Rectangle {
    id: root

    // Caller supplies the number of items to "build".
    required property int itemCount

    width: 420
    height: 180
    color: "#2d3436"
    radius: 8
    border.color: "#00b894"
    border.width: 2

    // Internal state
    property bool ready: false
    property int  builtCount: 0

    // Simulate heavy initialisation work spread over a short delay.
    Timer {
        id: initTimer
        interval: 800   // 800 ms pretend-work
        running: false
        repeat: false
        onTriggered: {
            root.builtCount = root.itemCount
            root.ready = true
            console.log("HeavyComponent: finished building", root.itemCount, "items")
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 8

        Label {
            text: root.ready ? "Heavy Component — Ready" : "Heavy Component — Initialising…"
            font.pixelSize: 16
            font.bold: true
            color: root.ready ? "#00b894" : "#fdcb6e"
        }

        ProgressBar {
            Layout.fillWidth: true
            indeterminate: !root.ready
            value: root.ready ? 1.0 : 0.0
        }

        Label {
            text: root.ready
                  ? "Built " + root.builtCount + " items successfully."
                  : "Building " + root.itemCount + " items, please wait…"
            color: "#dfe6e9"
            font.pixelSize: 13
        }

        Label {
            text: "Loaded asynchronously — UI stayed responsive."
            color: "#b2bec3"
            font.pixelSize: 11
        }
    }

    Component.onCompleted: {
        console.log("HeavyComponent: onCompleted — starting deferred init for",
                    root.itemCount, "items")
        initTimer.start()
    }
}
