// Sidebar.qml — collapsible navigation panel shown at the expanded breakpoint.
// Animates its width between 220 px (visible) and 0 (hidden).
// clip:true on the Rectangle hides content during the slide animation without
// a separate opacity animation (which would cause the content to vanish before
// the slide completes).

import QtQuick
import QtQuick.Layouts

Rectangle {
    id: sidebar

    // Supplied by Main.qml — drives the show/hide transition.
    required property bool isExpanded

    // Use Layout.preferredWidth rather than width: because this item lives
    // inside a RowLayout.  The layout engine owns 'width' on its children;
    // preferredWidth is the correct hook for communicating desired size.
    Layout.preferredWidth: isExpanded ? 220 : 0
    Layout.fillHeight:     true

    color: "#ffffff"
    clip:  true

    Behavior on Layout.preferredWidth {
        NumberAnimation { duration: 260; easing.type: Easing.OutCubic }
    }

    // Right-side border
    Rectangle {
        anchors { top: parent.top; bottom: parent.bottom; right: parent.right }
        width: 1
        color: "#e5e7eb"
    }

    ColumnLayout {
        anchors {
            fill:    parent
            margins: 16
        }
        spacing: 4

        // App brand
        Text {
            text:  "Dashboard"
            font { pixelSize: 18; weight: Font.Bold }
            color: "#111827"
            Layout.bottomMargin: 16
        }

        NavItem { label: "Overview";  iconChar: "◉"; selected: true }
        NavItem { label: "Analytics"; iconChar: "📊" }
        NavItem { label: "Users";     iconChar: "👥" }
        NavItem { label: "Revenue";   iconChar: "💰" }
        NavItem { label: "Settings";  iconChar: "⚙"  }

        Item { Layout.fillHeight: true }

        NavItem { label: "Sign out";  iconChar: "⏏" }
    }
}
