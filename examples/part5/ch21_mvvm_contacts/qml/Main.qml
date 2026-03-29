// Main.qml — Chapter 21: MVVM Contacts Application
// --------------------------------------------------
// Root ApplicationWindow.  Receives the `vm` context property
// (ContactListViewModel) injected from main.py via setInitialProperties.
//
// Layout:
//   ┌─────────────────────────────────┐
//   │  Header (title + search bar)    │
//   ├─────────────────────────────────┤
//   │  StackLayout                    │
//   │    [0] LoadingSpinner           │
//   │    [1] EmptyState               │
//   │    [2] ContactListView          │
//   └────────────────────┬────────────┘
//                        │  FAB (+)
//                        └──────────────> AddContactDialog

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

ApplicationWindow {
    id: root

    // `vm` is injected by Python via engine.setInitialProperties
    required property var vm

    visible: true
    width:   400
    height:  680
    title:   "Contacts"

    Material.theme:  Material.Dark
    Material.accent: Material.Purple

    // ------------------------------------------------------------------ //
    // Header
    // ------------------------------------------------------------------ //
    header: ToolBar {
        ColumnLayout {
            anchors {
                fill:           parent
                leftMargin:     12
                rightMargin:    12
                topMargin:       6
                bottomMargin:    6
            }
            spacing: 4

            Label {
                text:           "Contacts"
                font {
                    pixelSize: 20
                    bold:      true
                }
                color: "white"
            }

            // ── Search bar ────────────────────────────────────────────
            TextField {
                id:               searchField
                Layout.fillWidth: true
                placeholderText:  "Search by name, email or phone…"
                text:             root.vm.searchQuery

                leftInset:  0
                rightInset: 0
                topInset:   0
                bottomInset: 0

                background: Rectangle {
                    color:  "#40FFFFFF"
                    radius: 6
                }

                color:            "white"
                placeholderTextColor: "#AAFFFFFF"

                onTextEdited: root.vm.searchQuery = text

                // Sync back if viewmodel changes searchQuery from code
                Connections {
                    target: root.vm
                    function onSearchQueryChanged() {
                        if (searchField.text !== root.vm.searchQuery)
                            searchField.text = root.vm.searchQuery;
                    }
                }
            }
        }
    }

    // ------------------------------------------------------------------ //
    // Main content — stack-switches between loading / empty / list states
    // ------------------------------------------------------------------ //
    StackLayout {
        id: contentStack
        anchors {
            fill:           parent
            bottomMargin:   72   // leave room for the FAB
        }

        // 0 = loading, 1 = empty, 2 = list
        currentIndex: root.vm.loading ? 0
                    : root.vm.isEmpty ? 1
                    :                   2

        // ── [0] Loading indicator ─────────────────────────────────────
        Item {
            BusyIndicator {
                anchors.centerIn: parent
                running:          root.vm.loading
            }
        }

        // ── [1] Empty state ───────────────────────────────────────────
        Item {
            ColumnLayout {
                anchors.centerIn: parent
                spacing:          12

                Label {
                    text:             "No contacts found"
                    font.pixelSize:   18
                    opacity:          0.6
                    Layout.alignment: Qt.AlignHCenter
                }

                Label {
                    text:             root.vm.searchQuery.length > 0
                                      ? "Try a different search term."
                                      : "Tap + to add your first contact."
                    font.pixelSize:   14
                    opacity:          0.4
                    wrapMode:         Text.Wrap
                    Layout.maximumWidth: 260
                    Layout.alignment: Qt.AlignHCenter
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }

        // ── [2] Contact list ──────────────────────────────────────────
        ContactListView {
            viewModel: root.vm
        }
    }

    // ------------------------------------------------------------------ //
    // Floating Action Button
    // ------------------------------------------------------------------ //
    RoundButton {
        id:   fab
        text: "+"
        font.pixelSize: 24
        width:  56
        height: 56

        anchors {
            right:         parent.right
            bottom:        parent.bottom
            rightMargin:   16
            bottomMargin:  16
        }

        Material.background: Material.Purple
        Material.foreground: "white"

        onClicked: addDialog.open()
    }

    // ------------------------------------------------------------------ //
    // Add-contact dialog
    // ------------------------------------------------------------------ //
    AddContactDialog {
        id:        addDialog
        viewModel: root.vm
    }
}
