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

    // Row index supplied explicitly by the delegate wrapper in Main.qml.
    // Named delegateIndex (not index) to avoid collision with QML's built-in
    // index context property, which can produce unexpected binding behaviour.
    property int delegateIndex: -1

    // ── sizing ────────────────────────────────────────────────────────────
    height: row.implicitHeight + 20
    width:  ListView.view ? ListView.view.width : 400

    // ── hover highlight ───────────────────────────────────────────────────
    // Hover is NOT tracked inside the delegate.  HoverHandler and MouseArea
    // both fail to maintain stable hover state inside a ListView/Flickable:
    // events are intercepted or the state resets when the Flickable performs
    // its internal layout pass.
    //
    // Instead, the ListView in Main.qml tracks the mouse position via its own
    // HoverHandler and stores hoveredIndex.  Each delegate simply compares its
    // injected `index` context property to that value.
    readonly property bool isHovered: ListView.view !== null
                                      && ListView.view.hoveredIndex === delegateIndex

    Rectangle {
        anchors.fill: parent
        color:        root.isHovered ? "#f5f3ff" : "transparent"
        Behavior on color { ColorAnimation { duration: 120 } }
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
