// Main.qml — ch05_responsive_layout
// Demonstrates a responsive layout that adapts to three breakpoints:
//
//   compact   width < 600   → single-column stacked cards (ColumnLayout)
//   normal    600–999       → two-column grid of cards, no sidebar
//   expanded  width >= 1000 → fixed sidebar (220 px) + scrollable content area
//
// Resize the window to see the layout adapt in real time.
//
// Component files in this directory:
//   Sidebar.qml    — animated collapsible left-navigation panel
//   TopBar.qml     — fixed-height header with title and breakpoint badge
//   MetricCard.qml — individual metric tile (title, value, trend, subtitle)
//   NavItem.qml    — single navigation row used by Sidebar
//
// Run with:
//   qml Main.qml

pragma ComponentBehavior: Bound

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

    // ── root layout ───────────────────────────────────────────────────────
    RowLayout {
        anchors.fill: parent
        spacing:      0

        // ── Sidebar ───────────────────────────────────────────────────────
        Sidebar {
            isCompact:  root.isCompact
            isExpanded: root.isExpanded
        }

        // ── Main content area ─────────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth:  true
            Layout.fillHeight: true
            spacing:           0

            // Top bar
            TopBar {
                isCompact:  root.isCompact
                isExpanded: root.isExpanded
            }

            // Scrollable card area
            ScrollView {
                Layout.fillWidth:  true
                Layout.fillHeight: true
                contentWidth:      availableWidth   // disable horizontal scroll

                // Cards arranged in a layout that reacts to breakpoints
                Loader {
                    width: parent.width

                    // Swap between a ColumnLayout (compact) and a GridLayout
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
                                Layout.fillWidth:   true
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
                        width:         parent ? parent.width : 0
                        columns:       root.isExpanded ? 3 : 2
                        columnSpacing: 16
                        rowSpacing:    16

                        // padding via a full-span spacer row
                        Item {
                            Layout.columnSpan: root.isExpanded ? 3 : 2
                            Layout.fillWidth:  true
                            height: 16
                        }

                        Repeater {
                            model: cardModel
                            // No required property re-declarations here: MetricCard
                            // already defines them, and pragma ComponentBehavior: Bound
                            // makes the Repeater inject matching model roles into those
                            // existing required properties automatically.
                            // Re-declaring them creates duplicate required properties
                            // that the Repeater cannot satisfy, causing a delegate error.
                            delegate: MetricCard {
                                // index is a Repeater context property.  With
                                // ComponentBehavior: Bound it must be explicitly
                                // declared to be accessible inside the delegate.
                                required property int index

                                Layout.fillWidth:   true
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
