// NavItem.qml — single row in the sidebar navigation.
// Displays an icon glyph and a text label; toggles selected on click.

import QtQuick
import QtQuick.Layouts

Rectangle {
    id: navItem

    required property string label
    required property string iconChar
    property bool selected: false

    // Always fill the parent ColumnLayout horizontally; without this the
    // Rectangle's implicit width is 0 and the row collapses to nothing.
    Layout.fillWidth: true
    height: 44
    radius: 8
    color:  selected ? Qt.rgba(0.42, 0.23, 0.93, 0.12) : "transparent"

    Behavior on color { ColorAnimation { duration: 120 } }

    RowLayout {
        anchors {
            fill:    parent
            margins: 10
        }
        spacing: 10

        Text {
            text:           navItem.iconChar
            font.pixelSize: 18
            color:          navItem.selected ? "#6c3aec" : "#6b7280"
        }
        Text {
            text:             navItem.label
            font { pixelSize: 14; weight: navItem.selected ? Font.Medium : Font.Normal }
            color:            navItem.selected ? "#6c3aec" : "#374151"
            Layout.fillWidth: true
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape:  Qt.PointingHandCursor
        onClicked:    navItem.selected = !navItem.selected
    }
}
