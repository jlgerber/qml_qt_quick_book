// NavItem.qml — single row in the sidebar navigation.
// Displays an SVG icon and a text label; toggles selected on click.
//
// The icon is a white SVG rendered via Image.  MultiEffect colorization
// tints it to the accent colour (selected) or grey (unselected) at runtime,
// which avoids font-fallback issues that plague emoji-based icons on Linux.

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

Rectangle {
    id: navItem

    required property url    iconSource
    required property string label
    property bool selected:  false
    property bool showLabel: true

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

        // SVG icon — colorized to accent or grey based on selection state.
        // Layout.fillWidth + Image.Pad + AlignHCenter centres the glyph
        // horizontally when the label is hidden (icon-only sidebar mode).
        Image {
            source:             navItem.iconSource
            Layout.preferredWidth:  20
            Layout.preferredHeight: 20
            Layout.fillWidth:   !navItem.showLabel
            // PreserveAspectFit scales the SVG to fit within the item bounds.
            // Image.Pad renders at the raw sourceSize (40 px) regardless of the
            // item size, causing the icon to overflow its 20 px layout slot.
            fillMode:            Image.PreserveAspectFit
            horizontalAlignment: Image.AlignHCenter
            sourceSize:         Qt.size(40, 40)

            layer.enabled: true
            layer.effect: MultiEffect {
                colorization:      1.0
                colorizationColor: navItem.selected ? "#6c3aec" : "#6b7280"
            }
        }

        Text {
            text:             navItem.label
            font { pixelSize: 14; weight: navItem.selected ? Font.Medium : Font.Normal }
            color:            navItem.selected ? "#6c3aec" : "#374151"
            Layout.fillWidth: true
            visible:          navItem.showLabel
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape:  Qt.PointingHandCursor
        onClicked:    navItem.selected = !navItem.selected
    }
}
