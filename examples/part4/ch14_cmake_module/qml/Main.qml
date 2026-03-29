import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import com.example.backend

// Main.qml — root window for the CounterApp example.
// Demonstrates how a QML module (com.example.app) can depend on a
// separate C++ QML module (com.example.backend) and instantiate
// types from it directly.
Window {
    id: root
    width: 360
    height: 260
    visible: true
    title: qsTr("Counter — ch14")

    // Counter is auto-registered via QML_ELEMENT in counter.h
    Counter {
        id: counter
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 16

        // Value display
        Label {
            Layout.alignment: Qt.AlignHCenter
            text: counter.value
            font.pixelSize: 72
            font.bold: true
        }

        // Boundary indicators
        Label {
            Layout.alignment: Qt.AlignHCenter
            text: counter.atMaximum ? qsTr("Maximum reached") :
                  counter.atMinimum ? qsTr("Minimum reached") : ""
            color: counter.atMaximum ? "tomato" : "steelblue"
            font.pixelSize: 13
        }

        // +  /  −  /  Reset buttons
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 12

            Button {
                text: qsTr("−")
                font.pixelSize: 20
                enabled: !counter.atMinimum
                onClicked: counter.decrement()
            }

            Button {
                text: qsTr("Reset")
                onClicked: counter.reset()
            }

            Button {
                text: qsTr("+")
                font.pixelSize: 20
                enabled: !counter.atMaximum
                onClicked: counter.increment()
            }
        }
    }
}
