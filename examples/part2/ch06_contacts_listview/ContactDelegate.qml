// ContactDelegate.qml — ch06_contacts_listview
// Reusable delegate that renders a single contact row.
// All data arrives via required properties so the delegate is
// self-contained and safe with ListView's required-property model API.

import QtQuick
import QtQuick.Layouts

Item {
    id: root

    // ── required model fields ─────────────────────────────────────────────
    required property string initials
    required property string fullName
    required property string email
    required property string avatarColor

    // ── sizing ────────────────────────────────────────────────────────────
    height: row.implicitHeight + 20
    width:  ListView.view ? ListView.view.width : 400

    // ── hover highlight ───────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color:        hoverArea.containsMouse ? "#f5f3ff" : "transparent"
        Behavior on color { ColorAnimation { duration: 120 } }
    }

    MouseArea {
        id:          hoverArea
        anchors.fill: parent
        hoverEnabled: true
    }

    // Thin bottom separator
    Rectangle {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: 1
        color:  "#f0f0f6"
    }

    RowLayout {
        id: row

        anchors {
            left:    parent.left
            right:   parent.right
            verticalCenter: parent.verticalCenter
            leftMargin:  16
            rightMargin: 16
        }

        spacing: 14

        // ── Avatar circle ─────────────────────────────────────────────────
        Rectangle {
            width:  44
            height: 44
            radius: 22
            color:  root.avatarColor

            Text {
                anchors.centerIn: parent
                text:  root.initials
                font { pixelSize: 15; weight: Font.Medium }
                color: "#ffffff"
            }
        }

        // ── Name + email column ───────────────────────────────────────────
        Column {
            spacing: 3
            Layout.fillWidth: true

            Text {
                text:             root.fullName
                font { pixelSize: 15; weight: Font.Medium }
                color:            "#1a1a2e"
                elide:            Text.ElideRight
                width:            parent.width
            }

            Text {
                text:          root.email
                font.pixelSize: 13
                color:         "#6b7280"
                elide:         Text.ElideRight
                width:         parent.width
            }
        }

        // ── Chevron ───────────────────────────────────────────────────────
        Text {
            text:  "›"
            font.pixelSize: 20
            color: "#d1d5db"
        }
    }
}
