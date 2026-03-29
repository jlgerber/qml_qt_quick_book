// TopBar.qml — fixed-height header bar.
// Shows a context-sensitive title and a breakpoint indicator badge.

import QtQuick
import QtQuick.Layouts

Rectangle {
    id: topBar

    required property bool isCompact
    required property bool isExpanded

    Layout.fillWidth: true
    height: 56
    color:  "#ffffff"

    // Bottom border
    Rectangle {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: 1
        color:  "#e5e7eb"
    }

    RowLayout {
        anchors {
            fill:        parent
            leftMargin:  20
            rightMargin: 20
        }

        Text {
            text:  topBar.isCompact  ? "Dashboard"
                 : topBar.isExpanded ? "Overview"
                 :                     "Dashboard — Overview"
            font { pixelSize: 16; weight: Font.DemiBold }
            color: "#111827"
        }

        Item { Layout.fillWidth: true }

        // Breakpoint indicator — handy during development
        Rectangle {
            radius: 4
            color:  topBar.isCompact  ? "#fef3c7"
                  : topBar.isExpanded ? "#d1fae5"
                  :                     "#dbeafe"
            implicitWidth:  bpLabel.implicitWidth  + 12
            implicitHeight: bpLabel.implicitHeight + 6

            Text {
                id: bpLabel
                anchors.centerIn: parent
                text:  topBar.isCompact  ? "compact"
                     : topBar.isExpanded ? "expanded"
                     :                     "normal"
                font { pixelSize: 11; weight: Font.Medium }
                color: topBar.isCompact  ? "#92400e"
                     : topBar.isExpanded ? "#065f46"
                     :                     "#1e40af"
            }
        }
    }
}
