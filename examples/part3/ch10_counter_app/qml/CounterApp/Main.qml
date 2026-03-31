// Chapter 10 – Counter App
// Shows Property / Signal / Slot in action with two-way SpinBox binding.

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import com.example.counter

ApplicationWindow {
    id: root
    title: "Counter"
    width: 400
    height: 520
    visible: true

    // Instantiate the Python Counter type registered via @QmlElement.
    Counter {
        id: counter
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 20

        // ----------------------------------------------------------------
        // Large value display
        // ----------------------------------------------------------------
        Label {
            Layout.alignment: Qt.AlignHCenter
            text: counter.value
            font.pixelSize: 80
            font.bold: true
        }

        // ----------------------------------------------------------------
        // +  /  –  /  Reset buttons
        // ----------------------------------------------------------------
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 12

            Button {
                text: "−"
                font.pixelSize: 22
                implicitWidth: 60
                implicitHeight: 60
                onClicked: counter.decrement()
            }

            Button {
                text: "+"
                font.pixelSize: 22
                implicitWidth: 60
                implicitHeight: 60
                onClicked: counter.increment()
            }

            Button {
                text: "Reset"
                implicitHeight: 60
                onClicked: counter.reset()
            }
        }

        // ----------------------------------------------------------------
        // SpinBox – two-way binding via onValueModified → counter.setValue
        // ----------------------------------------------------------------
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 8

            Label { text: "Direct entry:" }

            SpinBox {
                id: spinBox
                from: 0
                to: 9999
                // One-way: Python → QML
                value: counter.value
                // Other way: QML → Python (only when user edits, not on sync)
                onValueModified: counter.setValue(spinBox.value)
            }
        }

        // ----------------------------------------------------------------
        // History list (last 5 values)
        // ----------------------------------------------------------------
        Label {
            text: "History (last 5):"
            font.bold: true
        }

        ListView {
            id: historyView
            Layout.fillWidth: true
            implicitHeight: 120
            clip: true
            // counter.history is a QVariantList; wrap it in a ListModel
            // via a JS array model (simplest approach for small lists).
            model: counter.history

            delegate: ItemDelegate {
                width: historyView.width
                text: "→ " + modelData
                font.pixelSize: 14
            }

            // Scroll to bottom whenever history updates.
            onCountChanged: positionViewAtEnd()
        }
    }
}
