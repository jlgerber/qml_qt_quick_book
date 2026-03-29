import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import com.example.performance

// Main.qml — ch18 Performance / Batched Updates demo.
//
// Demonstrates:
//   * SensorModel drives a 1 kHz synthetic sensor but only notifies the
//     view at ~60 fps via a 16 ms flush timer.
//   * A horizontal bar chart visualises the rolling window of 100 readings.
//   * Counters show flushes per second and the pending buffer depth to
//     illustrate that the view only processes coarse-grained updates.
Window {
    id: root
    width: 680
    height: 560
    visible: true
    title: qsTr("Batched Model Updates — ch18")

    SensorModel {
        id: sensorModel
    }

    // Measure actual flush rate over a 1-second window.
    property int lastUpdateCount: 0
    property int flushesPerSecond: 0

    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: {
            root.flushesPerSecond = sensorModel.updateCount - root.lastUpdateCount
            root.lastUpdateCount  = sensorModel.updateCount
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // ---- Diagnostic strip -------------------------------------------
        GridLayout {
            columns: 4
            columnSpacing: 24
            rowSpacing: 4

            Label { text: qsTr("Total flushes:"); font.bold: true }
            Label { text: sensorModel.updateCount }

            Label { text: qsTr("Flushes / s:"); font.bold: true }
            Label { text: root.flushesPerSecond }

            Label { text: qsTr("Pending readings:"); font.bold: true }
            Label {
                text: sensorModel.pendingCount
                color: sensorModel.pendingCount > 10 ? "tomato" : "green"
            }

            Label { text: qsTr("Rows in model:"); font.bold: true }
            Label { text: chartView.count }   // ListView.count is reactive
        }

        // ---- Bar chart --------------------------------------------------
        // Each delegate is a thin horizontal rectangle whose width is
        // proportional to the reading value (0..1 mapped to 0..chartWidth).
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#1e1e2e"
            radius: 8
            clip: true

            ListView {
                id: chartView
                anchors.fill: parent
                anchors.margins: 4
                model: sensorModel
                orientation: ListView.Vertical
                spacing: 0

                // Scroll to the bottom whenever new rows are added so we
                // always see the most recent readings.
                onCountChanged: chartView.positionViewAtEnd()

                delegate: Item {
                    width:  chartView.width
                    height: Math.max(1, Math.floor(chartView.height / 100))

                    Rectangle {
                        // Map value [0, 1] to bar width.
                        width:  model.value * (parent.width - 4)
                        height: parent.height - 1
                        anchors.verticalCenter: parent.verticalCenter
                        x: 2
                        radius: 1

                        // Colour shifts from green (low) through yellow to red (high).
                        color: {
                            const v = model.value
                            if (v < 0.5) return Qt.rgba(v * 2, 1, 0, 1)
                            else         return Qt.rgba(1, (1 - v) * 2, 0, 1)
                        }
                    }
                }
            }
        }

        // ---- Start / Stop -----------------------------------------------
        RowLayout {
            Button {
                id: startStopBtn
                property bool running: false
                text: running ? qsTr("Stop") : qsTr("Start")
                onClicked: {
                    running = !running
                    if (running)
                        sensorModel.startUpdates()
                    else
                        sensorModel.stopUpdates()
                }
            }
            Label {
                text: startStopBtn.running
                      ? qsTr("Sensor running — 1 kHz source, ~60 fps view updates")
                      : qsTr("Sensor stopped.")
                color: startStopBtn.running ? "green" : "#aaa"
            }
        }
    }
}
