// ContactListView.qml — Scrollable list of contacts
// --------------------------------------------------
// Expects a `viewModel` property (ContactListViewModel).
// Each row shows:
//   • Coloured avatar circle with the contact's initials
//   • Name (primary text) + email (secondary text)
//   • SwipeDelegate with a red delete action on the right

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

ListView {
    id: root

    // Injected from Main.qml
    required property var viewModel

    clip:     true
    spacing:  0

    model: root.viewModel.contacts

    ScrollBar.vertical: ScrollBar {}

    // ------------------------------------------------------------------
    // Section header — group by first letter of name
    // ------------------------------------------------------------------
    section.property:  "name"
    section.criteria:  ViewSection.FirstCharacter
    section.delegate: Rectangle {
        width:  root.width
        height: 28
        color:  "#22FFFFFF"

        required property string section

        Label {
            anchors {
                verticalCenter: parent.verticalCenter
                left:           parent.left
                leftMargin:     16
            }
            text:           section
            font {
                pixelSize: 11
                bold:      true
                capitalization: Font.AllUppercase
            }
            color: Material.accentColor
        }
    }

    // ------------------------------------------------------------------
    // Delegate
    // ------------------------------------------------------------------
    delegate: SwipeDelegate {
        id: delegate

        required property string contactId
        required property string name
        required property string email
        required property string phone
        required property int    index

        width:  root.width
        height: 72

        // Prevent the swipe action from fighting with ListView scrolling
        swipe.enabled: true

        // ── Right swipe → delete action ────────────────────────────
        swipe.right: Rectangle {
            width:   parent.width
            height:  parent.height
            color:   Material.color(Material.Red)
            anchors.right: parent.right

            RowLayout {
                anchors {
                    right:         parent.right
                    rightMargin:   16
                    verticalCenter: parent.verticalCenter
                }
                spacing: 8

                Label {
                    text:           "Delete"
                    color:          "white"
                    font.pixelSize: 14
                }
            }

            // Tapping anywhere in the revealed area confirms deletion
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    delegate.swipe.close();
                    root.viewModel.removeContact(delegate.contactId);
                }
            }
        }

        // ── Main content ────────────────────────────────────────────
        contentItem: RowLayout {
            spacing: 12

            // Avatar circle
            Rectangle {
                width:   44
                height:  44
                radius:  22
                color:   avatarColor(delegate.name)

                Label {
                    anchors.centerIn: parent
                    text:             initials(delegate.name)
                    color:            "white"
                    font {
                        pixelSize: 16
                        bold:      true
                    }
                }
            }

            // Text column
            ColumnLayout {
                Layout.fillWidth: true
                spacing:          2

                Label {
                    text:           delegate.name
                    font.pixelSize: 15
                    color:          "#E1E1E1"
                    elide:          Text.ElideRight
                    Layout.fillWidth: true
                }

                Label {
                    text:           delegate.email || delegate.phone
                    font.pixelSize: 12
                    color:          "#999999"
                    elide:          Text.ElideRight
                    Layout.fillWidth: true
                }
            }
        }

        background: Rectangle {
            color: delegate.SwipeDelegate.pressed ? "#22FFFFFF" : "transparent"
        }

        // Thin divider between rows
        Rectangle {
            anchors {
                bottom: parent.bottom
                left:   parent.left
                right:  parent.right
                leftMargin: 72
            }
            height: 1
            color:  "#1EFFFFFF"
            visible: delegate.index < root.count - 1
        }
    }

    // ------------------------------------------------------------------
    // Helper functions
    // ------------------------------------------------------------------

    function initials(fullName: string): string {
        if (!fullName) return "?";
        const parts = fullName.trim().split(/\s+/);
        if (parts.length === 1) return parts[0][0].toUpperCase();
        return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
    }

    // Deterministic colour from a name string
    function avatarColor(name: string): color {
        const palette = [
            "#E57373", "#F06292", "#BA68C8", "#9575CD",
            "#7986CB", "#64B5F6", "#4DD0E1", "#4DB6AC",
            "#81C784", "#AED581", "#FFD54F", "#FF8A65",
        ];
        let hash = 0;
        for (let i = 0; i < name.length; i++)
            hash = (hash * 31 + name.charCodeAt(i)) & 0xFFFFFF;
        return palette[Math.abs(hash) % palette.length];
    }
}
