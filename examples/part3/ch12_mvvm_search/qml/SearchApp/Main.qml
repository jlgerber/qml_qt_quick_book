// Chapter 12 – MVVM Search
// Search UI bound entirely to the SearchViewModel; no business logic here.

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: root
    title: "Qt Topic Search"
    width: 540
    height: 620
    visible: true

    // Injected from Python via engine.setInitialProperties().
    required property var vm

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // ----------------------------------------------------------------
        // Search bar
        // ----------------------------------------------------------------
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            TextField {
                id: searchField
                Layout.fillWidth: true
                placeholderText: "Search Qt topics…"
                // Two-way binding: QML ↔ vm.query
                text: root.vm.query
                onTextChanged: root.vm.query = text
                Keys.onReturnPressed: root.vm.performSearch()
                Keys.onEnterPressed:  root.vm.performSearch()
            }

            Button {
                text: "Search"
                enabled: !root.vm.searching && searchField.text.trim().length > 0
                onClicked: root.vm.performSearch()
            }

            Button {
                text: "Clear"
                enabled: searchField.text.length > 0 || root.vm.resultCount > 0
                onClicked: root.vm.clearSearch()
            }
        }

        // ----------------------------------------------------------------
        // Status bar: result count + busy indicator
        // ----------------------------------------------------------------
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            visible: root.vm.searching || root.vm.resultCount > 0

            BusyIndicator {
                running: root.vm.searching
                implicitWidth: 24
                implicitHeight: 24
                visible: root.vm.searching
            }

            Label {
                visible: !root.vm.searching && root.vm.resultCount > 0
                text: root.vm.resultCount + " result" +
                      (root.vm.resultCount === 1 ? "" : "s") + " found"
                font.italic: true
                color: "#555"
            }

            Label {
                visible: root.vm.searching
                text: "Searching…"
                font.italic: true
                color: "#555"
            }
        }

        // ----------------------------------------------------------------
        // Results list
        // ----------------------------------------------------------------
        ListView {
            id: resultsList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: root.vm.results
            spacing: 8

            delegate: Pane {
                width: resultsList.width
                padding: 12
                background: Rectangle {
                    color: "#fafafa"
                    border.color: "#ddd"
                    radius: 4
                }

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true

                        Label {
                            text: model.title
                            font.bold: true
                            font.pixelSize: 15
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Label {
                            text: model.score
                            font.pixelSize: 12
                            color: "#1976D2"
                            font.bold: true
                        }
                    }

                    Label {
                        text: model.description
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        font.pixelSize: 13
                        color: "#333"
                    }
                }
            }

            // Empty-state placeholder
            Label {
                anchors.centerIn: parent
                visible: resultsList.count === 0 && !root.vm.searching
                text: root.vm.query.length > 0
                      ? "No results for \"" + root.vm.query + "\""
                      : "Enter a search term above."
                horizontalAlignment: Text.AlignHCenter
                color: "#888"
                wrapMode: Text.WordWrap
                width: parent.width * 0.7
            }
        }
    }
}
