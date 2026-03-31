// Chapter 11 – Contact Model
// ListView over a QAbstractListModel with add-form and swipe-to-delete.

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: root
    title: "Contacts"
    width: 500
    height: 640
    visible: true

    // contactModel is injected via engine.setInitialProperties().
    // Declare it as a required property so QML knows the type at load time.
    required property var contactModel

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ----------------------------------------------------------------
        // Contact list
        // ----------------------------------------------------------------
        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: root.contactModel

            // Thin divider between delegates
            section.property: ""   // no sectioning – just visual separator

            delegate: SwipeDelegate {
                id: swipeDelegate
                width: listView.width
                padding: 0

                // Main content
                contentItem: Item {
                    implicitHeight: contactCol.implicitHeight + 20
                    ColumnLayout {
                        id: contactCol
                        spacing: 2
                        anchors {
                            left: parent.left
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                            leftMargin: 16
                            rightMargin: 16
                        }

                        Label {
                            text: model.name
                            font.bold: true
                            font.pixelSize: 15
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        Label {
                            text: model.email
                            font.pixelSize: 12
                            color: "#555"
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        Label {
                            text: model.phone
                            font.pixelSize: 12
                            color: "#555"
                            Layout.fillWidth: true
                        }
                    }
                }

                // Swipe-to-delete: reveal a red Delete button on the right.
                swipe.right: Rectangle {
                    color: swipeDelegate.swipe.complete ? "#cc3333" : "#e57373"
                    width: parent.width
                    height: parent.height
                    anchors.right: parent.right

                    Label {
                        anchors.centerIn: parent
                        text: "Delete"
                        color: "white"
                        font.bold: true
                    }

                    // Remove the row as soon as the swipe is fully open.
                    SwipeDelegate.onClicked: {
                        root.contactModel.removeContact(index)
                    }
                }

                Rectangle {
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                    height: 1
                    color: "#e0e0e0"
                }
            }

            Label {
                anchors.centerIn: parent
                visible: listView.count === 0
                text: "No contacts yet.\nAdd one below."
                horizontalAlignment: Text.AlignHCenter
                color: "#888"
            }
        }

        // ----------------------------------------------------------------
        // Add-contact form
        // ----------------------------------------------------------------
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: formLayout.implicitHeight + 24
            color: "#555555"
            border.color: "#ddd"
            border.width: 1

            ColumnLayout {
                id: formLayout
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 12
                }
                spacing: 8

                Label {
                    text: "Add Contact"
                    font.bold: true
                }

                TextField {
                    id: nameField
                    Layout.fillWidth: true
                    placeholderText: "Full name"
                }
                TextField {
                    id: emailField
                    Layout.fillWidth: true
                    placeholderText: "Email address"
                    inputMethodHints: Qt.ImhEmailCharactersOnly
                }
                TextField {
                    id: phoneField
                    Layout.fillWidth: true
                    placeholderText: "Phone number"
                    inputMethodHints: Qt.ImhDialableCharactersOnly
                }

                RowLayout {
                    spacing: 8

                    Button {
                        text: "Add"
                        enabled: nameField.text.trim().length > 0
                        onClicked: {
                            root.contactModel.addContact(
                                nameField.text.trim(),
                                emailField.text.trim(),
                                phoneField.text.trim()
                            )
                            nameField.clear()
                            emailField.clear()
                            phoneField.clear()
                            listView.positionViewAtEnd()
                        }
                    }

                    Button {
                        text: "Clear All"
                        onClicked: root.contactModel.clear()
                    }
                }
            }
        }
    }
}
