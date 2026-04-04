import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    visible: true
    width: 300
    height: 200
    title: "Button Controls"

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 12

        Button {
            text: "Submit"
            onClicked: resultText.text = "Form submitted!"
        }

        CheckBox {
            text: "Remember me"
            checked: true
        }

        RowLayout {
            RadioButton {
                text: "Option A"
                checked: true
            }
            RadioButton {
                text: "Option B"
            }
        }

        Text {
            id: resultText
            text: "Click Submit"
        }
    }
}