// containers.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    visible: true
    width: 500
    height: 500
    title: "Navigation Example"

    Drawer {
        id: drawer
        width: 200
        height: parent.height
        edge: Qt.LeftEdge

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            Label {
                text: "Menu"
                font.bold: true
                font.pixelSize: 16
            }

            ItemDelegate {
                text: "Home"
                Layout.fillWidth: true
                onClicked: { tabBar.currentIndex = 0; drawer.close() }
            }

            ItemDelegate {
                text: "Settings"
                Layout.fillWidth: true
                onClicked: { tabBar.currentIndex = 1; drawer.close() }
            }

            ItemDelegate {
                text: "About"
                Layout.fillWidth: true
                onClicked: { tabBar.currentIndex = 2; drawer.close() }
            }

            Item { Layout.fillHeight: true }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        ToolBar {
            Layout.fillWidth: true

            RowLayout {
                anchors.fill: parent

                Button {
                    text: "☰"
                    flat: true
                    onClicked: drawer.open()
                }

                Label {
                    text: "App"
                    font.bold: true
                    Layout.fillWidth: true
                }
            }
        }

        TabBar {
            id: tabBar
            Layout.fillWidth: true

            TabButton { text: "Tabs" }
            TabButton { text: "Swipe" }
            TabButton { text: "Stack" }
        }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: tabBar.currentIndex

            // Tabs view
            Rectangle {
                color: "#f0f0f0"
                Label {
                    anchors.centerIn: parent
                    text: "Tab-based Navigation"
                    font.pixelSize: 16
                }
            }

            // SwipeView
            SwipeView {
                currentIndex: 0
                orientation: Qt.Horizontal

                Rectangle {
                    color: "#e8f4f8"
                    Label { anchors.centerIn: parent; text: "Swipe Page 1" }
                }

                Rectangle {
                    color: "#e8e8f8"
                    Label { anchors.centerIn: parent; text: "Swipe Page 2" }
                }

                Rectangle {
                    color: "#f8e8e8"
                    Label { anchors.centerIn: parent; text: "Swipe Page 3" }
                }
            }

            // StackView
            StackView {
                id: stack
                Layout.fillWidth: true
                Layout.fillHeight: true
                initialItem: stackHomePage

                Component {
                    id: stackHomePage
                    Rectangle {
                        color: "#f4e8e8"
                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 12

                            Label {
                                text: "Stack-based Navigation"
                                font.pixelSize: 16
                            }

                            Button {
                                text: "Go to Details"
                                onClicked: stack.push(stackDetailsPage)
                            }
                        }
                    }
                }

                Component {
                    id: stackDetailsPage
                    Rectangle {
                        color: "#e8f4e8"
                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 12

                            Label {
                                text: "Details Page"
                                font.pixelSize: 16
                            }

                            Button {
                                text: "Go Back"
                                onClicked: stack.pop()
                            }
                        }
                    }
                }
            }
        }
    }
}