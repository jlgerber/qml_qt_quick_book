// containers.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    visible: true
    width: 400
    height: 500
    title: "Navigation Example"

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        TabBar {
            id: tabBar
            Layout.fillWidth: true

            TabButton {
                text: "Home"
            }
            TabButton {
                text: "Settings"
            }
            TabButton {
                text: "About"
            }
        }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: tabBar.currentIndex

            // Home tab
            Rectangle {
                color: "#f0f0f0"
                Text {
                    anchors.centerIn: parent
                    text: "Welcome to Home"
                    font.pixelSize: 18
                }
            }

            // Settings tab
            Rectangle {
                color: "#e8f4f8"
                Text {
                    anchors.centerIn: parent
                    text: "Settings go here"
                    font.pixelSize: 18
                }
            }

            // About tab
            Rectangle {
                color: "#f4e8e8"
                Text {
                    anchors.centerIn: parent
                    text: "About this app"
                    font.pixelSize: 18
                }
            }
        }
    }
}