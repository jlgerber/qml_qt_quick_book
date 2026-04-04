// menus.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    visible: true
    width: 400
    height: 400
    title: "Menus and Popups"

    menuBar: MenuBar {
        Menu {
            title: "File"
            MenuItem {
                text: "New"
                onTriggered: statusText.text = "File > New"
            }
            MenuItem {
                text: "Open"
                onTriggered: statusText.text = "File > Open"
            }
            MenuSeparator { }
            MenuItem {
                text: "Exit"
                onTriggered: Qt.quit()
            }
        }

        Menu {
            title: "Edit"
            MenuItem {
                text: "Undo"
                onTriggered: statusText.text = "Edit > Undo"
            }
            MenuItem {
                text: "Redo"
                onTriggered: statusText.text = "Edit > Redo"
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        Button {
            id: menuButton
            text: "Open Context Menu"

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
                text: "Delete"
                onTriggered: statusText.text = "Delete selected"
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

            Label {
                id: statusText
                anchors.centerIn: parent
                text: "Try the MenuBar, context menu, or dialog"
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