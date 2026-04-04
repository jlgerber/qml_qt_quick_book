// menus.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    visible: true
    width: 350
    height: 300
    title: "Menus and Popups"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        Button {
            id: menuButton
            text: "Open Menu"

            onClicked: contextMenu.popup()
        }

        Menu {
            id: contextMenu

            MenuItem {
                text: "New"
                onTriggered: statusText.text = "New selected"
            }
            MenuItem {
                text: "Open"
                onTriggered: statusText.text = "Open selected"
            }
            MenuSeparator { }
            MenuItem {
                text: "Exit"
                onTriggered: Qt.quit()
            }
        }

        Button {
            id: dialogButton
            text: "Show Dialog"

            onClicked: confirmDialog.open()
        }

        Dialog {
            id: confirmDialog
            title: "Confirm Action"
            standardButtons: Dialog.Ok | Dialog.Cancel
            width: 250

            Text {
                text: "Are you sure?"
            }

            onAccepted: statusText.text = "Confirmed!"
            onRejected: statusText.text = "Cancelled"
        }

        Rectangle {
            color: "#f0f0f0"
            Layout.fillWidth: true
            Layout.preferredHeight: 60
            radius: 4

            Text {
                id: statusText
                anchors.centerIn: parent
                text: "Select a menu item or open dialog"
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true

                ToolTip {
                    visible: parent.containsMouse
                    text: "Hover for tooltip"
                    delay: 500
                }
            }
        }
    }
}