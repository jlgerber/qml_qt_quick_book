// HomeScreen.qml — ch07_stack_navigation
// Grid of four app-style cards.  Tapping any card calls
// navigationController.navigateTo("Detail", { title: card.title })
// which tells Main.qml to push DetailScreen onto the StackView.

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects

Item {
    id: screen

    // Injected by Main.qml / StackView push
    required property QtObject navigationController

    // ── App card data ─────────────────────────────────────────────────────
    // Qt.resolvedUrl converts the relative path to an absolute file:// URL
    // at component-creation time so the resolved path travels correctly
    // when the icon is forwarded to DetailScreen via the navigation call.
    readonly property var apps: [
        { title: "Contacts",  icon: Qt.resolvedUrl("icons/contacts.svg"),  color: "#6c3aec", desc: "Manage your address book" },
        { title: "Calendar",  icon: Qt.resolvedUrl("icons/calendar.svg"),  color: "#0ea5e9", desc: "Events & reminders"       },
        { title: "Analytics", icon: Qt.resolvedUrl("icons/analytics.svg"), color: "#10b981", desc: "Usage statistics"         },
        { title: "Settings",  icon: Qt.resolvedUrl("icons/settings.svg"),  color: "#f59e0b", desc: "App preferences"          }
    ]

    // ── Background ────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color:        "#f8f7ff"
    }

    ColumnLayout {
        anchors {
            fill:    parent
            margins: 20
        }
        spacing: 16

        // Title
        Text {
            text: "Home"
            font { pixelSize: 26; weight: Font.Bold }
            color: "#1a1a2e"
        }

        Text {
            text: "Tap a card to navigate to the detail screen."
            font.pixelSize: 14
            color:          "#6b7280"
            Layout.bottomMargin: 4
        }

        // 2-column grid of cards
        GridLayout {
            Layout.fillWidth:  true
            Layout.fillHeight: true
            columns:           2
            columnSpacing:     14
            rowSpacing:        14

            Repeater {
                model: screen.apps

                delegate: Rectangle {
                    required property var modelData
                    required property int index

                    Layout.fillWidth:  true
                    Layout.fillHeight: true
                    radius:            14
                    color:             "#ffffff"

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled:        true
                        shadowColor:          Qt.rgba(0, 0, 0, 0.08)
                        shadowVerticalOffset: 3
                        shadowBlur:           0.7
                    }

                    // Press / hover tint
                    Rectangle {
                        anchors.fill: parent
                        radius:       parent.radius
                        color:        cardArea.pressed ? Qt.rgba(0, 0, 0, 0.06)
                                    : cardArea.containsMouse ? Qt.rgba(0, 0, 0, 0.03)
                                    : "transparent"
                        Behavior on color { ColorAnimation { duration: 100 } }
                    }

                    ColumnLayout {
                        anchors {
                            fill:    parent
                            margins: 20
                        }
                        spacing: 10

                        // Icon badge — solid accent-colour background, white SVG icon
                        Rectangle {
                            width:  52
                            height: 52
                            radius: 14
                            color:  modelData.color

                            Image {
                                anchors.centerIn: parent
                                width:       28
                                height:      28
                                sourceSize:  Qt.size(56, 56)
                                source:      modelData.icon
                                fillMode:    Image.PreserveAspectFit
                            }
                        }

                        Text {
                            text:             modelData.title
                            font { pixelSize: 16; weight: Font.DemiBold }
                            color:            "#1a1a2e"
                            Layout.fillWidth: true
                        }

                        Text {
                            text:             modelData.desc
                            font.pixelSize:   12
                            color:            "#9ca3af"
                            wrapMode:         Text.WordWrap
                            Layout.fillWidth: true
                        }

                        Item { Layout.fillHeight: true }

                        // "Open" pill
                        Rectangle {
                            width:  60
                            height: 26
                            radius: 13
                            color:  modelData.color

                            Text {
                                anchors.centerIn: parent
                                text:  "Open"
                                font { pixelSize: 11; weight: Font.Medium }
                                color: "#ffffff"
                            }
                        }
                    }

                    MouseArea {
                        id:           cardArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape:  Qt.PointingHandCursor

                        onClicked: {
                            screen.navigationController.navigateTo(
                                "Detail",
                                { title: modelData.title, icon: modelData.icon, accentColor: modelData.color }
                            )
                        }
                    }
                }
            }
        }
    }
}
