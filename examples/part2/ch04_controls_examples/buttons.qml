// buttons.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    visible: true
    width: 300
    height: 300
    title: "Button Controls"

    ColumnLayout {
        anchors.centerIn: parent
        anchors.margins: 16
        spacing: 12
        width: parent.width - 32

        Button {
            text: "Submit"
            Layout.fillWidth: true
            onClicked: resultText.text = "Form submitted!"
        }

        CheckBox {
            text: "Remember me"
            checked: true
        }

        Switch {
            text: "Dark mode"
            checked: false
        }

        RowLayout {
            Layout.fillWidth: true
            Label { text: "Options:" }
            RadioButton {
                text: "A"
                checked: true
            }
            RadioButton {
                text: "B"
            }
        }

        DelayButton {
            text: "Delete (hold 2s)"
            Layout.fillWidth: true
            delay: 2000
            onActivated: resultText.text = "Deleted!"
        }

        Rectangle {
            color: "#f0f0f0"
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            radius: 4

            Label {
                id: resultText
                anchors.centerIn: parent
                text: "Click Submit or Delete"
            }
        }
    }
}