// Sidebar.qml — collapsible navigation panel with three states:
//
//   expanded  (isExpanded)             220 px — icons + labels
//   normal    (!isCompact, !isExpanded) 56 px — icons only
//   compact   (isCompact)               0 px — hidden
//
// clip:true on the Rectangle hides content during the slide animation without
// a separate opacity animation (which would cause the content to vanish before
// the slide completes).

import QtQuick
import QtQuick.Layouts

Rectangle {
    id: sidebar

    // Supplied by Main.qml — drive the three-state width transition.
    required property bool isCompact
    required property bool isExpanded

    // Use Layout.preferredWidth rather than width: because this item lives
    // inside a RowLayout.  The layout engine owns 'width' on its children;
    // preferredWidth is the correct hook for communicating desired size.
    //
    //   expanded → 220 px (icons + labels)
    //   normal   →  56 px (icons only)
    //   compact  →   0 px (hidden)
    Layout.preferredWidth: isExpanded ? 220 : isCompact ? 0 : 56
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
            // 16 px in expanded mode; 6 px in icon-only mode so that each
            // NavItem is 56 − 12 = 44 px wide — square with its 44 px height.
            margins: sidebar.isExpanded ? 16 : 6
        }
        spacing: 4

        // App brand — hidden in icon-only (normal) mode
        Text {
            text:                "Dashboard"
            font { pixelSize: 18; weight: Font.Bold }
            color:               "#111827"
            Layout.bottomMargin: 16
            visible:             sidebar.isExpanded
        }

        NavItem { iconSource: Qt.resolvedUrl("icons/overview.svg");  label: "Overview";  selected: true; showLabel: sidebar.isExpanded }
        NavItem { iconSource: Qt.resolvedUrl("icons/analytics.svg"); label: "Analytics";               showLabel: sidebar.isExpanded }
        NavItem { iconSource: Qt.resolvedUrl("icons/users.svg");     label: "Users";                   showLabel: sidebar.isExpanded }
        NavItem { iconSource: Qt.resolvedUrl("icons/revenue.svg");   label: "Revenue";                 showLabel: sidebar.isExpanded }
        NavItem { iconSource: Qt.resolvedUrl("icons/settings.svg");  label: "Settings";                showLabel: sidebar.isExpanded }

        Item { Layout.fillHeight: true }

        NavItem { iconSource: Qt.resolvedUrl("icons/signout.svg");   label: "Sign out";                showLabel: sidebar.isExpanded }
    }
}
