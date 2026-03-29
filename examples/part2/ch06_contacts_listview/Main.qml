// Main.qml — ch06_contacts_listview
// Demonstrates ListView with:
//   • Section headers (grouped by first letter of surname)
//   • Search / filter via JavaScript (replaces model binding)
//   • ScrollBar overlay
//   • ContactDelegate as a reusable component
//
// Run with:
//   qml Main.qml

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id:      root
    title:   "Chapter 6 – Contacts ListView"
    width:   420
    height:  680
    visible: true

    background: Rectangle { color: "#f8f7ff" }

    // ── Full contact list ─────────────────────────────────────────────────
    // Each entry carries an `initials`, `fullName`, `email`, `avatarColor`,
    // and `section` (first letter used as section group).
    readonly property var allContacts: [
        { initials: "AB", fullName: "Alice Brown",    email: "alice@example.com",   avatarColor: "#6c3aec", section: "B" },
        { initials: "BC", fullName: "Bob Carter",     email: "bob@example.com",     avatarColor: "#0ea5e9", section: "C" },
        { initials: "CD", fullName: "Carol Davis",    email: "carol@example.com",   avatarColor: "#10b981", section: "D" },
        { initials: "DE", fullName: "David Evans",    email: "david@example.com",   avatarColor: "#f59e0b", section: "E" },
        { initials: "EF", fullName: "Eva Foster",     email: "eva@example.com",     avatarColor: "#ef4444", section: "F" },
        { initials: "FG", fullName: "Frank Garcia",   email: "frank@example.com",   avatarColor: "#8b5cf6", section: "G" },
        { initials: "GH", fullName: "Grace Harris",   email: "grace@example.com",   avatarColor: "#ec4899", section: "H" },
        { initials: "HI", fullName: "Henry Ingram",   email: "henry@example.com",   avatarColor: "#14b8a6", section: "I" }
    ]

    // ── Filtered list (updated by search field) ───────────────────────────
    property var filteredContacts: root.allContacts

    function applyFilter(query) {
        if (!query || query.trim() === "") {
            filteredContacts = allContacts
            return
        }
        const q = query.trim().toLowerCase()
        filteredContacts = allContacts.filter(function(c) {
            return c.fullName.toLowerCase().indexOf(q) !== -1
                || c.email.toLowerCase().indexOf(q) !== -1
        })
    }

    // ── Layout ────────────────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        spacing:      0

        // ── Header / search bar ───────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height:           100
            color:            "#ffffff"

            // Bottom border
            Rectangle {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                height: 1
                color:  "#e5e7eb"
            }

            ColumnLayout {
                anchors {
                    fill:    parent
                    margins: 16
                }
                spacing: 10

                Text {
                    text: "Contacts"
                    font { pixelSize: 22; weight: Font.Bold }
                    color: "#1a1a2e"
                }

                // Search field (plain TextInput wrapped in a styled Rectangle)
                Rectangle {
                    Layout.fillWidth: true
                    height:           38
                    radius:           19
                    color:            "#f3f4f6"
                    border { width: 1; color: searchInput.activeFocus ? "#6c3aec" : "transparent" }

                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    RowLayout {
                        anchors {
                            fill:    parent
                            leftMargin:  12
                            rightMargin: 12
                        }
                        spacing: 8

                        Text {
                            text:  "🔍"
                            font.pixelSize: 14
                            color: "#9ca3af"
                        }

                        TextInput {
                            id:               searchInput
                            Layout.fillWidth: true
                            font.pixelSize:   14
                            color:            "#1a1a2e"
                            clip:             true

                            onTextChanged: root.applyFilter(text)

                            Text {
                                anchors.fill:  parent
                                text:         "Search contacts…"
                                font:          searchInput.font
                                color:        "#9ca3af"
                                visible:      !searchInput.text && !searchInput.activeFocus
                            }
                        }

                        // Clear button
                        Text {
                            text:    "✕"
                            font.pixelSize: 13
                            color:   "#9ca3af"
                            visible: searchInput.text.length > 0

                            MouseArea {
                                anchors.fill: parent
                                onClicked:    searchInput.text = ""
                            }
                        }
                    }
                }
            }
        }

        // ── Contact list ──────────────────────────────────────────────────
        Item {
            Layout.fillWidth:  true
            Layout.fillHeight: true

            ListView {
                id:           contactList
                anchors.fill: parent
                clip:         true
                spacing:      0

                model:        root.filteredContacts

                // Section configuration
                section.property:  "section"
                section.criteria:  ViewSection.FullString

                section.delegate: Rectangle {
                    required property string section

                    width:  ListView.view.width
                    height: 28
                    color:  "#f0eeff"
                    z:      2   // float above delegates (sticky behaviour)

                    Text {
                        anchors {
                            left:           parent.left
                            verticalCenter: parent.verticalCenter
                            leftMargin:     16
                        }
                        text:  section
                        font { pixelSize: 12; weight: Font.Bold; letterSpacing: 1.5 }
                        color: "#6c3aec"
                    }
                }

                delegate: ContactDelegate {
                    // Map JS object properties to required properties
                    required property var modelData

                    initials:    modelData.initials
                    fullName:    modelData.fullName
                    email:       modelData.email
                    avatarColor: modelData.avatarColor
                }

                // Empty state
                Text {
                    anchors.centerIn: parent
                    text:    "No contacts match your search."
                    font.pixelSize: 15
                    color:   "#9ca3af"
                    visible: contactList.count === 0
                }

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }
            }
        }
    }
}
