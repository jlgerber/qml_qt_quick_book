// DetailScreen.qml — ch07_stack_navigation
// Shows detail content for the selected item.
// Receives `title`, `icon`, and `accentColor` as required properties injected
// by the StackView push call in Main.qml.
// Calls navigationController.back() to return to the previous screen.

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Item {
    id: screen

    // ── Required properties (injected by StackView.push) ─────────────────
    required property string    title
    required property string    icon
    required property string    accentColor
    required property QtObject  navigationController

    Rectangle {
        anchors.fill: parent
        color:        "#f8f7ff"
    }

    ColumnLayout {
        anchors {
            fill:    parent
            margins: 0
        }
        spacing: 0

        // ── Navigation bar ────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height:           56
            color:            "#ffffff"

            Rectangle {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                height: 1
                color:  "#e5e7eb"
            }

            RowLayout {
                anchors {
                    fill:        parent
                    leftMargin:  8
                    rightMargin: 16
                }
                spacing: 4

                // Back button
                Rectangle {
                    width:  40
                    height: 40
                    radius: 20
                    color:  backArea.pressed ? "#f0eeff"
                          : backArea.containsMouse ? "#f5f3ff"
                          : "transparent"

                    Behavior on color { ColorAnimation { duration: 100 } }

                    Text {
                        anchors.centerIn: parent
                        text:  "‹"
                        font { pixelSize: 26; weight: Font.Light }
                        color: screen.accentColor
                    }

                    MouseArea {
                        id:           backArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape:  Qt.PointingHandCursor
                        onClicked:    screen.navigationController.back()
                    }
                }

                Text {
                    text: "Back"
                    font { pixelSize: 16; weight: Font.Normal }
                    color: screen.accentColor
                }

                Item { Layout.fillWidth: true }

                Text {
                    text:  screen.title
                    font { pixelSize: 17; weight: Font.SemiBold }
                    color: "#1a1a2e"
                }

                Item { Layout.fillWidth: true }

                // Balance the back button visually
                Item { width: 88 }
            }
        }

        // ── Hero section ──────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height:           180

            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop {
                    position: 0.0
                    color: Qt.darker(screen.accentColor, 1.1)
                }
                GradientStop {
                    position: 1.0
                    color: Qt.lighter(screen.accentColor, 1.4)
                }
            }

            ColumnLayout {
                anchors.centerIn: parent
                spacing:          8

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text:  screen.icon
                    font.pixelSize: 52
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text:  screen.title
                    font { pixelSize: 22; weight: Font.Bold }
                    color: "#ffffff"
                }
            }
        }

        // ── Content area ──────────────────────────────────────────────────
        ScrollView {
            Layout.fillWidth:  true
            Layout.fillHeight: true
            contentWidth: availableWidth

            ColumnLayout {
                width:   parent.width
                spacing: 12

                Item { height: 8 }

                Repeater {
                    model: 5

                    delegate: Rectangle {
                        required property int index

                        Layout.fillWidth:   true
                        Layout.leftMargin:  16
                        Layout.rightMargin: 16
                        height:             72
                        radius:             10
                        color:              "#ffffff"

                        // Elevation shadow — Qt version compatibility note:
                        //
                        // Current implementation uses a plain offset Rectangle
                        // (works on all Qt 6 versions, no extra imports required).
                        //
                        // To upgrade to a true blurred shadow on Qt ≥ 6.5, remove
                        // the Rectangle below and replace it with:
                        //
                        //   layer.enabled: true
                        //   layer.effect: MultiEffect {
                        //       shadowEnabled:        true
                        //       shadowColor:          Qt.rgba(0, 0, 0, 0.06)
                        //       shadowVerticalOffset: 2
                        //       shadowBlur:           0.6
                        //   }
                        //
                        // On Qt 6.3–6.4, import Qt5Compat.GraphicalEffects and use:
                        //   layer.enabled: true
                        //   layer.effect: DropShadow {
                        //       color:          Qt.rgba(0, 0, 0, 0.06)
                        //       verticalOffset: 2
                        //       radius:         8
                        //       samples:        17
                        //   }
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: -2
                            z: -1
                            radius: parent.radius + 2
                            color: Qt.rgba(0, 0, 0, 0.06)
                            transform: Translate { y: 2 }
                        }

                        RowLayout {
                            anchors {
                                fill:    parent
                                margins: 16
                            }
                            spacing: 12

                            Rectangle {
                                width:  40
                                height: 40
                                radius: 8
                                color:  Qt.rgba(
                                            Qt.color(screen.accentColor).r,
                                            Qt.color(screen.accentColor).g,
                                            Qt.color(screen.accentColor).b,
                                            0.12)

                                Text {
                                    anchors.centerIn: parent
                                    text:  ["📌","📎","🔔","📁","🔗"][index]
                                    font.pixelSize: 18
                                }
                            }

                            Column {
                                Layout.fillWidth: true
                                spacing: 4

                                Text {
                                    text:  screen.title + " — item " + (index + 1)
                                    font { pixelSize: 14; weight: Font.Medium }
                                    color: "#1a1a2e"
                                }

                                Text {
                                    text:  "Placeholder detail row. Replace with real data."
                                    font.pixelSize: 12
                                    color: "#9ca3af"
                                }
                            }
                        }
                    }
                }

                Item { height: 16 }
            }
        }
    }
}
