import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Ch01 — The Binding Engine
// Demonstrates:
//   • Property bindings on width / height / color
//   • How assigning a plain value *breaks* a binding
//   • How Qt.binding() restores a binding at runtime
ApplicationWindow {
    id: root
    title: "Ch01 – Binding Engine Demo"
    width: 700
    height: 500
    visible: true

    // ── shared model value driven by the slider ──────────────────────────────
    property real masterWidth: widthSlider.value

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 16

        // ── Slider ───────────────────────────────────────────────────────────
        RowLayout {
            spacing: 12
            Label { text: "Master width:" }
            Slider {
                id: widthSlider
                Layout.fillWidth: true
                from: 100
                to: root.width - 40
                value: 400
                stepSize: 1
            }
            Label {
                // Binding: text re-evaluates whenever masterWidth changes.
                text: root.masterWidth.toFixed(0) + " px"
                font.bold: true
                Layout.minimumWidth: 70
            }
        }

        // ── Parent rectangle (width bound to slider) ─────────────────────────
        Rectangle {
            id: parentRect
            // Binding: parentRect.width tracks root.masterWidth exactly.
            width: root.masterWidth
            height: 60
            color: "#3daee9"
            radius: 6

            Label {
                anchors.centerIn: parent
                text: "Parent  " + parentRect.width.toFixed(0) + " px"
                color: "white"
                font.pixelSize: 14
            }
        }

        // ── Two child rectangles bound to fractions of the parent width ───────
        RowLayout {
            spacing: 8

            Rectangle {
                id: leftChild
                // Binding: always 40 % of the parent.
                width: parentRect.width * 0.40
                height: 50
                color: "#27ae60"
                radius: 6
                Label {
                    anchors.centerIn: parent
                    text: "40 %\n" + leftChild.width.toFixed(0) + " px"
                    horizontalAlignment: Text.AlignHCenter
                    color: "white"
                    font.pixelSize: 12
                }
            }

            Rectangle {
                id: rightChild
                // Binding: always 55 % of the parent.
                width: parentRect.width * 0.55
                height: 50
                color: "#8e44ad"
                radius: 6
                Label {
                    anchors.centerIn: parent
                    text: "55 %\n" + rightChild.width.toFixed(0) + " px"
                    horizontalAlignment: Text.AlignHCenter
                    color: "white"
                    font.pixelSize: 12
                }
            }
        }

        // ── Binding breakage demo ────────────────────────────────────────────
        Rectangle {
            id: breakableRect
            width: root.masterWidth   // starts as a binding
            height: 50
            color: bindingBroken ? "#e74c3c" : "#e67e22"
            radius: 6

            property bool bindingBroken: false

            Label {
                anchors.centerIn: parent
                text: breakableRect.bindingBroken
                      ? "Binding BROKEN — width frozen at " + breakableRect.width.toFixed(0) + " px"
                      : "Binding LIVE — width " + breakableRect.width.toFixed(0) + " px"
                color: "white"
                font.pixelSize: 13
            }
        }

        RowLayout {
            spacing: 10

            Button {
                text: "Break binding (assign literal)"
                onClicked: {
                    // Assigning a plain value destroys the binding.
                    breakableRect.width = breakableRect.width   // freeze current value
                    breakableRect.bindingBroken = true
                }
            }

            Button {
                text: "Restore with Qt.binding()"
                onClicked: {
                    // Qt.binding() installs a new binding expression at runtime.
                    breakableRect.width = Qt.binding(function() {
                        return root.masterWidth
                    })
                    breakableRect.bindingBroken = false
                }
            }
        }

        // ── Binding loop guard note ──────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 56
            color: "#2c3e50"
            radius: 6
            Label {
                anchors.centerIn: parent
                width: parent.width - 24
                text: "Tip: a binding that reads and writes the same property "
                    + "creates a binding loop — Qt will warn and break it automatically."
                color: "#ecf0f1"
                font.pixelSize: 12
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
            }
        }

        Item { Layout.fillHeight: true }
    }
}
