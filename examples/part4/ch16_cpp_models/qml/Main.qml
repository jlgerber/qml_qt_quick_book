import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import com.example.models

// Main.qml — ch16 C++ Models demo.
//
// Demonstrates:
//   * Consuming a QAbstractListModel from QML (ListView + model roles)
//   * Q_INVOKABLE calls: addTask, removeTask, setDone
//   * QSortFilterProxyModel: showDoneItems toggle hides completed tasks
//   * Priority badge rendered from an int role
//
// taskModel and taskProxy are injected by C++ via setInitialProperties.
ApplicationWindow {
    id: root
    width: 520
    height: 600
    visible: true
    title: qsTr("Task List — ch16")

    // These properties receive the objects set via engine.setInitialProperties().
    property var taskModel: null
    property var taskProxy: null

    // Priority → colour helper (pure QML, no C++ needed).
    function priorityColor(p) {
        return p === 3 ? "#e74c3c"   // high  — red
             : p === 2 ? "#f39c12"   // medium — orange
                       : "#27ae60"   // low   — green
    }

    function priorityLabel(p) {
        return p === 3 ? "HIGH" : p === 2 ? "MED" : "LOW"
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        // ---- Add-task bar ------------------------------------------------
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            TextField {
                id: titleField
                Layout.fillWidth: true
                placeholderText: qsTr("New task title…")
                onAccepted: addButton.clicked()
            }

            ComboBox {
                id: priorityCombo
                model: ["Low", "Medium", "High"]
                currentIndex: 0
            }

            Button {
                id: addButton
                text: qsTr("Add")
                enabled: titleField.text.trim().length > 0
                onClicked: {
                    if (taskModel)
                        taskModel.addTask(titleField.text.trim(),
                                          false,
                                          priorityCombo.currentIndex + 1)
                    titleField.clear()
                }
            }
        }

        // ---- "Hide done" toggle -------------------------------------------
        RowLayout {
            Label { text: qsTr("Hide completed tasks:") }
            Switch {
                id: hideDoneSwitch
                checked: false
                onCheckedChanged: {
                    if (taskProxy)
                        taskProxy.showDoneItems = !checked
                }
            }
        }

        // ---- Task list ---------------------------------------------------
        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: taskProxy   // proxy forwards all roles from the source model

            spacing: 4

            delegate: Rectangle {
                width: listView.width
                height: 52
                radius: 6
                color: model.done ? "#f5f5f5" : "white"
                border.color: "#ddd"

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 8

                    // Done checkbox
                    CheckBox {
                        checked: model.done
                        onToggled: {
                            // setDone operates on the *source* model row.
                            // mapToSource gives us the source index.
                            if (taskModel)
                                taskModel.setDone(
                                    taskProxy.mapToSource(
                                        taskProxy.index(index, 0)).row(),
                                    checked)
                        }
                    }

                    // Task title
                    Label {
                        Layout.fillWidth: true
                        text: model.title
                        font.strikeout: model.done
                        color: model.done ? "#999" : "#222"
                        elide: Text.ElideRight
                    }

                    // Priority badge
                    Rectangle {
                        width: 44; height: 22
                        radius: 11
                        color: root.priorityColor(model.priority)

                        Label {
                            anchors.centerIn: parent
                            text: root.priorityLabel(model.priority)
                            color: "white"
                            font.pixelSize: 10
                            font.bold: true
                        }
                    }

                    // Remove button
                    ToolButton {
                        text: "✕"
                        font.pixelSize: 14
                        onClicked: {
                            if (taskModel)
                                taskModel.removeTask(
                                    taskProxy.mapToSource(
                                        taskProxy.index(index, 0)).row())
                        }
                    }
                }
            }

            // Empty-state message
            Label {
                anchors.centerIn: parent
                visible: listView.count === 0
                text: qsTr("No tasks — add one above!")
                color: "#aaa"
                font.pixelSize: 16
            }
        }

        // ---- Status bar --------------------------------------------------
        Label {
            text: qsTr("%1 task(s) shown").arg(listView.count)
            color: "#666"
            font.pixelSize: 12
        }
    }
}
