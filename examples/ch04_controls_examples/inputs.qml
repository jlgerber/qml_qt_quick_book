// inputs.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    visible: true
    width: 380
    height: 500
    title: "Input Controls"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 10

        TextField {
            id: nameField
            placeholderText: "Enter your name"
            Layout.fillWidth: true
        }

        Label {
            text: "Volume: " + Math.round(volumeSlider.value) + "%"
            font.bold: true
        }

        Slider {
            id: volumeSlider
            from: 0
            to: 100
            stepSize: 5
            value: 50
            Layout.fillWidth: true
        }

        Label {
            text: "Comments:"
        }

        TextArea {
            placeholderText: "Enter multiple lines of text..."
            Layout.fillWidth: true
            Layout.preferredHeight: 60
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 16

            ColumnLayout {
                Label { text: "Quantity:"; font.bold: true }
                SpinBox {
                    from: 1
                    to: 100
                    value: 5
                }
            }

            ColumnLayout {
                Label { text: "Rotation:"; font.bold: true }
                Dial {
                    from: 0
                    to: 360
                    value: 45
                    implicitWidth: 80
                    implicitHeight: 80
                }
            }
        }

        Label {
            text: "Size: " + sizeCombo.currentText
            font.bold: true
        }

        ComboBox {
            id: sizeCombo
            model: ["Small", "Medium", "Large"]
            Layout.fillWidth: true
        }

        Rectangle {
            color: "#f0f0f0"
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            radius: 4

            Label {
                anchors.centerIn: parent
                text: nameField.text ? ("Hello, " + nameField.text + "!") : "Enter your name above"
            }
        }
    }
}