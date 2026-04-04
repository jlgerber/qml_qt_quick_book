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