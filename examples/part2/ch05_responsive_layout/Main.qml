// Main.qml — ch05_responsive_layout
// Demonstrates a responsive layout that adapts to three breakpoints:
//
//   compact   width < 600   → single-column stacked cards (ColumnLayout)
//   normal    600–999       → two-column grid of cards, no sidebar
//   expanded  width >= 1000 → fixed sidebar (220 px) + scrollable content area
//
// Resize the window to see the layout adapt in real time.
//
// Run with:
//   qml Main.qml

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id:      root
    title:   "Chapter 5 – Responsive Layout"
    width:   1024
    height:  700
    visible: true

    // ── breakpoint properties ─────────────────────────────────────────────
    readonly property bool isCompact:  width <  600
    readonly property bool isExpanded: width >= 1000

    background: Rectangle { color: "#f0f2f5" }

    // ── card data model ───────────────────────────────────────────────────
    ListModel {
        id: cardModel
        ListElement { cardTitle: "Analytics";    subtitle: "Traffic & conversions";   value: "12,480"; trend: "+8%" }
        ListElement { cardTitle: "Revenue";      subtitle: "Monthly recurring";       value: "$4,290"; trend: "+3%" }
        ListElement { cardTitle: "New Users";    subtitle: "Registrations this week"; value: "342";    trend: "+21%" }
        ListElement { cardTitle: "Support";      subtitle: "Open tickets";            value: "17";     trend: "-4%" }
        ListElement { cardTitle: "Performance";  subtitle: "Avg. response time";      value: "142 ms"; trend: "-12%" }
        ListElement { cardTitle: "Storage";      subtitle: "Used capacity";           value: "68 %";   trend: "+1%" }
    }

    // ── reusable card component ───────────────────────────────────────────
    component MetricCard: Rectangle {
        id: card

        required property string cardTitle
        required property string subtitle
        required property string value
        required property string trend

        readonly property bool positive: trend.startsWith("+")

        radius:  10
        color:   "#ffffff"
        // Simple programmatic shadow via a behind rectangle
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled:           true
            shadowColor:             Qt.rgba(0, 0, 0, 0.08)
            shadowVerticalOffset:    2
            shadowHorizontalOffset:  0
            shadowBlur:              0.7
        }

        implicitHeight: formGrid.implicitHeight + 24
        implicitWidth:  200

        GridLayout {
            id: formGrid
            anchors {
                left:    parent.left
                right:   parent.right
                top:     parent.top
                margins: 16
            }
            columns:      2
            columnSpacing: 8
            rowSpacing:    4

            // Row 0 — title spanning both columns
            Text {
                text:              card.cardTitle
                font { pixelSize: 13; weight: Font.Medium }
                color:             "#6b7280"
                Layout.columnSpan: 2
            }

            // Row 1 — big value + trend badge
            Text {
                text:             card.value
                font { pixelSize: 26; weight: Font.Bold }
                color:            "#111827"
                Layout.fillWidth: true
            }

            Rectangle {
                radius: 4
                color:  card.positive ? Qt.rgba(0.06, 0.73, 0.44, 0.12)
                                      : Qt.rgba(0.94, 0.27, 0.27, 0.12)
                implicitWidth:  trendLabel.implicitWidth  + 10
                implicitHeight: trendLabel.implicitHeight + 6

                Text {
                    id: trendLabel
                    anchors.centerIn: parent
                    text:  card.trend
                    font { pixelSize: 12; weight: Font.Medium }
                    color: card.positive ? "#10b981" : "#ef4444"
                }
            }

            // Row 2 — subtitle
            Text {
                text:              card.subtitle
                font.pixelSize:    12
                color:             "#9ca3af"
                Layout.columnSpan: 2
            }
        }
    }

    // ── sidebar nav item ──────────────────────────────────────────────────
    component NavItem: Rectangle {
        id: navItem
        required property string label
        required property string iconChar
        property bool  selected: false

        height:  44
        radius:   8
        color:    selected ? Qt.rgba(0.42, 0.23, 0.93, 0.12) : "transparent"

        RowLayout {
            anchors {
                fill:    parent
                margins: 10
            }
            spacing: 10

            Text {
                text:          navItem.iconChar
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

    // ── root layout ───────────────────────────────────────────────────────
    RowLayout {
        anchors.fill: parent
        spacing:      0

        // ── Sidebar (expanded breakpoint only) ────────────────────────────
        Rectangle {
            id: sidebar

            // Animated width: 220 when visible, 0 when hidden
            width: root.isExpanded ? 220 : 0
            Layout.fillHeight: true

            color:   "#ffffff"
            clip:    true   // hide content while animating

            // Border on the right side
            Rectangle {
                anchors { top: parent.top; bottom: parent.bottom; right: parent.right }
                width: 1
                color: "#e5e7eb"
            }

            Behavior on width {
                NumberAnimation { duration: 260; easing.type: Easing.OutCubic }
            }

            // Sidebar content (only rendered when wide enough to matter)
            ColumnLayout {
                anchors {
                    fill:    parent
                    margins: 16
                }
                spacing: 4
                opacity: root.isExpanded ? 1 : 0

                Behavior on opacity {
                    NumberAnimation { duration: 200 }
                }

                // App brand
                Text {
                    text: "Dashboard"
                    font { pixelSize: 18; weight: Font.Bold }
                    color: "#111827"
                    Layout.bottomMargin: 16
                }

                NavItem { label: "Overview";   iconChar: "◉"; selected: true }
                NavItem { label: "Analytics";  iconChar: "📊" }
                NavItem { label: "Users";      iconChar: "👥" }
                NavItem { label: "Revenue";    iconChar: "💰" }
                NavItem { label: "Settings";   iconChar: "⚙" }

                Item { Layout.fillHeight: true }

                NavItem { label: "Sign out";   iconChar: "⏏" }
            }
        }

        // ── Main content area ─────────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth:  true
            Layout.fillHeight: true
            spacing:           0

            // Top bar
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
                        fill:             parent
                        leftMargin:       20
                        rightMargin:      20
                    }

                    Text {
                        text:  root.isCompact  ? "Dashboard"
                             : root.isExpanded ? "Overview"
                             :                   "Dashboard — Overview"
                        font { pixelSize: 16; weight: Font.SemiBold }
                        color: "#111827"
                    }

                    Item { Layout.fillWidth: true }

                    // Breakpoint indicator (handy during development)
                    Rectangle {
                        radius: 4
                        color:  root.isCompact  ? "#fef3c7"
                              : root.isExpanded ? "#d1fae5"
                              :                   "#dbeafe"
                        implicitWidth:  bpLabel.implicitWidth  + 12
                        implicitHeight: bpLabel.implicitHeight + 6

                        Text {
                            id: bpLabel
                            anchors.centerIn: parent
                            text:  root.isCompact  ? "compact"
                                 : root.isExpanded ? "expanded"
                                 :                   "normal"
                            font { pixelSize: 11; weight: Font.Medium }
                            color: root.isCompact  ? "#92400e"
                                 : root.isExpanded ? "#065f46"
                                 :                   "#1e40af"
                        }
                    }
                }
            }

            // Scrollable card area
            ScrollView {
                Layout.fillWidth:  true
                Layout.fillHeight: true
                contentWidth:      availableWidth   // disable horizontal scroll

                // Cards arranged in a layout that reacts to breakpoints
                Loader {
                    width: parent.width

                    // Swap between a ColumnLayout (compact) and a Flow/GridLayout
                    sourceComponent: root.isCompact ? compactCards : wideCards

                    Behavior on opacity { NumberAnimation { duration: 160 } }
                }

                // ── compact: stacked full-width cards ─────────────────────
                Component {
                    id: compactCards

                    ColumnLayout {
                        width:   parent ? parent.width : 0
                        spacing: 12

                        Item { height: 16 }   // top padding

                        Repeater {
                            model: cardModel
                            delegate: MetricCard {
                                required property string cardTitle
                                required property string subtitle
                                required property string value
                                required property string trend

                                Layout.fillWidth: true
                                Layout.leftMargin:  16
                                Layout.rightMargin: 16
                            }
                        }

                        Item { height: 16 }   // bottom padding
                    }
                }

                // ── normal / expanded: grid of cards ──────────────────────
                Component {
                    id: wideCards

                    GridLayout {
                        width:        parent ? parent.width : 0
                        columns:      root.isExpanded ? 3 : 2
                        columnSpacing: 16
                        rowSpacing:    16

                        // padding via anchors
                        Item {
                            Layout.columnSpan: root.isExpanded ? 3 : 2
                            Layout.fillWidth: true
                            height: 16
                        }

                        Repeater {
                            model: cardModel
                            delegate: MetricCard {
                                required property string cardTitle
                                required property string subtitle
                                required property string value
                                required property string trend

                                Layout.fillWidth:  true
                                Layout.leftMargin:  index % (root.isExpanded ? 3 : 2) === 0 ? 20 : 0
                                Layout.rightMargin: (index + 1) % (root.isExpanded ? 3 : 2) === 0 ? 20 : 0
                            }
                        }

                        Item {
                            Layout.columnSpan: root.isExpanded ? 3 : 2
                            height: 20
                        }
                    }
                }
            }
        }
    }
}
